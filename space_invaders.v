// Space Invaders by 
//WU, Yu Heng		1003475330 	wuyu35	
//LEE, Patricia


`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

module part2
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
  
	  // Since SW[6:0] is used for input (X,Y)
	  wire [6:0]coordinate_input;
	  // Press KEY[1] to start drawing as per instructions in paragraph 
	  wire start_drawing = KEY[1];
	  // Pass SW value into coordinate input wire
	  assign coordinate_input = SW[6:0]; 
	  // Load register with X value 
	  wire load_value = KEY[3];
	  
	  // give color value from SW into wire
	  assign colour = SW[9:7];
	  
	  wire load_x, load_y, load_draw; 

      // datapath d0(...);
    datapath d0(
        .clk(CLOCK_50),
        .reset_n(resetn),
        .data_in(coordinate_input),
        .load_x(load_x),
        .load_y(load_y),
        .load_draw(load_draw),
        .x(x),
        .y(y),
        .drawing(writeEn),
        .resetting(resetting)
        );

    // Instansiate FSM control
    // control c0(...);
    control c0(
        .clk(CLOCK_50),
        .reset_n(resetn),
        .get_input(get_input),
        .drawing(writeEn),
        .load_x(load_x),
        .load_y(load_y),
        .load_draw(load_draw),
        .start_drawing(start_drawing),
        .resetting(resetting)
        );
    
endmodule


module control(
				clk,
				reset_n,
				start_game,
				drawing,
				move_player,
				bullet_onscreen,
				bullet_end,
				hit_alien
				);
				
	input clk;
	input reset_n;
	input start_game; 
	input drawing;
	input move_player;
	input bullet_onscreen;
	/* I originally didn't know what to do when navigating the FSM for if the bullet
		hit the aliens or when the bullet hit the edge of the game. So instead of making
		2 variables 'bullet_alien' and 'bullet_edge', I just decided to have only a single
		variable 'bullet_end' and then we deal with the alien shit later*/
	input bullet_end; 
	input alien_hit;
	input game_over;
	
	output reg bullet_x;
	
	reg[5:0] current_state, next_state;
	
	localparam 	WAIT_DRAW 			= 'd0,
				DRAW_PLAYER_ALIENS	= 'd1,
				WAIT_BEGIN_GAME		= 'd2,
				SHOOT				= 'd3,
				DRAW_BULLET 		= 'd4,
				MOVE_CHAR_LEFT 		= 'd5,
				DRAW_MOVE_LEFT		= 'd6,
				MOVE_CHAR_RIGHT		= 'd7,
				DRAW_MOVE_RIGHT		= 'd8,
				MOVE_BULLET			= 'd9,
				CHECK_HIT			= 'd10,
				REMOVE_ALIEN 		= 'd11,
				REMOVE_BULLET 		= 'd12,
				END_GAME			= 'd13;
				
	/* For the drawing variable, I'm planning to hijack Jeff's idea of 
		if drawing = 1, then stay in that state */
		
	always@(*)
	begin: state_table
		case(current_state)
			// Wait for input to start game				  not pressed   pressed
			// How ternary works in verilog:		 	  1				0 
			
			// Press the start button to begin drawing
			WAIT_DRAW: 		next_state = start_game ? WAIT_DRAW : DRAW_PLAYER_ALIENS;
			
			// Draw the players and aliens 
			DRAW_PLAYER_ALIENS: next_state = drawing ? DRAW_PLAYER_ALIENS : WAIT_BEGIN_GAME;
			
			// Wait for start_game input to fire first bullet
			WAIT_BEGIN_GAME:next_state = start_game ? WAIT_BEGIN_GAME : SHOOT;
			
			// If bullet_onscreen = 0 then DRAW_BULLET, if 1 then MOVE_CHARACTER_LEFT
			SHOOT :			next_state = bullet_onscreen ? MOVE_CHARACTER_LEFT : DRAW_BULLET;
			
			// After it is done drawing, move the go to MOVE_CHARACTER_LEFT state to check for move_player input
			// If drawing = 0, stay in this state to keep drawing
			DRAW_BULLET: 	next_state = drawing ? DRAW_BULLET : MOVE_CHARACTER_LEFT
			
			// move_player = 0 ==> move left, 	move_player = 1 ==> move_right
			// If the player keeps the same direction, move bullet, otherwise go to state for player to go to other direction
			MOVE_CHAR_LEFT:	next_state = move_player ? MOVE_CHAR_RIGHT : DRAW_MOVE_LEFT;
			DRAW_MOVE_LEFT: next_state = drawing ? DRAW_MOVE_LEFT : MOVE_BULLET;
			
			// Same as before, but move_player has to stay at 1 before reaching bullet
			MOVE_CHAR_RIGHT: next_state = move_player ? DRAW_MOVE_RIGHT : MOVE_CHAR_LEFT;
			DRAW_MOVE_RIGHT: next_state = drawing ? DRAW_MOVE_RIGHT : MOVE_BULLET; 
			
			// If bullet_onscreen is true go back to shoot
			MOVE_BULLET: 	next_state = drawing ? MOVE_BULLET : CHECK_HIT; 
			
			// If bullet_end = 1, then REMOVE_BULLET, if bullet_end = 0 then cycle back to SHOOT
			CHECK_HIT: 		next_state = bullet_end ? REMOVE_BULLET : SHOOT; 
			
			// If alien_hit = 1, then REMOVE_ALIEN, if alien_hit = 0, then cycle back to SHOOT 
			REMOVE_BULLET: 	next_state = alien_hit ? REMOVE_ALIEN : SHOOT; 
			
			// If Game_over, then go to END state, otherwise cycle back to SHOOT
			REMOVE_ALIEN: next_state = game_over ? END_GAME : SHOOT;
			
		endcase
	end // state_table 
			
	/* I have no clue what to do for this section right now
		I don't even know what variables we're using yet
		But here's an example with bullet_y, where maybe I can just
		add "bullet_x" to the square coordinates for the bullet 
	*/
	always @(*)
	begin: enable_signals
		bullet_x = 1'b0;
		case (current_state)
			MOVE_BULLET: begin
				bullet_x = 1'b1;
			end
			
		endcase
	end
	
	always@(posedge clk)
    begin: state_FFs
        if (!resetn)
            current_state <= WAIT_DRAW;
        else
            current_state <= next_state;
    end // state_FFS

endmodule 
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	