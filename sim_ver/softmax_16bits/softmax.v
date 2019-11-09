`timescale 1ns / 1ps
`include "defines.v"

//fixed adder adds unsigned fixed numbers. Overflow flag is high in case of overflow
module softmax(
  inp, //data in from memory to max block
  sub0_inp, //data inputs from memory to first-stage subtractors
  sub1_inp, //data inputs from memory to second-stage subtractors
  addr_limit, //max address containing required data: needed to modify later

  addr, //address corresponding to data inp
  sub0_inp_addr, //address corresponding to sub0_inp
  sub1_inp_addr, //address corresponding to sub1_inp
  outp0,  
  outp1,
  outp2,
  outp3,

  clk, 
  reset, 
  done,
  start); //start signal for softmax units
  //done signal is also needed
  
  input clk;
  input reset;
  input start;
  
  input  [`DATAWIDTH*`NUM-1:0] inp;
  input  [`DATAWIDTH*`NUM-1:0] sub0_inp;
  input  [`DATAWIDTH*`NUM-1:0] sub1_inp;
  input  [`ADDRSIZE-1:0]       addr_limit;  

  output [`ADDRSIZE-1 :0] addr;
  output [`ADDRSIZE-1 :0] sub0_inp_addr;
  output [`ADDRSIZE-1 :0] sub1_inp_addr;
  output [`DATAWIDTH-1:0] outp0;
  output [`DATAWIDTH-1:0] outp1;
  output [`DATAWIDTH-1:0] outp2;
  output [`DATAWIDTH-1:0] outp3;
  output done;
  ////-----control logic for the modes-----//////
  reg [`DATAWIDTH*`NUM-1:0] inp_reg;
  reg [`ADDRSIZE-1:0] addr;
  reg [`DATAWIDTH*`NUM-1:0] sub0_inp_reg;
  reg [`DATAWIDTH*`NUM-1:0] sub1_inp_reg;
  reg [`ADDRSIZE-1:0] sub0_inp_addr;
  reg [`ADDRSIZE-1:0] sub1_inp_addr;
  reg mode1_t;
  reg mode1_run;
  reg mode2_t;
  reg mode2_run;
  reg mode3_run;
  reg mode4_run;
  reg mode5_run;
  reg presub_run;
  reg presub_t;
  reg mode6_run;
  reg mode7_run;
  reg done;

  always @(posedge clk)
  begin
    if(reset) begin
      inp_reg <= 0;
      addr <= 0;
      mode1_t <= 0;
      mode1_run <= 0;
      sub0_inp_addr <= 0;
      sub1_inp_addr <= 0;
      sub0_inp_reg <= 0;
      sub1_inp_reg <= 0;
      mode2_t <= 0;
      mode2_run <= 0;  
      mode3_run <= 0;
      mode4_run <= 0;
      mode5_run <= 0;
      mode6_run <= 0;
      mode7_run <= 0;
      presub_run <= 0;
      presub_t  <= 0;
      done <= 0;
    end

    if(!reset && mode1_t && addr < addr_limit) begin
      addr <= addr + 1;
      inp_reg <= inp;
      mode1_run <= 1;
    end else begin
      mode1_t <= 0;
      mode1_run <= 0;
    end
    

    if(!reset && mode2_t && sub0_inp_addr < addr_limit)begin
      sub0_inp_addr <= sub0_inp_addr + 1;
      sub0_inp_reg <= sub0_inp;
      mode2_run <= 1;        
    end else begin
      mode2_run <= 0;
      mode2_t <= 0;
    end

    if(!reset && presub_t && sub1_inp_addr < addr_limit)begin
      sub1_inp_addr <= sub1_inp_addr + 1;
      sub1_inp_reg <= sub1_inp;
      presub_run <= 1;
    end else begin
      presub_t <= 0;
      presub_run <= 0;
    end
    
    if(mode2_run == 1)begin
      mode3_run <= 1;
    end else begin
      mode3_run <= 0;
    end
    
    ////----trigger mdoe 4 adderTree----////
    if(mode3_run == 1)begin
      mode4_run <= 1;
    end else begin
      mode4_run <= 0;
    end

    if(mode4_run == 0)begin
      mode5_run <= 0;
    end

    if(presub_run == 1)begin
      mode6_run <= 1;
    end else begin
      mode6_run <= 0;
    end

    if(mode6_run == 1)begin
      mode7_run <= 1;
    end else begin
      mode7_run <= 0;
    end
   
    if(mode7_run == 1)begin
      done <= 1;
    end else begin
      done <= 0;
    end
  end
  ////----trigger the max logic------//////
  always @(posedge start)
  begin
    if(reset == 0) begin
      mode1_t = 1;
    end
  end

  ////----trigger the latch address of presub----////
  always @(negedge mode3_run)
  begin 
    if(reset == 0) begin
      presub_t = 1;
    end
  end
   
  ////----trigger mode5 log----////
  always @(negedge mode4_run)
  begin
    if(reset == 0)begin
      mode5_run = 1;
    end
  end
  
  always @(negedge mode1_run)
  begin
    if(reset == 0)begin
      mode2_t = 1;
    end
  end

  ////------mode1 max block---------///////
  wire [`DATAWIDTH-1:0] max_outp_temp;
  reg  [`DATAWIDTH-1:0] max_outp;
 
  mode1_max mode1_max(.inp0(inp_reg[`DATAWIDTH-1:0]),
                      .inp1(inp_reg[`DATAWIDTH*2-1:`DATAWIDTH]),
                      .inp2(inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
                      .inp3(inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
                      .ex_inp(max_outp),
                      .outp(max_outp_temp)); 
  
  always @(posedge clk)
  begin
    if(reset)begin
      max_outp <= 0;
    end else if(mode1_run == 1)begin
      max_outp <= max_outp_temp;
    end
  end

  
  ////------mode2 subtraction---------///////
  wire [`DATAWIDTH-1:0] outp_sub0_temp;
  wire [`DATAWIDTH-1:0] outp_sub1_temp;
  wire [`DATAWIDTH-1:0] outp_sub2_temp;
  wire [`DATAWIDTH-1:0] outp_sub3_temp;

  mode2_sub mode2_sub(.a_inp0(sub0_inp_reg[`DATAWIDTH-1:0]),
                      .a_inp1(sub0_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH]),
                      .a_inp2(sub0_inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
                      .a_inp3(sub0_inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
                      .b_inp(max_outp),
                      .outp0(outp_sub0_temp),
                      .outp1(outp_sub1_temp),
                      .outp2(outp_sub2_temp),
                      .outp3(outp_sub3_temp));
 
  reg [`DATAWIDTH-1:0] mode2_outp_sub0;
  reg [`DATAWIDTH-1:0] mode2_outp_sub1;
  reg [`DATAWIDTH-1:0] mode2_outp_sub2;
  reg [`DATAWIDTH-1:0] mode2_outp_sub3;
  
  always @(posedge clk)
  begin
    if(reset)begin
      mode2_outp_sub0 <= 0;
      mode2_outp_sub1 <= 0;
      mode2_outp_sub2 <= 0;
      mode2_outp_sub3 <= 0;
    end else if(mode2_run) begin
      mode2_outp_sub0 <= outp_sub0_temp;
      mode2_outp_sub1 <= outp_sub1_temp;
      mode2_outp_sub2 <= outp_sub2_temp;
      mode2_outp_sub3 <= outp_sub3_temp;
    end
  end
  
  ////------mode3 exponential---------///////
  wire [`DATAWIDTH-1:0] outp_exp0_temp;
  wire [`DATAWIDTH-1:0] outp_exp1_temp;
  wire [`DATAWIDTH-1:0] outp_exp2_temp;
  wire [`DATAWIDTH-1:0] outp_exp3_temp;
  
  mode3_exp mode3_exp(.inp0(mode2_outp_sub0),
                      .inp1(mode2_outp_sub1),
                      .inp2(mode2_outp_sub2),
                      .inp3(mode2_outp_sub3),
                      .outp0(outp_exp0_temp),
                      .outp1(outp_exp1_temp),
                      .outp2(outp_exp2_temp),
                      .outp3(outp_exp3_temp));
  
  reg [`DATAWIDTH-1:0] mode3_outp_exp0;
  reg [`DATAWIDTH-1:0] mode3_outp_exp1;
  reg [`DATAWIDTH-1:0] mode3_outp_exp2;
  reg [`DATAWIDTH-1:0] mode3_outp_exp3;
  
  always @(posedge clk)
  begin
    if(reset) begin
	  mode3_outp_exp0 <= 0;
	  mode3_outp_exp1 <= 0;
	  mode3_outp_exp2 <= 0;
	  mode3_outp_exp3 <= 0;
	end else if(mode3_run)begin
	  mode3_outp_exp0 <= outp_exp0_temp;
	  mode3_outp_exp1 <= outp_exp1_temp;
	  mode3_outp_exp2 <= outp_exp2_temp;
	  mode3_outp_exp3 <= outp_exp3_temp;
	end
  end
  
  //////------mode4 adder tree---------///////
  wire [`DATAWIDTH-1:0] outp_add_temp;
  reg  [`DATAWIDTH-1:0] mode4_outp_add;
  mode4_adderTree mode4_adderTree(.inp0(mode3_outp_exp0), 
                                  .inp1(mode3_outp_exp1),
                                  .inp2(mode3_outp_exp2),
                                  .inp3(mode3_outp_exp3),
                                  .outp(outp_add_temp),
                                  .ex_inp(mode4_outp_add));
  
  always @(posedge clk)
  begin
    if(reset) begin
	  mode4_outp_add <= 0;
	end else if(mode4_run) begin
	  mode4_outp_add <= outp_add_temp;
	end
  end
  
  //////------mode5 log---------///////
  wire [`DATAWIDTH-1:0] outp_log_temp;
  reg  [`DATAWIDTH-1:0] mode5_outp_log;
  mode5_ln mode5_ln(.inp(mode4_outp_add), .outp(outp_log_temp));
  
  always @(posedge clk)
  begin
	if(reset) begin
	  mode5_outp_log <= 0;
	end else if(mode5_run) begin
	  mode5_outp_log <= outp_log_temp;
    end
  end
  
  //////------mode6 pre-sub---------///////
  wire [`DATAWIDTH-1:0] outp_sub0_temp1;
  wire [`DATAWIDTH-1:0] outp_sub1_temp1;
  wire [`DATAWIDTH-1:0] outp_sub2_temp1;
  wire [`DATAWIDTH-1:0] outp_sub3_temp1;  

  reg  [`DATAWIDTH-1:0] mode6_outp_presub0;
  reg  [`DATAWIDTH-1:0] mode6_outp_presub1;
  reg  [`DATAWIDTH-1:0] mode6_outp_presub2;
  reg  [`DATAWIDTH-1:0] mode6_outp_presub3;
 
  mode6_sub pre_sub(.a_inp0(sub1_inp_reg[`DATAWIDTH-1:0]),
                    .a_inp1(sub1_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH]),
                    .a_inp2(sub1_inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
                    .a_inp3(sub1_inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
                    .b_inp(max_outp),
                    .outp0(outp_sub0_temp1),
                    .outp1(outp_sub1_temp1),
                    .outp2(outp_sub2_temp1),
                    .outp3(outp_sub3_temp1));

  always @(posedge clk)
  begin
    if(reset) begin
      mode6_outp_presub0 <= 0;
      mode6_outp_presub1 <= 0;
      mode6_outp_presub2 <= 0;
      mode6_outp_presub3 <= 0;
    end else if(presub_run) begin
      mode6_outp_presub0 <= outp_sub0_temp1;
      mode6_outp_presub1 <= outp_sub1_temp1;
      mode6_outp_presub2 <= outp_sub2_temp1;
      mode6_outp_presub3 <= outp_sub3_temp1;
    end
  end


  //////------mode6 sub log---------/////// 
  wire [`DATAWIDTH-1:0] outp_logsub0_temp;
  wire [`DATAWIDTH-1:0] outp_logsub1_temp;
  wire [`DATAWIDTH-1:0] outp_logsub2_temp;
  wire [`DATAWIDTH-1:0] outp_logsub3_temp;

  reg [`DATAWIDTH-1:0] mode6_outp_logsub0;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub1;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub2;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub3;

  
  mode6_sub mode6_sub(.a_inp0(mode6_outp_presub0),
                      .a_inp1(mode6_outp_presub1),
                      .a_inp2(mode6_outp_presub2),
                      .a_inp3(mode6_outp_presub3),
                      .b_inp(mode5_outp_log),
                      .outp0(outp_logsub0_temp),
                      .outp1(outp_logsub1_temp),
                      .outp2(outp_logsub2_temp),
                      .outp3(outp_logsub3_temp));

  always @(posedge clk)
  begin
    if(reset) begin
      mode6_outp_logsub0 <= 0;
      mode6_outp_logsub1 <= 0;
      mode6_outp_logsub2 <= 0;
      mode6_outp_logsub3 <= 0;
    end else if(mode6_run) begin
      mode6_outp_logsub0 <= outp_logsub0_temp;
      mode6_outp_logsub1 <= outp_logsub1_temp;
      mode6_outp_logsub2 <= outp_logsub2_temp;
      mode6_outp_logsub3 <= outp_logsub3_temp;
    end
  end

  //////------mode7 exp---------///////
  /*wire [`DATAWIDTH-1:0] outp_temp0;
  wire [`DATAWIDTH-1:0] outp_temp1;
  wire [`DATAWIDTH-1:0] outp_temp2;
  wire [`DATAWIDTH-1:0] outp_Temp3;*/    
  wire [`DATAWIDTH-1:0] outp0_temp;
  wire [`DATAWIDTH-1:0] outp1_temp;
  wire [`DATAWIDTH-1:0] outp2_temp;
  wire [`DATAWIDTH-1:0] outp3_temp;

  reg [`DATAWIDTH-1:0] outp0;
  reg [`DATAWIDTH-1:0] outp1;
  reg [`DATAWIDTH-1:0] outp2;
  reg [`DATAWIDTH-1:0] outp3;

  mode7_exp mode7_exp(.inp0(mode6_outp_logsub0),
                      .inp1(mode6_outp_logsub1),
                      .inp2(mode6_outp_logsub2),
                      .inp3(mode6_outp_logsub3),
                      .outp0(outp0_temp),
                      .outp1(outp1_temp),
                      .outp2(outp2_temp),
                      .outp3(outp3_temp));

  always @(posedge clk)
  begin
    if(reset) begin
      outp0 <= 0;
      outp1 <= 0;
      outp2 <= 0;
      outp3 <= 0;
    end else if (mode7_run) begin
      outp0 <= outp0_temp;
      outp1 <= outp1_temp;
      outp2 <= outp2_temp;
      outp3 <= outp3_temp;
    end
  end
endmodule


