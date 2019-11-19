//`include "defines.v"
module logunit (a, z, status);

	
	input [15:0] a;
	output [15:0] z;
	output [7:0] status;

	wire [15: 0] fxout1;
	wire [15: 0] fxout2;


	LUT1 lut1 (.addr(a[14:10]),.log(fxout1)); 
	LUT2 lut2 (.addr(a[9:2]),.log(fxout2));  
	DW_fp_addsub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add(.a(fxout1), .b(fxout2), .rnd(3'b0), .op(1'b0), .z(z), .status(status[7:0]));
endmodule

module LUT1(addr, log);
    input [4:0] addr;
    output reg [15:0] log;

    always @(addr) begin
        case (addr)
			5'b0 		: log = 16'b1111110000000000;
			5'b1 		: log = 16'b1100100011011010;
			5'b10 		: log = 16'b1100100010000001;
			5'b11 		: log = 16'b1100100000101001;
			5'b100 		: log = 16'b1100011110100000;
			5'b101 		: log = 16'b1100011011101110;
			5'b110 		: log = 16'b1100011000111101;
			5'b111 		: log = 16'b1100010110001100;
			5'b1000 		: log = 16'b1100010011011010;
			5'b1001 		: log = 16'b1100010000101001;
			5'b1010 		: log = 16'b1100001011101110;
			5'b1011 		: log = 16'b1100000110001100;
			5'b1100 		: log = 16'b1100000000101001;
			5'b1101 		: log = 16'b1011110110001100;
			5'b1110 		: log = 16'b1011100110001100;
			5'b1111 		: log = 16'b0000000000000000;
			5'b10000 		: log = 16'b0011100110001100;
			5'b10001 		: log = 16'b0011110110001100;
			5'b10010 		: log = 16'b0100000000101001;
			5'b10011 		: log = 16'b0100000110001100;
			5'b10100 		: log = 16'b0100001011101110;
			5'b10101 		: log = 16'b0100010000101001;
			5'b10110 		: log = 16'b0100010011011010;
			5'b10111 		: log = 16'b0100010110001100;
			5'b11000 		: log = 16'b0100011000111101;
			5'b11001 		: log = 16'b0100011011101110;
			5'b11010 		: log = 16'b0100011110100000;
			5'b11011 		: log = 16'b0100100000101001;
			5'b11100 		: log = 16'b0100100010000001;
			5'b11101 		: log = 16'b0100100011011010;
			5'b11110 		: log = 16'b0100100100110011;
			5'b11111 		: log = 16'b0111110000000000;
        endcase
    end
endmodule

