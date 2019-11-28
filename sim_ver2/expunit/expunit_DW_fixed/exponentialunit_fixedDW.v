module expunit_fixed (a, z, status, stage_run, clk, reset);

		
	input [31:0] a;
	input stage_run;
  	input clk;
  	input reset;
	output [31:0] z;
	output [7:0] status;

	wire [31:0] fp_out;
	reg [31:0] fp_out_reg;
	wire [31:0] fx;
	wire [31:0] fx2;

	always @(posedge clk) begin
    		if(reset) begin
      		fp_out_reg <= 0;
    		end else if(stage_run) begin
      		fp_out_reg <= fp_out;
    		end
  	end

	//fptofixed_para fpfx (.fp(a), .fx(fxout));
	fptofixed_para fptofx2 (.fp(a),.fx(fx));
	fixedtofp  fxtofp2 (.fp(fx),.fx(fp_out));
	DW_fp_exp #(23,8,1,2) expfxdw (.a(fp_out_reg), .z(z), .status(status));
	
endmodule

module fixedtofp (
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
	assign fx = {1'b1,log,temp3[30:8]};

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

module fptofixed_para (
	fp,
	fx
	);
	

	input [31:0] fp; // Half Precision fp
	output [31:0] fx;  

	wire [31:0] temp;

	assign fx = ~(temp[31:0]);	

DW01_addsub #(32) addsub1 (.A(fp),.B(32'h00000001),.CI(1'b0),.ADD_SUB(1'b1),.SUM(temp),.CO());
endmodule
