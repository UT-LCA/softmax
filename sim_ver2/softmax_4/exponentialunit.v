`include "defines.v"
module expunit (a, z, status);

	parameter int_width = 3; // fixed point integer length
	parameter frac_width = 4; // fixed point fraction length
		
	input [15:0] a;
	output [15:0] z;
	output [7:0] status;

	wire [int_width + frac_width - 1: 0] fxout;
	wire [31:0] LUTout;
	wire [15:0] Mult_out;

	fptofixed_para fpfx (.fp(a), .fx(fxout));
	LUT lut(.addr(fxout[int_width + frac_width - 1 : 0]), .exp(LUTout)); 
	DW_fp_mult #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) fpmult (.a(a), .b(LUTout[31:16]), .rnd(3'b000), .z(Mult_out), .status());
	DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) fpsub (.a(Mult_out), .b(LUTout[15:0]), .rnd(3'b000), .z(z), .status(status[7:0]));
endmodule

module fptofixed_para (
	fp,
	fx
	);
	
	parameter int_width = 3; // fixed point integer length
	parameter frac_width = 4; // fixed point fraction length

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

DW01_ash #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) ash( .A(Mant[15:0]), .DATA_TC(1'b0), .SH(Ea[4:0]), .SH_TC(1'b1), .B(sftfx));

endmodule

module LUT(addr, exp);
    input [6:0] addr;
    output reg [31:0] exp;

    always @(addr) begin
        case (addr)
			7'b0 		: exp = 32'b00111011110000010011110000000000;
			7'b1 		: exp = 32'b00111011010010010011101111111000;
			7'b10 		: exp = 32'b00111010110110000011101111101010;
			7'b11 		: exp = 32'b00111010011011100011101111010110;
			7'b100 		: exp = 32'b00111010000010100011101110111110;
			7'b101 		: exp = 32'b00111001101011000011101110100000;
			7'b110 		: exp = 32'b00111001010101000011101101111111;
			7'b111 		: exp = 32'b00111001000000100011101101011011;
			7'b1000 		: exp = 32'b00111000101101000011101100110100;
			7'b1001 		: exp = 32'b00111000011010110011101100001011;
			7'b1010 		: exp = 32'b00111000001001110011101011100000;
			7'b1011 		: exp = 32'b00110111110011010011101010110100;
			7'b1100 		: exp = 32'b00110111010101000011101010000111;
			7'b1101 		: exp = 32'b00110110111000100011101001011001;
			7'b1110 		: exp = 32'b00110110011101110011101000101010;
			7'b1111 		: exp = 32'b00110110000100110011100111111011;
			7'b10000 		: exp = 32'b00110101101101010011100111001100;
			7'b10001 		: exp = 32'b00110101010111000011100110011101;
			7'b10010 		: exp = 32'b00110101000010010011100101101110;
			7'b10011 		: exp = 32'b00110100101110110011100101000000;
			7'b10100 		: exp = 32'b00110100011100100011100100010010;
			7'b10101 		: exp = 32'b00110100001011010011100011100101;
			7'b10110 		: exp = 32'b00110011110110000011100010111000;
			7'b10111 		: exp = 32'b00110011010111100011100010001100;
			7'b11000 		: exp = 32'b00110010111011000011100001100001;
			7'b11001 		: exp = 32'b00110010100000010011100000111000;
			7'b11010 		: exp = 32'b00110010000111000011100000001111;
			7'b11011 		: exp = 32'b00110001101111010011011111001101;
			7'b11100 		: exp = 32'b00110001011001000011011101111111;
			7'b11101 		: exp = 32'b00110001000100000011011100110011;
			7'b11110 		: exp = 32'b00110000110000100011011011101010;
			7'b11111 		: exp = 32'b00110000011110000011011010100010;
			7'b100000 		: exp = 32'b00110000001100110011011001011101;
			7'b100001 		: exp = 32'b00101111111000110011011000011010;
			7'b100010 		: exp = 32'b00101111011010010011010111011001;
			7'b100011 		: exp = 32'b00101110111101100011010110011010;
			7'b100100 		: exp = 32'b00101110100010100011010101011101;
			7'b100101 		: exp = 32'b00101110001001010011010100100011;
			7'b100110 		: exp = 32'b00101101110001010011010011101010;
			7'b100111 		: exp = 32'b00101101011011000011010010110100;
			7'b101000 		: exp = 32'b00101101000110000011010001111111;
			7'b101001 		: exp = 32'b00101100110010010011010001001100;
			7'b101010 		: exp = 32'b00101100011111110011010000011100;
			7'b101011 		: exp = 32'b00101100001110010011001111011010;
			7'b101100 		: exp = 32'b00101011111011110011001110000000;
			7'b101101 		: exp = 32'b00101011011101000011001100101001;
			7'b101110 		: exp = 32'b00101011000000000011001011010110;
			7'b101111 		: exp = 32'b00101010100100110011001010000110;
			7'b110000 		: exp = 32'b00101010001011010011001000111010;
			7'b110001 		: exp = 32'b00101001110011100011000111110001;
			7'b110010 		: exp = 32'b00101001011101000011000110101010;
			7'b110011 		: exp = 32'b00101001000111110011000101100111;
			7'b110100 		: exp = 32'b00101000110100000011000100100110;
			7'b110101 		: exp = 32'b00101000100001010011000011101001;
			7'b110110 		: exp = 32'b00101000001111110011000010101101;
			7'b110111 		: exp = 32'b00100111111110100011000001110101;
			7'b111000 		: exp = 32'b00100111011111100011000000111111;
			7'b111001 		: exp = 32'b00100111000010100011000000001011;
			7'b111010 		: exp = 32'b00100110100111010010111110110011;
			7'b111011 		: exp = 32'b00100110001101100010111101010100;
			7'b111100 		: exp = 32'b00100101110101100010111011111010;
			7'b111101 		: exp = 32'b00100101011111000010111010100100;
			7'b111110 		: exp = 32'b00100101001001110010111001010001;
			7'b111111 		: exp = 32'b00100100110101110010111000000011;
			7'b1000000 		: exp = 32'b00100100100011000010110110111000;
			7'b1000001 		: exp = 32'b00100100010001010010110101110000;
			7'b1000010 		: exp = 32'b00100100000000110010110100101100;
			7'b1000011 		: exp = 32'b00100011100010010010110011101011;
			7'b1000100 		: exp = 32'b00100011000101000010110010101101;
			7'b1000101 		: exp = 32'b00100010101001110010110001110001;
			7'b1000110 		: exp = 32'b00100010001111110010110000111001;
			7'b1000111 		: exp = 32'b00100001110111110010110000000011;
			7'b1001000 		: exp = 32'b00100001100001000010101110100000;
			7'b1001001 		: exp = 32'b00100001001011100010101100111110;
			7'b1001010 		: exp = 32'b00100000110111100010101011100010;
			7'b1001011 		: exp = 32'b00100000100100100010101010001001;
			7'b1001100 		: exp = 32'b00100000010010110010101000110101;
			7'b1001101 		: exp = 32'b00100000000010010010100111100101;
			7'b1001110 		: exp = 32'b00011111100101000010100110011001;
			7'b1001111 		: exp = 32'b00011111000111110010100101010000;
			7'b1010000 		: exp = 32'b00011110101100000010100100001011;
			7'b1010001 		: exp = 32'b00011110010010010010100011001001;
			7'b1010010 		: exp = 32'b00011101111001110010100010001011;
			7'b1010011 		: exp = 32'b00011101100011000010100001001111;
			7'b1010100 		: exp = 32'b00011101001101010010100000010111;
			7'b1010101 		: exp = 32'b00011100111001010010011111000011;
			7'b1010110 		: exp = 32'b00011100100110010010011101011101;
			7'b1010111 		: exp = 32'b00011100010100100010011011111100;
			7'b1011000 		: exp = 32'b00011100000011110010011010100000;
			7'b1011001 		: exp = 32'b00011011100111110010011001001000;
			7'b1011010 		: exp = 32'b00011011001010010010010111110101;
			7'b1011011 		: exp = 32'b00011010101110100010010110100110;
			7'b1011100 		: exp = 32'b00011010010100100010010101011011;
			7'b1011101 		: exp = 32'b00011001111100000010010100010100;
			7'b1011110 		: exp = 32'b00011001100101000010010011010000;
			7'b1011111 		: exp = 32'b00011001001111010010010010010000;
			7'b1100000 		: exp = 32'b00011000111011000010010001010011;
			7'b1100001 		: exp = 32'b00011000100111110010010000011001;
			7'b1100010 		: exp = 32'b00011000010110000010001111000101;
			7'b1100011 		: exp = 32'b00011000000101000010001101011101;
			7'b1100100 		: exp = 32'b00010111101010100010001011111010;
			7'b1100101 		: exp = 32'b00010111001100110010001010011100;
			7'b1100110 		: exp = 32'b00010110110001000010001001000011;
			7'b1100111 		: exp = 32'b00010110010110110010000111101111;
			7'b1101000 		: exp = 32'b00010101111110000010000110011111;
			7'b1101001 		: exp = 32'b00010101100111000010000101010011;
			7'b1101010 		: exp = 32'b00010101010001010010000100001011;
			7'b1101011 		: exp = 32'b00010100111100110010000011000110;
			7'b1101100 		: exp = 32'b00010100101001100010000010000110;
			7'b1101101 		: exp = 32'b00010100010111100010000001001000;
			7'b1101110 		: exp = 32'b00010100000110100010000000001110;
			7'b1101111 		: exp = 32'b00010011101101010001111110101110;
			7'b1110000 		: exp = 32'b00010011001111100001111101000101;
			7'b1110001 		: exp = 32'b00010010110011100001111011100010;
			7'b1110010 		: exp = 32'b00010010011001000001111010000100;
			7'b1110011 		: exp = 32'b00010010000000010001111000101011;
			7'b1110100 		: exp = 32'b00010001101001000001110111010111;
			7'b1110101 		: exp = 32'b00010001010011000001110110000111;
			7'b1110110 		: exp = 32'b00010000111110100001110100111011;
			7'b1110111 		: exp = 32'b00010000101011010001110011110011;
			7'b1111000 		: exp = 32'b00010000011001000001110010101111;
			7'b1111001 		: exp = 32'b00010000001000000001110001101111;
			7'b1111010 		: exp = 32'b00001111110000010001110000110010;
			7'b1111011 		: exp = 32'b00001111010010000001101111110000;
			7'b1111100 		: exp = 32'b00001110110101110001101110000010;
			7'b1111101 		: exp = 32'b00001110011011010001101100011011;
			7'b1111110 		: exp = 32'b00001110000010100001101010111001;
			7'b1111111 		: exp = 32'b00001101101011000001101001011100;
            default: exp = 0;
        endcase
    end
endmodule
