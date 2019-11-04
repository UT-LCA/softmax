

`timescale 1ns / 1ps
`define DATAWIDTH 16
`define NUM 4
//fixed adder adds unsigned fixed numbers. Overflow flag is high in case of overflow
module softmax(
  inp,
  sub0_inp,
  sub1_inp,
  
  outp0,
  outp1,
  outp2,
  outp3,

  clk, 
  reset, 
  start);
  
  input clk;
  input reset;
  input start;
  
  input  [`DATAWIDTH*`NUM-1:0] inp;
  input  [`DATAWIDTH*`NUM-1:0] sub0_inp;
  input  [`DATAWIDTH*`NUM-1:0] sub1_inp;

  output [`DATAWIDTH-1:0] outp0;
  output [`DATAWIDTH-1:0] outp1;
  output [`DATAWIDTH-1:0] outp2;
  output [`DATAWIDTH-1:0] outp3;
  
  reg [2:0] status_counter;
  
  ///-------status counter--------///////
  always @ (posedge clk)
  begin
    if(reset) begin
	  status_counter <= 0;
	end else if(!start && status_counter == 3'b000) begin
	  status_counter <= 0;
	end else begin
	  status_counter <= status_counter + 1;
    end
  end
   
  ////------mode1 max block---------///////
  wire [`DATAWIDTH-1:0] max_outp_temp;
  reg  [`DATAWIDTH-1:0] max_outp;
 
  mode1_max max0(.inp0(inp[`DATAWIDTH-1:0]),
                 .inp1(inp[`DATAWIDTH*2-1:`DATAWIDTH]),
                 .inp2(inp[`DATAWIDTH*3-1:`DATAWIDTH*2]),
                 .inp3(inp[`DATAWIDTH*4-1:`DATAWIDTH*3]),
                 .ex_inp(`DATAWIDTH'd0),
                 .outp(max_outp_temp)); 
  
  always @(posedge clk)
  begin
    if(reset)begin
	   max_outp <= 0;
	end else if(status_counter == 3'b001)begin
	   max_outp <= max_outp_temp;
	end
  end
  
  ////------mode2 subtraction---------///////
  wire [`DATAWIDTH-1:0] outp_sub0_temp;
  wire [`DATAWIDTH-1:0] outp_sub1_temp;
  wire [`DATAWIDTH-1:0] outp_sub2_temp;
  wire [`DATAWIDTH-1:0] outp_sub3_temp;
    
  mode2_sub sub0(.a_inp0(sub0_inp[`DATAWIDTH-1:0]),
                 .a_inp1(sub0_inp[`DATAWIDTH*2-1:`DATAWIDTH]),
                 .a_inp2(sub0_inp[`DATAWIDTH*3-1:`DATAWIDTH*2]),
                 .a_inp3(sub0_inp[`DATAWIDTH*4-1:`DATAWIDTH*3]),
                 .b_inp(max_outp),
                 .outp0(outp_sub0_temp),
                 .outp1(outp_sub1_temp),
                 .outp2(outp_sub2_temp),
                 .outp3(outp_sub3_temp));
 
  reg [`DATAWIDTH-1:0] outp_sub0;
  reg [`DATAWIDTH-1:0] outp_sub1;
  reg [`DATAWIDTH-1:0] outp_sub2;
  reg [`DATAWIDTH-1:0] outp_sub3;
  
  always @(posedge clk)
  begin
    if(reset)begin
	  outp_sub0 <= 0;
	  outp_sub1 <= 0;
	  outp_sub2 <= 0;
	  outp_sub3 <= 0;
	end else if(status_counter == 3'b010) begin
	  outp_sub0 <= outp_sub0_temp;
	  outp_sub1 <= outp_sub1_temp;
	  outp_sub2 <= outp_sub2_temp;
	  outp_sub3 <= outp_sub3_temp;
	end
  end
  
  ////------mode3 exponential---------///////
  wire [`DATAWIDTH-1:0] outp_exp0_temp;
  wire [`DATAWIDTH-1:0] outp_exp1_temp;
  wire [`DATAWIDTH-1:0] outp_exp2_temp;
  wire [`DATAWIDTH-1:0] outp_exp3_temp;
  
  mode3_exp exp0(.inp0(outp_sub0),
                 .inp1(outp_sub1),
                 .inp2(outp_sub2),
                 .inp3(outp_sub3),
                 .outp0(outp_exp0_temp),
                 .outp1(outp_exp1_temp),
                 .outp2(outp_exp2_temp),
                 .outp3(outp_exp3_temp));
  
  reg [`DATAWIDTH-1:0] outp_exp0;
  reg [`DATAWIDTH-1:0] outp_exp1;
  reg [`DATAWIDTH-1:0] outp_exp2;
  reg [`DATAWIDTH-1:0] outp_exp3;
  
  always @(posedge clk)
  begin
    if(reset) begin
	  outp_exp0 <= 0;
	  outp_exp1 <= 0;
	  outp_exp2 <= 0;
	  outp_exp3 <= 0;
	end else if(status_counter == 3'b011)begin
	  outp_exp0 <= outp_exp0_temp;
	  outp_exp1 <= outp_exp1_temp;
	  outp_exp2 <= outp_exp2_temp;
	  outp_exp3 <= outp_exp3_temp;
	end
  end
  
  //////------mode4 adder tree---------///////
  wire [`DATAWIDTH-1:0] outp_add_temp;
  reg  [`DATAWIDTH-1:0] outp_add;
  mode4_adderTree adder_tree0(.inp0(outp_exp0), 
                              .inp1(outp_exp1),
                              .inp2(outp_exp2),
                              .inp3(outp_exp3),
                              .outp(outp_add_temp),
                              .ex_inp(`DATAWIDTH'd0));
  
  always @(posedge clk)
  begin
    if(reset) begin
	  outp_add <= 0;
	end else if(status_counter == 3'b100) begin
	  outp_add <= outp_add_temp;
	end
  end
  
  //////------mode5 log---------///////
  wire [`DATAWIDTH-1:0] outp_log_temp;
  reg  [`DATAWIDTH-1:0] outp_log;
  mode5_ln ln0(.inp(outp_add), .outp(outp_log_temp));
  
  always @(posedge clk)
  begin
	if(reset) begin
	  outp_log <= 0;
	end else if(status_counter == 3'b101) begin
	  outp_log <= outp_log_temp;
    end
  end
  
  //////------mode6 pre-sub---------///////
  wire [`DATAWIDTH-1:0] outp_sub0_temp1;
  wire [`DATAWIDTH-1:0] outp_sub1_temp1;
  wire [`DATAWIDTH-1:0] outp_sub2_temp1;
  wire [`DATAWIDTH-1:0] outp_sub3_temp1;  

  reg  [`DATAWIDTH-1:0] outp_presub0;
  reg  [`DATAWIDTH-1:0] outp_presub1;
  reg  [`DATAWIDTH-1:0] outp_presub2;
  reg  [`DATAWIDTH-1:0] outp_presub3;
 
  mode6_sub pre_sub(.a_inp0(sub1_inp[`DATAWIDTH-1:0]),
                 .a_inp1(sub1_inp[`DATAWIDTH*2-1:`DATAWIDTH]),
                 .a_inp2(sub1_inp[`DATAWIDTH*3-1:`DATAWIDTH*2]),
                 .a_inp3(sub1_inp[`DATAWIDTH*4-1:`DATAWIDTH*3]),
                 .b_inp(max_outp),
                 .outp0(outp_sub0_temp1),
                 .outp1(outp_sub1_temp1),
                 .outp2(outp_sub2_temp1),
                 .outp3(outp_sub3_temp1));

  always @(posedge clk)
  begin
    if(reset) begin
      outp_presub0 <= 0;
      outp_presub1 <= 0;
      outp_presub2 <= 0;
      outp_presub3 <= 0;
    end else if(status_counter == 3'b101) begin
      outp_presub0 <= outp_sub0_temp1;
      outp_presub1 <= outp_sub1_temp1;
      outp_presub2 <= outp_sub2_temp1;
      outp_presub3 <= outp_sub3_temp1;
    end
  end


  //////------mode6 sub log---------/////// 
  wire [`DATAWIDTH-1:0] outp_logsub0_temp;
  wire [`DATAWIDTH-1:0] outp_logsub1_temp;
  wire [`DATAWIDTH-1:0] outp_logsub2_temp;
  wire [`DATAWIDTH-1:0] outp_logsub3_temp;

  reg [`DATAWIDTH-1:0] outp_logsub0;
  reg [`DATAWIDTH-1:0] outp_logsub1;
  reg [`DATAWIDTH-1:0] outp_logsub2;
  reg [`DATAWIDTH-1:0] outp_logsub3;

  
  mode6_sub sub2(.a_inp0(outp_presub0),
                 .a_inp1(outp_presub1),
                 .a_inp2(outp_presub2),
                 .a_inp3(outp_presub3),
                 .b_inp(outp_log),
                 .outp0(outp_logsub0_temp),
                 .outp1(outp_logsub1_temp),
                 .outp2(outp_logsub2_temp),
                 .outp3(outp_logsub3_temp));

  always @(posedge clk)
  begin
    if(reset) begin
      outp_logsub0 <= 0;
      outp_logsub1 <= 0;
      outp_logsub2 <= 0;
      outp_logsub3 <= 0;
    end else if(status_counter == 3'b110) begin
      outp_logsub0 <= outp_logsub0_temp;
      outp_logsub1 <= outp_logsub1_temp;
      outp_logsub2 <= outp_logsub2_temp;
      outp_logsub3 <= outp_logsub3_temp;
    end
  end

  //////------mode7 exp---------///////
  /*wire [`DATAWIDTH-1:0] outp_temp0;
  wire [`DATAWIDTH-1:0] outp_temp1;
  wire [`DATAWIDTH-1:0] outp_temp2;
  wire [`DATAWIDTH-1:0] outp_Temp3;*/    
  mode7_exp exp1(.inp0(outp_logsub0),
                 .inp1(outp_logsub1),
                 .inp2(outp_logsub2),
                 .inp3(outp_logsub3),
                 .outp0(outp0),
                 .outp1(outp1),
                 .outp2(outp2),
                 .outp3(outp3));
  

endmodule