module LUT2(addr, log);
    input [7:0] addr;
    output reg [15:0] log;

    always @(addr) begin
        case (addr)
			8'b0 		: log = 16'b0000000000000000;
			8'b1 		: log = 16'b0001101111111100;
			8'b10 		: log = 16'b0001111111111000;
			8'b11 		: log = 16'b0010000111110111;
			8'b100 		: log = 16'b0010001111110000;
			8'b101 		: log = 16'b0010010011110100;
			8'b110 		: log = 16'b0010010111101110;
			8'b111 		: log = 16'b0010011011101000;
			8'b1000 		: log = 16'b0010011111100001;
			8'b1001 		: log = 16'b0010100001101100;
			8'b1010 		: log = 16'b0010100011101000;
			8'b1011 		: log = 16'b0010100101100011;
			8'b1100 		: log = 16'b0010100111011101;
			8'b1101 		: log = 16'b0010101001010111;
			8'b1110 		: log = 16'b0010101011010001;
			8'b1111 		: log = 16'b0010101101001010;
			8'b10000 		: log = 16'b0010101111000011;
			8'b10001 		: log = 16'b0010110000011101;
			8'b10010 		: log = 16'b0010110001011001;
			8'b10011 		: log = 16'b0010110010010101;
			8'b10100 		: log = 16'b0010110011010000;
			8'b10101 		: log = 16'b0010110100001100;
			8'b10110 		: log = 16'b0010110101000111;
			8'b10111 		: log = 16'b0010110110000010;
			8'b11000 		: log = 16'b0010110110111100;
			8'b11001 		: log = 16'b0010110111110111;
			8'b11010 		: log = 16'b0010111000110001;
			8'b11011 		: log = 16'b0010111001101011;
			8'b11100 		: log = 16'b0010111010100101;
			8'b11101 		: log = 16'b0010111011011110;
			8'b11110 		: log = 16'b0010111100011000;
			8'b11111 		: log = 16'b0010111101010001;
			8'b100000 		: log = 16'b0010111110001010;
			8'b100001 		: log = 16'b0010111111000011;
			8'b100010 		: log = 16'b0010111111111011;
			8'b100011 		: log = 16'b0011000000011010;
			8'b100100 		: log = 16'b0011000000110110;
			8'b100101 		: log = 16'b0011000001010010;
			8'b100110 		: log = 16'b0011000001101110;
			8'b100111 		: log = 16'b0011000010001010;
			8'b101000 		: log = 16'b0011000010100101;
			8'b101001 		: log = 16'b0011000011000001;
			8'b101010 		: log = 16'b0011000011011100;
			8'b101011 		: log = 16'b0011000011111000;
			8'b101100 		: log = 16'b0011000100010011;
			8'b101101 		: log = 16'b0011000100101111;
			8'b101110 		: log = 16'b0011000101001010;
			8'b101111 		: log = 16'b0011000101100101;
			8'b110000 		: log = 16'b0011000110000000;
			8'b110001 		: log = 16'b0011000110011011;
			8'b110010 		: log = 16'b0011000110110110;
			8'b110011 		: log = 16'b0011000111010000;
			8'b110100 		: log = 16'b0011000111101011;
			8'b110101 		: log = 16'b0011001000000101;
			8'b110110 		: log = 16'b0011001000100000;
			8'b110111 		: log = 16'b0011001000111010;
			8'b111000 		: log = 16'b0011001001010101;
			8'b111001 		: log = 16'b0011001001101111;
			8'b111010 		: log = 16'b0011001010001001;
			8'b111011 		: log = 16'b0011001010100011;
			8'b111100 		: log = 16'b0011001010111101;
			8'b111101 		: log = 16'b0011001011010111;
			8'b111110 		: log = 16'b0011001011110001;
			8'b111111 		: log = 16'b0011001100001010;
			8'b1000000 		: log = 16'b0011001100100100;
			8'b1000001 		: log = 16'b0011001100111110;
			8'b1000010 		: log = 16'b0011001101010111;
			8'b1000011 		: log = 16'b0011001101110000;
			8'b1000100 		: log = 16'b0011001110001010;
			8'b1000101 		: log = 16'b0011001110100011;
			8'b1000110 		: log = 16'b0011001110111100;
			8'b1000111 		: log = 16'b0011001111010101;
			8'b1001000 		: log = 16'b0011001111101110;
			8'b1001001 		: log = 16'b0011010000000100;
			8'b1001010 		: log = 16'b0011010000010000;
			8'b1001011 		: log = 16'b0011010000011100;
			8'b1001100 		: log = 16'b0011010000101001;
			8'b1001101 		: log = 16'b0011010000110101;
			8'b1001110 		: log = 16'b0011010001000001;
			8'b1001111 		: log = 16'b0011010001001110;
			8'b1010000 		: log = 16'b0011010001011010;
			8'b1010001 		: log = 16'b0011010001100110;
			8'b1010010 		: log = 16'b0011010001110010;
			8'b1010011 		: log = 16'b0011010001111110;
			8'b1010100 		: log = 16'b0011010010001010;
			8'b1010101 		: log = 16'b0011010010010110;
			8'b1010110 		: log = 16'b0011010010100010;
			8'b1010111 		: log = 16'b0011010010101110;
			8'b1011000 		: log = 16'b0011010010111010;
			8'b1011001 		: log = 16'b0011010011000110;
			8'b1011010 		: log = 16'b0011010011010010;
			8'b1011011 		: log = 16'b0011010011011110;
			8'b1011100 		: log = 16'b0011010011101010;
			8'b1011101 		: log = 16'b0011010011110101;
			8'b1011110 		: log = 16'b0011010100000001;
			8'b1011111 		: log = 16'b0011010100001101;
			8'b1100000 		: log = 16'b0011010100011000;
			8'b1100001 		: log = 16'b0011010100100100;
			8'b1100010 		: log = 16'b0011010100110000;
			8'b1100011 		: log = 16'b0011010100111011;
			8'b1100100 		: log = 16'b0011010101000111;
			8'b1100101 		: log = 16'b0011010101010010;
			8'b1100110 		: log = 16'b0011010101011110;
			8'b1100111 		: log = 16'b0011010101101001;
			8'b1101000 		: log = 16'b0011010101110100;
			8'b1101001 		: log = 16'b0011010110000000;
			8'b1101010 		: log = 16'b0011010110001011;
			8'b1101011 		: log = 16'b0011010110010110;
			8'b1101100 		: log = 16'b0011010110100010;
			8'b1101101 		: log = 16'b0011010110101101;
			8'b1101110 		: log = 16'b0011010110111000;
			8'b1101111 		: log = 16'b0011010111000011;
			8'b1110000 		: log = 16'b0011010111001110;
			8'b1110001 		: log = 16'b0011010111011010;
			8'b1110010 		: log = 16'b0011010111100101;
			8'b1110011 		: log = 16'b0011010111110000;
			8'b1110100 		: log = 16'b0011010111111011;
			8'b1110101 		: log = 16'b0011011000000110;
			8'b1110110 		: log = 16'b0011011000010001;
			8'b1110111 		: log = 16'b0011011000011100;
			8'b1111000 		: log = 16'b0011011000100111;
			8'b1111001 		: log = 16'b0011011000110001;
			8'b1111010 		: log = 16'b0011011000111100;
			8'b1111011 		: log = 16'b0011011001000111;
			8'b1111100 		: log = 16'b0011011001010010;
			8'b1111101 		: log = 16'b0011011001011101;
			8'b1111110 		: log = 16'b0011011001100111;
			8'b1111111 		: log = 16'b0011011001110010;
			8'b10000000 		: log = 16'b0011011001111101;
			8'b10000001 		: log = 16'b0011011010000111;
			8'b10000010 		: log = 16'b0011011010010010;
			8'b10000011 		: log = 16'b0011011010011101;
			8'b10000100 		: log = 16'b0011011010100111;
			8'b10000101 		: log = 16'b0011011010110010;
			8'b10000110 		: log = 16'b0011011010111100;
			8'b10000111 		: log = 16'b0011011011000111;
			8'b10001000 		: log = 16'b0011011011010001;
			8'b10001001 		: log = 16'b0011011011011100;
			8'b10001010 		: log = 16'b0011011011100110;
			8'b10001011 		: log = 16'b0011011011110000;
			8'b10001100 		: log = 16'b0011011011111011;
			8'b10001101 		: log = 16'b0011011100000101;
			8'b10001110 		: log = 16'b0011011100001111;
			8'b10001111 		: log = 16'b0011011100011010;
			8'b10010000 		: log = 16'b0011011100100100;
			8'b10010001 		: log = 16'b0011011100101110;
			8'b10010010 		: log = 16'b0011011100111000;
			8'b10010011 		: log = 16'b0011011101000011;
			8'b10010100 		: log = 16'b0011011101001101;
			8'b10010101 		: log = 16'b0011011101010111;
			8'b10010110 		: log = 16'b0011011101100001;
			8'b10010111 		: log = 16'b0011011101101011;
			8'b10011000 		: log = 16'b0011011101110101;
			8'b10011001 		: log = 16'b0011011101111111;
			8'b10011010 		: log = 16'b0011011110001001;
			8'b10011011 		: log = 16'b0011011110010011;
			8'b10011100 		: log = 16'b0011011110011101;
			8'b10011101 		: log = 16'b0011011110100111;
			8'b10011110 		: log = 16'b0011011110110001;
			8'b10011111 		: log = 16'b0011011110111011;
			8'b10100000 		: log = 16'b0011011111000101;
			8'b10100001 		: log = 16'b0011011111001110;
			8'b10100010 		: log = 16'b0011011111011000;
			8'b10100011 		: log = 16'b0011011111100010;
			8'b10100100 		: log = 16'b0011011111101100;
			8'b10100101 		: log = 16'b0011011111110110;
			8'b10100110 		: log = 16'b0011011111111111;
			8'b10100111 		: log = 16'b0011100000000100;
			8'b10101000 		: log = 16'b0011100000001001;
			8'b10101001 		: log = 16'b0011100000001110;
			8'b10101010 		: log = 16'b0011100000010011;
			8'b10101011 		: log = 16'b0011100000011000;
			8'b10101100 		: log = 16'b0011100000011101;
			8'b10101101 		: log = 16'b0011100000100001;
			8'b10101110 		: log = 16'b0011100000100110;
			8'b10101111 		: log = 16'b0011100000101011;
			8'b10110000 		: log = 16'b0011100000110000;
			8'b10110001 		: log = 16'b0011100000110100;
			8'b10110010 		: log = 16'b0011100000111001;
			8'b10110011 		: log = 16'b0011100000111110;
			8'b10110100 		: log = 16'b0011100001000010;
			8'b10110101 		: log = 16'b0011100001000111;
			8'b10110110 		: log = 16'b0011100001001100;
			8'b10110111 		: log = 16'b0011100001010001;
			8'b10111000 		: log = 16'b0011100001010101;
			8'b10111001 		: log = 16'b0011100001011010;
			8'b10111010 		: log = 16'b0011100001011110;
			8'b10111011 		: log = 16'b0011100001100011;
			8'b10111100 		: log = 16'b0011100001101000;
			8'b10111101 		: log = 16'b0011100001101100;
			8'b10111110 		: log = 16'b0011100001110001;
			8'b10111111 		: log = 16'b0011100001110110;
			8'b11000000 		: log = 16'b0011100001111010;
			8'b11000001 		: log = 16'b0011100001111111;
			8'b11000010 		: log = 16'b0011100010000011;
			8'b11000011 		: log = 16'b0011100010001000;
			8'b11000100 		: log = 16'b0011100010001100;
			8'b11000101 		: log = 16'b0011100010010001;
			8'b11000110 		: log = 16'b0011100010010101;
			8'b11000111 		: log = 16'b0011100010011010;
			8'b11001000 		: log = 16'b0011100010011110;
			8'b11001001 		: log = 16'b0011100010100011;
			8'b11001010 		: log = 16'b0011100010100111;
			8'b11001011 		: log = 16'b0011100010101100;
			8'b11001100 		: log = 16'b0011100010110000;
			8'b11001101 		: log = 16'b0011100010110101;
			8'b11001110 		: log = 16'b0011100010111001;
			8'b11001111 		: log = 16'b0011100010111110;
			8'b11010000 		: log = 16'b0011100011000010;
			8'b11010001 		: log = 16'b0011100011000110;
			8'b11010010 		: log = 16'b0011100011001011;
			8'b11010011 		: log = 16'b0011100011001111;
			8'b11010100 		: log = 16'b0011100011010100;
			8'b11010101 		: log = 16'b0011100011011000;
			8'b11010110 		: log = 16'b0011100011011100;
			8'b11010111 		: log = 16'b0011100011100001;
			8'b11011000 		: log = 16'b0011100011100101;
			8'b11011001 		: log = 16'b0011100011101001;
			8'b11011010 		: log = 16'b0011100011101110;
			8'b11011011 		: log = 16'b0011100011110010;
			8'b11011100 		: log = 16'b0011100011110110;
			8'b11011101 		: log = 16'b0011100011111011;
			8'b11011110 		: log = 16'b0011100011111111;
			8'b11011111 		: log = 16'b0011100100000011;
			8'b11100000 		: log = 16'b0011100100000111;
			8'b11100001 		: log = 16'b0011100100001100;
			8'b11100010 		: log = 16'b0011100100010000;
			8'b11100011 		: log = 16'b0011100100010100;
			8'b11100100 		: log = 16'b0011100100011000;
			8'b11100101 		: log = 16'b0011100100011101;
			8'b11100110 		: log = 16'b0011100100100001;
			8'b11100111 		: log = 16'b0011100100100101;
			8'b11101000 		: log = 16'b0011100100101001;
			8'b11101001 		: log = 16'b0011100100101101;
			8'b11101010 		: log = 16'b0011100100110010;
			8'b11101011 		: log = 16'b0011100100110110;
			8'b11101100 		: log = 16'b0011100100111010;
			8'b11101101 		: log = 16'b0011100100111110;
			8'b11101110 		: log = 16'b0011100101000010;
			8'b11101111 		: log = 16'b0011100101000110;
			8'b11110000 		: log = 16'b0011100101001011;
			8'b11110001 		: log = 16'b0011100101001111;
			8'b11110010 		: log = 16'b0011100101010011;
			8'b11110011 		: log = 16'b0011100101010111;
			8'b11110100 		: log = 16'b0011100101011011;
			8'b11110101 		: log = 16'b0011100101011111;
			8'b11110110 		: log = 16'b0011100101100011;
			8'b11110111 		: log = 16'b0011100101100111;
			8'b11111000 		: log = 16'b0011100101101011;
			8'b11111001 		: log = 16'b0011100101101111;
			8'b11111010 		: log = 16'b0011100101110011;
			8'b11111011 		: log = 16'b0011100101110111;
			8'b11111100 		: log = 16'b0011100101111100;
			8'b11111101 		: log = 16'b0011100110000000;
			8'b11111110 		: log = 16'b0011100110000100;
			8'b11111111 		: log = 16'b0011100110001000;
        endcase
    end
endmodule
