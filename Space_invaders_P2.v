`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

/*Ok so since the TA said "basic" graphics, I want to set up 2 different goals we can reach for
  The first goal would be just literally "basic" graphics where we output the squares then we say fuck it, and get 3/3.
  So for this first goal I was thinking of just storing the different x & y values into variables, then passing them in 
  Remember how we kinda recreated the board on the screen using Lab6's code? The picture that's pinned in discord right now. 
  Yeah i was thinking we do that but just using verilog instead of by hand.
    
 	about the second goal, so i'll write it down when I remember........  
  
    player: (60, 37) 
    (111100, 100101)
    
    aliens: (5, 60), (5, 45), (5, 30), (5, 15)
    (101, 111100)
    (101, 101101)
    (101, 011110)
    (101, 001111)
  */  

module space_invaders
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
		VGA_B,   						//	VGA Blue[9:0]
		HEX0,
		HEX4
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
	output   [6:0] HEX0;
	output   [6:0] HEX4;
	
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
	  
	  wire load_x, load_y, load_draw; 
	  
	  wire [3:0] fsm_hex_output;
	  wire [3:0] score;
	  wire clk_pulse;
  	wire bullet_onscreen;
  	wire bullet_end = 1'b0;
  	wire alien_hit = 1'b0;
	  wire game_over = 1'b0;

	 
    datapath d0(
      .clk(clk_pulse),
      .reset_n(SW[9]),
      .x(x),
      .y(y),
      .(colour),
      .drawing(writeEn),
      .bullet_onscreen(bullet_onscreen),
      .bullet_end(bullet_end),
      .alien_hit(alien_hit),
      .game_over(game_over),
      .fsm_num(fsm_hex_output)
    );
		
    // Instansiate FSM control
    // control c0(...);
    control c0(
      .clk(clk_pulse),
      .reset_n(SW[9]),
		  .start_game(SW[0]),
      .drawing(writeEn),
		  .move_player(SW[2]),
		  .bullet_onscreen(bullet_onscreen),
		  .bullet_end(bullet_end),
		  .alien_hit(alien_hit),
		  .game_over(game_over),
		  .fsm_num(fsm_hex_output),
		  .score(score)
    );
    
endmodule

    
module datapath(
      clk,
      reset_n,
      x,
      y,
  		colour,
      drawing,
      bullet_onscreen,
      bullet_end,
      alien_hit,
      game_over,
  		fsm_num
		);
  	
  input clk;
  input reset_n;
  input fsm_num;
  
  output reg drawing;
  output reg [7:0] x;
  output reg [6:0] y;
  output reg [2:0] colour;
  
  output reg bullet_onscreen = 1'b0
  output reg bullet_end = 1'b0;
  output reg alien_hit = 1'b0;
  output reg game_over = 1'b0;
  
  localparam 	x_interval = 4'b0000,
  						x_player = 6'b111100,
    					y_player = 6'b100101,
    					x_alien = 6'b000101;
  // Aliens have y range of 0 to 60
  
  // Counter for regular drawing 
	reg [5:0] counter = 5'b0; 
	// Counter for drawing the whole screen black during reset 
	reg [14:0] reset_counter = 15'b0; 
  
  // FSM always block
  always@(posedge clk) begin
    // If reset_n is at 0, then redraw the screen
    if (!reset_n) begin
			drawing <= 1'b1; 
			reset_counter <= 15'b0;
      colour <= 3'b000;
    end 
    
    //For redrawing the whole board in when resetting 
    if (!reset_n) begin
      drawing <= 1'b1;
				x <= reset_counter[7:0]; 
				y <= reset_counter[14:8];
				
				/* If reset counter has overflowed, then it is done redrawing the
				whole screen into black */
				if (reset_counter == 15'b1111_1111_1111_1111) begin 
					drawing <= 1'b0; 
					resetting <= 1'b0; 
					x <= 7'b0; 
					y <= 6'b0; 
					reset_counter <= 15'b0;
				end 
				reset_counter <= reset_counter + 1'b1;
		end 
    
    /*
    player: (60, 37) 
    (111100, 100101)
    
    aliens: (5, 60), (5, 45), (5, 30), (5, 15)
    (101, 111100)
    (101, 101101)
    (101, 011110)
    (101, 001111)*/
    wire [6:0] y_player = y_player_start;
    wire [7:0] x_player = x_player_start;
    wire [6:0] y_bullet; 
    wire [7:0] x_bullet; 
    
      localparam 	x_interval = 4'b0000,
  								x_player_start = 6'b111100,
    							y_player_start = 6'b100101,
    							x_alien = 6'b000101
    							y_edge = 6'b111111,
    							x_edge = ;
    
    // DRAW_PLAYER_ALIEN 
    if (fsm_num == 4'b0001) begin
      // Set drawing variable to 1
      drawing <= 1'b1;
      // X is constant for aliens at 5
      x <= x_alien;
      y <= y_interval; //y_interval = 4'b0000 defined above
      colour <= 3'b100; // aliens are red
      
      // If statement for when you're finished drawing the aliens
      // Draw the player now
      if (y_interval == 111100 && x == 4'b0101) begin
        x <= x_player_start;
        y <= y_player_start;
        colour <= 3'b001; // player is blue
      end 
      // Finish drawing
      else begin 
        drawing <= 1'b0;
      end 
      // Increment y_interval by 15 
      y_interval <= y_interval + 4'b1111
    end // end of if for DRAW_PLAYER_ALIEN
    
    
    // DRAW_BULLET
    if (fsm_num == 4'b0100) begin 
    	bullet_onscreen <= 1'b1;
      drawing <= 1'b1; 
      colour <= 3'b111;
      
      // Create the white bullet right on top of the player
      y <= y_player - 4'b1111; 
      x <= x - 4'b1111;
      
      // Store values in wire
      y_bullet = y; 
      x_bullet = x;
      
      // Return x and y values back to player values for movement
      if (x != x_player_start) begin 
        x <= x_player;
        y <= y_player;
        drawing <= 0;
        colour <= 3'b001;
      end
    end
    
    // DRAW_MOVE_LEFT
    if (fsm_num == 4'b0110) begin
    	// Draw the current player square into black
      drawing <= 1'b1; 
      x <= x_player; 
      y <= y_player; 
      colour <= 3'b000;
      
      // Draw the new player 
      if (colour == 3'b000) begin 
        drawing <= 1'b0;
        y <= y_player + 4'b1001; 
        // If the player collides on the edge
        if ((y_player + 4'b1001) > y_edge) begin
          y <= y_edge;
          y_player = y_edge;
     	 	end 
        colour <= 3'b001; 
        // Exit the drawing state
        drawing <= 1'b0;
      end 
    end // End of DRAW_MOVE_LEFT 
    
    // DRAW_MOVE_RIGHT
    if (fsm_num == 4'b1000) begin
      // Draw the current player square into black
      drawing <= 1'b1; 
      x <= x_player; 
      y <= y_player; 
      colour <= 3'b000;
      
      // Draw the new player 
      if (colour == 3'b000) begin 
        drawing <= 1'b0;
        y <= y_player - 4'b1001; 
        // If the player collides on the edge
        if ((y_player - 4'b1001) < 0) begin
          y <= y_edge;
          y_player = y_edge;
     	 	end 
        colour <= 3'b001; 
        // Exit the drawing state
        drawing <= 1'b0;
      end 
    end
    
    // MOVE_BULLET
    if (fsm_num == 4'b1001) begin
      // Draw the current bullet square into black
      x <= x_bullet; 
      y <= y_bullet; 
      colour <= 3'b000;
      drawing <= 1'b1; 

      // Draw the new bullet 
      if (colour == 3'b000) begin 
        drawing <= 1'b0;
        x <= x_bullet - 4'b1001; 
        x_bullet = x;
        
        // If Bullet hits an alien (for phase 3)
        //.....
        //.....
        
        // If the bullet collides on the top edge
        if (x_bullet < 0) begin
          x <= 0;
          x_bullet = 0; 
          bullet_onscreen <= 0;
          bullet_end <= 0;
     	 	end 
        colour <= 3'b111; 
        // Exit the drawing state
        drawing <= 1'b0;
      end 
    end
    
  end //End of FSM always block
    
endmodule
    

module control(
				clk,
				reset_n,
				start_game,
				drawing,
				move_player,
				bullet_onscreen,
				bullet_end,
				alien_hit,
				game_over,
				fsm_num,
				score
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
	
	output reg [3:0] fsm_num;
	output reg [3:0] score = 4'b0;
	
	reg[5:0] current_state, next_state;
	
	localparam 	WAIT_DRAW 			= 5'd0,
				DRAW_PLAYER_ALIENS	= 5'd1,
				WAIT_BEGIN_GAME		= 5'd2,
				SHOOT				= 5'd3,
				DRAW_BULLET 		= 5'd4,
				MOVE_CHAR_LEFT 		= 5'd5,
				DRAW_MOVE_LEFT		= 5'd6,
				MOVE_CHAR_RIGHT		= 5'd7,
				DRAW_MOVE_RIGHT		= 5'd8,
				MOVE_BULLET			= 5'd9,
				CHECK_HIT			= 5'd10,
				REMOVE_ALIEN 		= 5'd11,
				REMOVE_BULLET 		= 5'd12,
				END_GAME			= 5'd13;
				
	/* For the drawing variable, I'm planning to hijack Jeff's idea of 
		if drawing = 1, then stay in that state */
		
	//localparam score_keep = 4'b0;
		
	always@(posedge clk)
	begin: state_table
		case(current_state)
			// Wait for input to start game				  not pressed   pressed
			// How ternary works in verilog:		 	  1				0 
			
			// Press the start button to begin drawing
			WAIT_DRAW: 		next_state = start_game ? WAIT_DRAW : DRAW_PLAYER_ALIENS;
			
			// Draw the players and aliens 
			DRAW_PLAYER_ALIENS: next_state = drawing ? DRAW_PLAYER_ALIENS : WAIT_BEGIN_GAME;
			//DRAW_PLAYER_ALIENS: next_state = drawing ? WAIT_BEGIN_GAME : DRAW_PLAYER_ALIENS;
			
			// Wait for start_game input to fire first bullet
			WAIT_BEGIN_GAME:next_state = start_game ? WAIT_BEGIN_GAME : SHOOT;
			
			// If bullet_onscreen = 0 then DRAW_BULLET, if 1 then MOVE_CHAR_LEFT
			SHOOT :			next_state = bullet_onscreen ? MOVE_CHAR_LEFT : DRAW_BULLET;
			
			// After it is done drawing, move the go to MOVE_CHAR_LEFT state to check for move_player input
			// If drawing = 0, stay in this state to keep drawing
			DRAW_BULLET: 	next_state = drawing ? DRAW_BULLET : MOVE_CHAR_LEFT;
			
			// move_player = 0 ==> move left, 	move_player = 1 ==> move_right
			// If the player keeps the same direction, move bullet, otherwise go to state for player to go to other direction
			MOVE_CHAR_LEFT:	next_state = move_player ? MOVE_CHAR_RIGHT : DRAW_MOVE_LEFT;
			DRAW_MOVE_LEFT: next_state = drawing ? DRAW_MOVE_LEFT : MOVE_BULLET;
			
			// Same as before, but move_player has to stay at 1 before reaching bullet
			MOVE_CHAR_RIGHT: next_state = move_player ? DRAW_MOVE_RIGHT : MOVE_CHAR_LEFT;
			DRAW_MOVE_RIGHT: next_state = drawing ? DRAW_MOVE_RIGHT : MOVE_BULLET; 
			
			// If bullet_onscreen is true go back to shoot
			MOVE_BULLET: 	next_state = drawing ? MOVE_BULLET : CHECK_HIT; 
			
			// If bullet_end = 1, then REMOVE_BULLET, reset_nif bullet_end = 0 then cycle back to SHOOT
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
	
	always @(posedge clk)
	begin: enable_signals
		fsm_num = 4'b0;
		case (current_state)
			WAIT_DRAW: begin
				fsm_num = 4'b0000;
			end
			
			DRAW_PLAYER_ALIENS: begin
				fsm_num = 4'b0001;
			end
			
			WAIT_BEGIN_GAME: begin
				fsm_num = 4'b0010;
			end
			
			SHOOT: begin
				fsm_num = 4'b0011;
			end
			
			DRAW_BULLET: begin
				fsm_num = 4'b0100;
			end
			
			MOVE_CHAR_LEFT: begin
				fsm_num = 4'b0101;
			end
			
			DRAW_MOVE_LEFT: begin
				fsm_num = 4'b0110;
			end
			
			MOVE_CHAR_RIGHT: begin
				fsm_num = 4'b0111;
			end
			
			DRAW_MOVE_RIGHT: begin
				fsm_num = 4'b1000;
			end
			
			MOVE_BULLET: begin
				fsm_num = 4'b1001;
			end
			
			CHECK_HIT: begin
				fsm_num = 4'b1010;
			end
			
			REMOVE_BULLET: begin
				fsm_num = 4'b1011;
				if (alien_hit == 1'b1)
					score = score + 1;
			end
			
			REMOVE_ALIEN: begin
				fsm_num = 4'b1100;
			end
			
			END_GAME: begin
				fsm_num = 4'b1101;
			end
			
			
		endcase
	end
	
	always@(posedge clk)
    begin: state_FFs
        if (!reset_n)
            current_state <= WAIT_DRAW;
        else
            current_state <= next_state;
    end // state_FFS
	 

endmodule 
	
	
	
	
	
	
	
	
	
	