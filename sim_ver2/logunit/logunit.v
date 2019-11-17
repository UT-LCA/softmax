`timescale 1ns / 1ps
module logunit (a, z, status);

	
	input [15:0] a;
	output [15:0] z;
	output [7:0] status;

	wire [15: 0] fxout1;
	wire [15: 0] fxout2;


	LUT1 lut1 (.addr(a[14:10]),.log(fxout1)); 
	LUT2 lut2 (.addr(a[9:0]),.log(fxout2));  
	DW_fp_addsub add(.a(fxout1), .b(fxout2), .rnd(3'b0), .op(1'b0), .z(z), .status(status[7:0]));
	
endmodule
