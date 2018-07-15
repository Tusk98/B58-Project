module clock_timer(reset_n, clock, pulse);
	input reset_n;
	input clock; 
	
	reg [27:0] counter;
	output pulse;
	
	// 833'334 in Decimal, will turn Clock_50 into 59.99 Hz 
	localparam limit = 20'b1100_1011_0111_0011_0110;
	
	always @(posedge clock)
	begin
		if (reset_n == 1'b0)
			counter <= 0;
		else if (counter == limi) 
			counter <= 0;
		else if (reset_n = 1'b1)
			counter <= counter + 1'b1;
	end
	
	assign pulse = (counter == limit) ? 1 : 0; 
	
endmodule