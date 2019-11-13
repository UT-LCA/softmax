

`timescale 1ns / 1ps

//fixed adder adds unsigned fixed numbers. Overflow flag is high in case of overflow
module softmax(
  inp1,
  inp2,
  inp3,
  inp4,  
  outp1,
  outp2,
  outp3,
  outp4,  
  clk, 
  reset, 
  start,
  done);
  
  input clk;
  input reset;
  input start;
  
  input  [31:0] inp1;
  input  [31:0] inp2;
  input  [31:0] inp3;
  input  [31:0] inp4;
  
  reg [2:0] status_counter;
  
  output [31:0] outp1;
  output [31:0] outp2;
  output [31:0] outp3;
  output [31:0] outp4;
  
  reg [31:0] outp1;
  reg [31:0] outp2;
  reg [31:0] outp3;
  reg [31:0] outp4;

  output done;
  
  ///-------status counter--------///////
  
  reg done;
  reg we;
  always @(posedge clk)
  begin
    if(reset) begin
	  status_counter <= 0;
	end else if(!start && status_counter == 3'b000) begin
	  status_counter <= 0;
	end else begin
	  status_counter <= status_counter + 1;
    end
  end
  
  always @(status_counter)
  begin
	case(status_counter)
	  3'b111: done <= 1;
	  default: done <= 0;
	endcase
  end
  
  
  ////------sorting block---------///////
  wire [31:0] max_inp_temp;
  reg  [31:0] max_inp;
  
  Sorting_Block_4 sort_block(.inp1(inp1), .inp2(inp2), .inp3(inp3), .inp4(inp4), .outp(max_inp_temp));
  
  always @(posedge clk)
  begin
    if(reset)begin
	   max_inp <= 0;
	end else if(status_counter == 3'b001)begin
	   max_inp <= max_inp_temp;
	end
  end
  
  ////------store the value in the small ram---------//
  wire [31:0] outp_mem1_temp;
  wire [31:0] outp_mem2_temp;
  wire [31:0] outp_mem3_temp;
  wire [31:0] outp_mem4_temp;
  
  wire [31:0] inp_mem1;
  wire [31:0] inp_mem2;
  wire [31:0] inp_mem3;
  wire [31:0] inp_mem4;
  
  assign inp_mem1 = (status_counter == 3'b001)? inp1 : outp_sub1_temp;
  assign inp_mem2 = (status_counter == 3'b001)? inp2 : outp_sub2_temp;
  assign inp_mem3 = (status_counter == 3'b001)? inp3 : outp_sub3_temp;
  assign inp_mem4 = (status_counter == 3'b001)? inp4 : outp_sub4_temp;
  
  single_port_ram ram_1(.data(inp_mem1), .addr(2'b00), .we(we), .clk(clk), .q(outp_mem1_temp));
  single_port_ram ram_2(.data(inp_mem2), .addr(2'b01), .we(we), .clk(clk), .q(outp_mem2_temp));
  single_port_ram ram_3(.data(inp_mem3), .addr(2'b10), .we(we), .clk(clk), .q(outp_mem3_temp));
  single_port_ram ram_4(.data(inp_mem4), .addr(2'b11), .we(we), .clk(clk), .q(outp_mem4_temp));
  
  always @(posedge clk)
  begin
    if(reset) begin
	  we <= 0;
	end else if(status_counter == 3'b000 || status_counter == 3'b010)begin
	  we <= 1;
	end
  end
  
  ////------subtraction---------///////
  wire [31:0] outp_sub1_temp;
  wire [31:0] outp_sub2_temp;
  wire [31:0] outp_sub3_temp;
  wire [31:0] outp_sub4_temp;
  
  wire [31:0] sub_inp_temp;
  
  assign sub_inp_temp = (status_counter == 3'b001)? max_inp_temp : outp_log_temp;
  
  DW_fp_sub sub1_1(.a(outp_mem1_temp), .b(sub_inp_temp), .z(outp_sub1_temp), .rnd(3'b000));
  DW_fp_sub sub1_2(.a(outp_mem2_temp), .b(sub_inp_temp), .z(outp_sub2_temp), .rnd(3'b000));
  DW_fp_sub sub1_3(.a(outp_mem3_temp), .b(sub_inp_temp), .z(outp_sub3_temp), .rnd(3'b000));
  DW_fp_sub sub1_4(.a(outp_mem4_temp), .b(sub_inp_temp), .z(outp_sub4_temp), .rnd(3'b000));
  
  reg [31:0] outp_sub1;
  reg [31:0] outp_sub2;
  reg [31:0] outp_sub3;
  reg [31:0] outp_sub4;
  
  always @(posedge clk)
  begin
    if(reset)begin
	  outp_sub1 <= 0;
	  outp_sub2 <= 0;
	  outp_sub3 <= 0;
	  outp_sub4 <= 0;
	end else if(status_counter == 3'b010) begin
	  outp_sub1 <= outp_sub1_temp;
	  outp_sub2 <= outp_sub2_temp;
	  outp_sub3 <= outp_sub3_temp;
	  outp_sub4 <= outp_sub4_temp;
	end
  end
  
  ////------feed into exponential---------///////
  wire [31:0] outp_exp1_temp;
  wire [31:0] outp_exp2_temp;
  wire [31:0] outp_exp3_temp;
  wire [31:0] outp_exp4_temp;
  
  wire [31:0] inp_exp1;
  wire [31:0] inp_exp2;
  wire [31:0] inp_exp3;
  wire [31:0] inp_exp4;
  
  assign inp_exp1 = outp_sub1;
  assign inp_exp2 = outp_sub2;
  assign inp_exp3 = outp_sub3;
  assign inp_exp4 = outp_sub4;
  
  DW_fp_exp exp1(.a(inp_exp1), .z(outp_exp1_temp));
  DW_fp_exp exp2(.a(inp_exp2), .z(outp_exp2_temp));
  DW_fp_exp exp3(.a(inp_exp3), .z(outp_exp3_temp));
  DW_fp_exp exp4(.a(inp_exp4), .z(outp_exp4_temp));
  
  always @(posedge clk)
  begin
    if(reset) begin
	  outp1 <= 0;
	  outp2 <= 0;
	  outp3 <= 0;
	  outp4 <= 0;
	end else if(done == 1) begin
	  outp1 <= outp_exp1_temp;
	  outp2 <= outp_exp2_temp;
	  outp3 <= outp_exp3_temp;
	  outp4 <= outp_exp4_temp;
	end
  end
  
  reg [31:0] outp_exp1;
  reg [31:0] outp_exp2;
  reg [31:0] outp_exp3;
  reg [31:0] outp_exp4;
  
  always @(posedge clk)
  begin
    if(reset) begin
	  outp_exp1 <= 0;
	  outp_exp2 <= 0;
	  outp_exp3 <= 0;
	  outp_exp4 <= 0;
	end else if(status_counter == 3'b011)begin
	  outp_exp1 <= outp_exp1_temp;
	  outp_exp2 <= outp_exp2_temp;
	  outp_exp3 <= outp_exp3_temp;
	  outp_exp4 <= outp_exp4_temp;
	end
  end
  
  //////------feed into adder tree---------///////
  wire [31:0] outp_add_temp;
  reg  [31:0] outp_add;
  adder_tree_4 adder_tree(.inp1(outp_exp1), .inp2(outp_exp2), .inp3(outp_exp3), 
				 .inp4(outp_exp4), .outp(outp_add_temp));
  
  always @(posedge clk)
  begin
    if(reset) begin
	  outp_add <= 0;
	end else if(status_counter == 3'b100) begin
	  outp_add <= outp_add_temp;
	end
  end
  
  //////------feed into log unit---------///////
  wire [31:0] outp_log_temp;
  reg  [31:0] outp_log;
  DW_fp_ln log(.a(outp_add), .z(outp_log_temp));
  
  always @(posedge clk)
  begin
	if(reset) begin
	  outp_log <= 0;
	end else if(status_counter == 3'b101) begin
	  outp_log <= outp_log_temp;
    end
  end
  
  //////------subtract the log output from the value---------///////
  /*wire [31:0] outp_sub2_1_temp;
  wire [31:0] outp_sub2_2_temp;
  wire [31:0] outp_sub2_3_temp;
  wire [31:0] outp_sub2_4_temp;
  
  DW_fp_sub sub2_1(.a(outp_sub1), .b(outp_log), .z(outp_sub2_1_temp), .rnd(3'b000));
  DW_fp_sub sub2_2(.a(outp_sub2), .b(outp_log), .z(outp_sub2_2_temp), .rnd(3'b000));
  DW_fp_sub sub2_3(.a(outp_sub3), .b(outp_log), .z(outp_sub2_3_temp), .rnd(3'b000));
  DW_fp_sub sub2_4(.a(outp_sub4), .b(outp_log), .z(outp_sub2_4_temp), .rnd(3'b000));
  
  reg [31:0] outp_sub2_1;
  reg [31:0] outp_sub2_2;
  reg [31:0] outp_sub2_3;
  reg [31:0] outp_sub2_4;
  
  always @(posedge clk)
  begin
    if(reset) begin
	  outp_sub2_1 <= 0;
	  outp_sub2_2 <= 0;
	  outp_sub2_3 <= 0;
	  outp_sub2_4 <= 0;
	end else if(status_counter == 3'b110) begin
	  outp_sub2_1 <= outp_sub2_1_temp;
	  outp_sub2_2 <= outp_sub2_2_temp;
	  outp_sub2_3 <= outp_sub2_3_temp;
	  outp_sub2_4 <= outp_sub2_4_temp;
	end
  end*/
  
	  
	  
  
endmodule

///////-----adder tree with 4 inputs------------------//////////
module adder_tree_4(inp1, inp2, inp3, inp4, outp);
  input  [31:0] inp1;
  input  [31:0] inp2;
  input  [31:0] inp3;
  input  [31:0] inp4;
  
  output [31:0] outp;
  
  wire [31:0] outp_add1;
  wire [31:0] outp_add2;
  DW_fp_add add1(.a(inp1), .b(inp2), .z(outp_add1), .rnd(3'b000));
  DW_fp_add add2(.a(inp3), .b(inp4), .z(outp_add2), .rnd(3'b000));
  DW_fp_add add3(.a(outp_add1), .b(outp_add2), .z(outp), .rnd(3'b000));
  
endmodule

//////------sort 4 inputs and generate 1 max output---------///////
module Sorting_Block_4(inp1, inp2, inp3, inp4, outp);
  input [31:0] inp1;
  input [31:0] inp2;
  input [31:0] inp3;
  input [31:0] inp4;
  output [31:0] outp;
  
  wire [31:0] outp_cmp1;
  wire [31:0] outp_cmp2;

  DW_fp_cmp cmp1(.a(inp1), .b(inp2), .z1(outp_cmp1), .zctr(1'b0));
  DW_fp_cmp cmp2(.a(inp3), .b(inp4), .z1(outp_cmp2), .zctr(1'b0));
  DW_fp_cmp cmp3(.a(outp_cmp1), .b(outp_cmp2), .z1(outp), .zctr(1'b0));
  
endmodule

`define DWIDTH 32
`define NUM 1

module single_port_ram
(
	input  [`DWIDTH*`NUM - 1:0] data,
	input  [1:0] addr,
	input we, clk,
	output [`DWIDTH*`NUM - 1:0] q
);

	// Declare the RAM variable
	reg [`DWIDTH*`NUM - 1 : 0] ram [1:0];
	
	// Variable to hold the registered read address
	reg [1 : 0] addr_reg;
	
	always @ (posedge clk)
	begin
	// Write
		if (we)
			ram[addr] <= data;
		
		addr_reg <= addr;
		
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.
	assign q = ram[addr_reg];

endmodule




