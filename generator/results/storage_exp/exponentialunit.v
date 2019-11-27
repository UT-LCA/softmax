
module expunit (a, z, status, stage_run, clk, reset);

  parameter int_width = 3; // fixed point integer length
  parameter frac_width = 3; // fixed point fraction length
  	
  input [15:0] a;
  input stage_run;
  input clk;
  input reset;
  output [15:0] z;
  output [7:0] status;
  
  wire [int_width + frac_width - 1: 0] fxout;
  wire [31:0] LUTout;
  reg  [31:0] LUTout_reg;
  wire [15:0] Mult_out;
  reg  [15:0] Mult_out_reg;

  always @(posedge clk) begin
    if(reset) begin
      Mult_out_reg <= 0;
      LUTout_reg <= 0;
    end else if(stage_run) begin
      Mult_out_reg <= Mult_out;
      LUTout_reg <= LUTout;
    end
  end

  
        
  fptofixed_para fpfx (.fp(a), .fx(fxout));
  LUT lut(.addr(fxout[int_width + frac_width - 1 : 0]), .exp(LUTout)); 
  DW_fp_mult #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) fpmult (.a(a), .b(LUTout[31:16]), .rnd(3'b000), .z(Mult_out), .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) fpsub (.a(Mult_out_reg), .b(LUTout_reg[15:0]), .rnd(3'b000), .z(z), .status(status[7:0]));
endmodule

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

module LUT(addr, exp);
    input [5:0] addr;
    output reg [31:0] exp;

    always @(addr) begin
        case (addr)
			6'b0 		: exp = 32'b00111011110000010011110000000000;
			6'b1 		: exp = 32'b00111010110110000011101111101010;
			6'b10 		: exp = 32'b00111010000010100011101110111110;
			6'b11 		: exp = 32'b00111001010101000011101101111111;
			6'b100 		: exp = 32'b00111000101101000011101100110100;
			6'b101 		: exp = 32'b00111000001001110011101011100000;
			6'b110 		: exp = 32'b00110111010101000011101010000111;
			6'b111 		: exp = 32'b00110110011101110011101000101010;
			6'b1000 		: exp = 32'b00110101101101010011100111001100;
			6'b1001 		: exp = 32'b00110101000010010011100101101110;
			6'b1010 		: exp = 32'b00110100011100100011100100010010;
			6'b1011 		: exp = 32'b00110011110110000011100010111000;
			6'b1100 		: exp = 32'b00110010111011000011100001100001;
			6'b1101 		: exp = 32'b00110010000111000011100000001111;
			6'b1110 		: exp = 32'b00110001011001000011011101111111;
			6'b1111 		: exp = 32'b00110000110000100011011011101010;
			6'b10000 		: exp = 32'b00110000001100110011011001011101;
			6'b10001 		: exp = 32'b00101111011010010011010111011001;
			6'b10010 		: exp = 32'b00101110100010100011010101011101;
			6'b10011 		: exp = 32'b00101101110001010011010011101010;
			6'b10100 		: exp = 32'b00101101000110000011010001111111;
			6'b10101 		: exp = 32'b00101100011111110011010000011100;
			6'b10110 		: exp = 32'b00101011111011110011001110000000;
			6'b10111 		: exp = 32'b00101011000000000011001011010110;
			6'b11000 		: exp = 32'b00101010001011010011001000111010;
			6'b11001 		: exp = 32'b00101001011101000011000110101010;
			6'b11010 		: exp = 32'b00101000110100000011000100100110;
			6'b11011 		: exp = 32'b00101000001111110011000010101101;
			6'b11100 		: exp = 32'b00100111011111100011000000111111;
			6'b11101 		: exp = 32'b00100110100111010010111110110011;
			6'b11110 		: exp = 32'b00100101110101100010111011111010;
			6'b11111 		: exp = 32'b00100101001001110010111001010001;
			6'b100000 		: exp = 32'b00100100100011000010110110111000;
			6'b100001 		: exp = 32'b00100100000000110010110100101100;
			6'b100010 		: exp = 32'b00100011000101000010110010101101;
			6'b100011 		: exp = 32'b00100010001111110010110000111001;
			6'b100100 		: exp = 32'b00100001100001000010101110100000;
			6'b100101 		: exp = 32'b00100000110111100010101011100010;
			6'b100110 		: exp = 32'b00100000010010110010101000110101;
			6'b100111 		: exp = 32'b00011111100101000010100110011001;
			6'b101000 		: exp = 32'b00011110101100000010100100001011;
			6'b101001 		: exp = 32'b00011101111001110010100010001011;
			6'b101010 		: exp = 32'b00011101001101010010100000010111;
			6'b101011 		: exp = 32'b00011100100110010010011101011101;
			6'b101100 		: exp = 32'b00011100000011110010011010100000;
			6'b101101 		: exp = 32'b00011011001010010010010111110101;
			6'b101110 		: exp = 32'b00011010010100100010010101011011;
			6'b101111 		: exp = 32'b00011001100101000010010011010000;
			6'b110000 		: exp = 32'b00011000111011000010010001010011;
			6'b110001 		: exp = 32'b00011000010110000010001111000101;
			6'b110010 		: exp = 32'b00010111101010100010001011111010;
			6'b110011 		: exp = 32'b00010110110001000010001001000011;
			6'b110100 		: exp = 32'b00010101111110000010000110011111;
			6'b110101 		: exp = 32'b00010101010001010010000100001011;
			6'b110110 		: exp = 32'b00010100101001100010000010000110;
			6'b110111 		: exp = 32'b00010100000110100010000000001110;
			6'b111000 		: exp = 32'b00010011001111100001111101000101;
			6'b111001 		: exp = 32'b00010010011001000001111010000100;
			6'b111010 		: exp = 32'b00010001101001000001110111010111;
			6'b111011 		: exp = 32'b00010000111110100001110100111011;
			6'b111100 		: exp = 32'b00010000011001000001110010101111;
			6'b111101 		: exp = 32'b00001111110000010001110000110010;
			6'b111110 		: exp = 32'b00001110110101110001101110000010;
			6'b111111 		: exp = 32'b00001110000010100001101010111001;
        endcase
    end
endmodule
