`timescale 1ns / 1ps
module fptofixed_para (
	fp,
	fx
	);
	
	parameter int_width = 3; // fixed point integer length
	parameter frac_width = 3; // fixed point fraction length

	input [15:0] fp; // Half Precision fp
	output [int_width + frac_width - 1:0] fx;  
	
	wire [15:0] Mant; // mantissa of fp
	wire signed [4:0] Ea; // non biased exponent
	wire [4:0] Exp; // biased exponent
	wire [15:0] sftfx; // output of shifter block
	reg [15:0] temp;
	
	assign Mant = {6'b000001, fp[9:0]};
	assign Exp = fp[14:10];
	assign Ea = Exp - 15;

	assign fx = temp[9+int_width:10-frac_width];
	

always @(sftfx)
begin
// only negetive numbers as inputs after sorting and subtraction from max
	if (Ea > int_width - 1)
		begin
			temp <= 16'hFFFF; // if there is an overflow
			
		end
	else if ( fp[14:0] == 15'b0)
		begin 
			temp <= 16'b0;
			
		end	
	else // underflow automatically becomes zero
		begin
			temp <= sftfx;
		end
end	

DW01_ash  #(`DATAWIDTH, 5) ash( .A(Mant[15:0]), .DATA_TC(1'b0), .SH(Ea[4:0]), .SH_TC(1'b1), .B(sftfx));

endmodule
