`timescale 1ns / 1ps
module logunit (fpin, fpout);

	
	input [15:0] fpin;
	output [15:0] fpout;


	wire [15: 0] fxout1;
	wire [15: 0] fxout2;


	LUT1 lut1 (.addr(fpin[14:10]),.log(fxout1)); 
	LUT2 lut2 (.addr(fpin[9:0]),.log(fxout2));  
	DW_fp_addsub add(.a(fxout1), .b(fxout2), .rnd(3'b0), .op(1'b0), .z(fpout), .status());
endmodule
