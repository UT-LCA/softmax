module logunit_fixed (a, z, status);

	
	input [31:0] a;
	output reg [31:0] z;
	output [7:0] statusl
	wire [31: 0] fx;
	wire [31:0] temp;	

	fixedtofpln fptofx3(.fp(a),.fx(fx));
	DW_fp_ln #(23,8,1,0,0) ln(.a(fx), .z(z), .status(status));

endmodule

module fixedtofpln (
	fp,
	fx
	);
	
	

	input [31:0] fp; // Half Precision fp
	output [31:0] fx;  
	
	wire [31:0] dec;
	wire [5:0] enc;

	wire [7:0] log;
	wire [30:0] temp;
	//wire grt;
	wire [30:0] temp2;
	reg [31:0] temp3;

	assign temp = fp[30:0];
	assign fx = {1'b0,log,temp3[30:8]};

always @(temp2)
begin
	if (dec[31:0] == 0)
		begin
			temp3 <= 31'h00000000;		
		end

	else 
		begin
			temp3 <= temp2;
		end
end	

always @(enc) begin
 	case (enc[4:0])
			5'b0 		: log = 8'b10001110;
			5'b1 		: log = 8'b10001101;
			5'b10 		: log = 8'b10001100;
			5'b11 		: log = 8'b10001011;
			5'b100 		: log = 8'b10001010;
			5'b101 		: log = 8'b10001001;
			5'b110 		: log = 8'b10001000;
			5'b111 		: log = 8'b10000111;
			5'b1000 		: log = 8'b10000110;
			5'b1001 		: log = 8'b10000101;
			5'b1010 		: log = 8'b10000100;
			5'b1011 		: log = 8'b10000011;
			5'b1100 		: log = 8'b10000010;
			5'b1101 		: log = 8'b10000001;
			5'b1110 		: log = 8'b10000000;
			5'b1111 		: log = 8'b01111111;
			5'b10000 		: log = 8'b01111110;
			5'b10001 		: log = 8'b01111101;
			5'b10010 		: log = 8'b01111100;
			5'b10011 		: log = 8'b01111011;
			5'b10100 		: log = 8'b01111010;
			5'b10101 		: log = 8'b01111001;
			5'b10110 		: log = 8'b01111000;
			5'b10111 		: log = 8'b01110111;
			5'b11000 		: log = 8'b01110110;
			5'b11001 		: log = 8'b01110101;
			5'b11010 		: log = 8'b01110100;
			5'b11011 		: log = 8'b01110011;
			5'b11100 		: log = 8'b01110010;
			5'b11101 		: log = 8'b01110001;
			5'b11110 		: log = 8'b01110000;
			5'b11111 		: log = 8'b01101111;
        endcase
end

DW_lzd #(32) lzd (.a(fp),.enc(enc),.dec(dec));
DW01_ash #(31,6) ash( .A(temp[30:0]), .DATA_TC(1'b0), .SH(enc), .SH_TC(1'b0), .B(temp2));
//DW01_addsub #(32) addsub1 (.A(fp),.B(32'h00000001),.CI(1'b0),.ADD_SUB(1'b1),.SUM(temp),.CO());
endmodule
