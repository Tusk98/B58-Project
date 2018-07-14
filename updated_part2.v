// Part 2 skeleton

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
	  assign color = SW[9:7];
	  
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

module datapath(
		clk, 
		reset_n,
		data_in,
		x,
		y,
		load_x,
		load_y,
		load_draw,
		drawing, 
		resetting
	);
	
	input clk; 
	input reset_n; 
	// Raw data input 
	input [6:0] data_in;
	// Input from FSM to instruct datapath to load X, Y, start drawing
	input load_x, load_y, load_draw; 
	
	// The X and Y values to be passed into the VGA Adapter
	output reg [7:0] x;
	output reg [6:0] y; 
	// Drawing and Resetting global variables used for telling control 
	// FSM that you're still drawing/resetting
	output reg drawing; 
	output reg resetting
	
	// Values for X and Y 
	reg [7:0] x_reg = 7'b0; 
	reg [6:0] y_reg = 6'b0;
	
	// Counter for regular drawing 
	reg [5:0] counter = 5'b0; 
	// Counter for drawing the whole screen black during reset 
	reg [14:0] reset_counter = 15'b0; 
	
	always@(posedge clk) begin 
		// If reset_n is at 0, then initiate values 
		if (!reset_n) begin 
			x_reg <= 7'd0; 
			y_reg <= 6'd0; 
			counter <= 5'b0; 
			drawing <= 1'b1; 
			reset_counter <= 15'b0;
			resetting <= 1'b1; 
		end 
		else begin
			// Resetting is triggered by reset_n in the previous code block
			// Triggers a redraw of the whole 
			if (resetting) begin 
				drawing <= 1'b1;
				x <= x_reg + rcounter[7:0]; 
				y <= y_reg + rcounter[14:8];
				
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
			
			// If it's not resetting, then drawing is the only state left 
			else begin 
				if (drawing) begin 
					// Adding bits by 2'b because of ???
					x <= x_reg + counter[1:0]; 
					y <= y_reg + counter[3:2];
					
					// If regular counter overflows, we're done drawing 
					if (counter == 5'b10000) begin 
						/* set to not draw to screen */
                        drawing <= 1'b0;
                        x       <= 7'b0;
                        y       <= 6'b0;
                        counter <= 5'b0;
					end
					counter <= counter + 1'b1; 
				end 
				
				/* otherwise, check if we are loading x or y value, or drawing */
                else begin
                    /* load x */
                    if (load_x)
                        x_reg <= { 1'b0, data_in };
                    /* load y */
                    if (load_y)
                        y_reg <= data_in;
                    if (load_draw)
                        drawing <= 1'b1;
                end 
			end //end of else statement for resetting 
		end //end of else for reset_n 
	end //end of always block
endmodule 

module control (
		clk, 
		reset_n, 
		get_input, 
		start_drawing, 
		drawing, 
		resetting, 
		load_x, 
		load_y, 
		load_draw
	); 
	
	input clk; 
	input reset_n; 
	input get_input; 
	input start_drawing; 
	input drawing; 
	input resetting; 
	
	output reg load_x, load_y, load_draw; 
	
	reg [5:0] current_state, next_state;
	
	    /* finite states */
    localparam  S_LOAD_X_WAIT       = 5'd0,
                S_LOAD_X            = 5'd1,
                S_LOAD_Y_WAIT       = 5'd2,
                S_LOAD_Y            = 5'd3,
                S_DRAW_WAIT         = 5'd4,
                S_DRAWING           = 5'd5,
                S_DONE_DRAWING      = 5'd6,
                S_RESET             = 5'd6;
				
	always@(*) 
	begin: state_table 
		case (current_state)
			/* waiting for X input                   not pressed     pressed */
			S_LOAD_X_WAIT:  next_state = get_input ? S_LOAD_X_WAIT : S_LOAD_X;
			/* get X input */
			S_LOAD_X:       next_state = get_input ? S_LOAD_Y_WAIT : S_LOAD_X;
			/* waiting for Y input */
			S_LOAD_Y_WAIT:  next_state = get_input ? S_LOAD_Y_WAIT : S_LOAD_Y;
			/* get Y input */
			S_LOAD_Y:       next_state = get_input ? S_DRAW_WAIT : S_LOAD_Y;
			/* wait for drawing input */
			S_DRAW_WAIT:    next_state = start_drawing ? S_DRAW_WAIT : S_DRAWING;
			/* start drawing                       1           0             */
			S_DRAWING:      next_state = drawing ? S_DRAWING : S_DONE_DRAWING;
			/* done drawing              go to wait for X input */
			S_DONE_DRAWING: next_state = S_LOAD_X_WAIT;
			/* resetting state                       1         0             */
			S_RESET:        next_state = resetting ? S_RESET : S_LOAD_X_WAIT;
			default:        next_state = S_LOAD_X_WAIT;
		endcase
	end // state_table 
	
	always @(*) 
	begin: enable_signals
		// Set up as all signals 0 by default 
		// These load signals tell datapath what to do
		load_x = 1'b0; 
		load_y = 1'b0; 
		load_draw = 1'b0;
		case (current_state) 
			// If current state is in S_LOAD_X then set load_x to 1
			// Allows datapath to load in X value
			S_LOAD_X: begin  
				load_x = 1'b1; 
			end 
			
			S_LOAD_Y: begin 
				load_y = 1'b1;
			end 
			
			S_DRAWING: begin
				load_draw = 1'b1; 
			end 
			
			S_DONE_DRAWING: begin 
				load_draw = 1'b0; 
			end		
		endcase 
	end // enable signals
	
	    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if (!resetn)
            current_state <= S_RESET;
        else
            current_state <= next_state;
    end // state_FFS
	
endmodule 
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	