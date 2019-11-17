`timescale 1ns / 1ps

module expunit (fpin, fpout);

	parameter int_width = 3; // fixed point integer length
	parameter frac_width = 4; // fixed point fraction length
		
	input [15:0] fpin;
	output [15:0] fpout;


	wire [int_width + frac_width - 1: 0] fxout;
	wire [31:0] LUTout;
	wire [15:0] Mult_out;

	fptofixed_para fpfx (.fp(fpin), .fx(fxout));
	LUT lut(.addr(fxout[int_width + frac_width - 1 : 0]), .exp(LUTout)); 
	DW_fp_mult fpmult (.a(fpin), .b(LUTout[31:16]), .rnd(3'b000), .z(Mult_out), .status());
	DW_fp_add fpsub (.a(Mult_out), .b(LUTout[15:0]), .rnd(3'b000), .z(fpout), .status());
endmodule
