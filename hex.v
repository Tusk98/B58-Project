module hex(out, in); 
	input [9:0] in;
	output [6:0] out;
	
	light0 zero (.a0(in[3]), .a1(in[2]), .a2(in[1]), .a3(in[0]), .a(out[0]));	
	light1 one (.b0(in[3]), .b1(in[2]), .b2(in[1]), .b3(in[0]), .b(out[1]));	
	light2 two (.c0(in[3]), .c1(in[2]), .c2(in[1]), .c3(in[0]), .c(out[2]));	
	light3 three (.d0(in[3]), .d1(in[2]), .d2(in[1]), .d3(in[0]), .d(out[3]));	
	light4 four (.e0(in[3]), .e1(in[2]), .e2(in[1]), .e3(in[0]), .e(out[4]));	
	light5 five (.f0(in[3]), .f1(in[2]), .f2(in[1]), .f3(in[0]), .f(out[5]));	
	light6 six (.g0(in[3]), .g1(in[2]), .g2(in[1]), .g3(in[0]), .g(out[6]));	
endmodule


module light0(a0, a1, a2, a3, a);
	input a0;
	input a1;
	input a2;
	input a3;
	output a;
	
	assign a = (~a0 & ~a1 & ~a2 & a3) | (~a0 & a1 & ~a2 & ~a3) | (a0 & a1 & ~a2 & a3) | (a0 & ~a1 & a2 & a3);
endmodule

module light1(b0, b1, b2, b3, b);
	input b0;
	input b1;
	input b2;
	input b3;
	output b;
	
	assign b = (~b0 & b1 & ~b2 & b3) | (b0 & b2 & b3) | (b0 & b1 & ~b3) | (b1 & b2 & ~b3);
endmodule

module light2(c0, c1, c2, c3, c);
	input c0;
	input c1;
	input c2;
	input c3;
	output c;
	
	assign c = (~c0 & ~c1 & c2 & ~c3) | (c0 & c1 & c2) | (c0 & c1 & ~c3);
endmodule

module light3(d0, d1, d2, d3, d);
	input d0;
	input d1;
	input d2;
	input d3;
	output d;
	
	assign d = (~d0 & d1 & ~d2 & ~d3) | (~d0 & ~d1 & ~d2 & d3) | (d1 & d2 & d3) | (d0 & ~d1 & d2 & ~d3);
endmodule

module light4(e0, e1, e2, e3, e);
	input e0;
	input e1;
	input e2;
	input e3;
	output e;
	
	assign e = (~e0 & e1 & ~e2) | (~e1 & ~e2 & e3) | (~e0 & e3);
endmodule

module light5(f0, f1, f2, f3, f);
	input f0;
	input f1;
	input f2;
	input f3;
	output f;
	
	assign f = (f0 & f1 & ~f2 & f3) | (~f0 & ~f1 & f3) | (~f0 & f2 & f3) | (~f0 & ~f1 & f2);
endmodule

module light6(g0, g1, g2, g3, g);
	input g0;
	input g1;
	input g2;
	input g3;
	output g;
	
	assign g = (~g0 & ~g1 & ~g2) | (g0 & g1 & ~g2 & ~g3) | (~g0 & g1 & g2 & g3);
endmodule


