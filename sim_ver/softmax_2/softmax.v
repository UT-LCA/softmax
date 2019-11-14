`timescale 1ns / 1ps
`include "defines.v"

//fixed adder adds unsigned fixed numbers. Overflow flag is high in case of overflow
module softmax(
  inp,      //data in from memory to max block
  sub0_inp, //data inputs from memory to first-stage subtractors
  sub1_inp, //data inputs from memory to second-stage subtractors

  start_addr,   //the first address that contains input data in the on-chip memory
  end_addr,     //max address containing required data

  addr,          //address corresponding to data inp
  sub0_inp_addr, //address corresponding to sub0_inp
  sub1_inp_addr, //address corresponding to sub1_inp
  outp0,  
  outp1,
  mode1_done,

  clk, 
  reset, 
  init,   //the signal indicating to latch the new start address
  done,   //done signal asserts when the softmax calculation is over
  start); //start signal for the overall softmax operation
  
  input clk;
  input reset;
  input start;
  input init;
  
  input  [`DATAWIDTH*`NUM-1:0] inp;
  input  [`DATAWIDTH*`NUM-1:0] sub0_inp;
  input  [`DATAWIDTH*`NUM-1:0] sub1_inp;
  input  [`ADDRSIZE-1:0]       end_addr;  
  input  [`ADDRSIZE-1:0]       start_addr;  

  output [`ADDRSIZE-1 :0] addr;
  output [`ADDRSIZE-1 :0] sub0_inp_addr;
  output [`ADDRSIZE-1 :0] sub1_inp_addr;
  output [`DATAWIDTH-1:0] outp0;
  output [`DATAWIDTH-1:0] outp1;

  output mode1_done;
  output done;

  ////-----latches to latch the input and addr-----//////
  reg [`DATAWIDTH*`NUM-1:0] inp_reg;
  reg [`ADDRSIZE-1:0] addr;
  reg [`DATAWIDTH*`NUM-1:0] sub0_inp_reg;
  reg [`DATAWIDTH*`NUM-1:0] sub1_inp_reg;
  reg [`ADDRSIZE-1:0] sub0_inp_addr;
  reg [`ADDRSIZE-1:0] sub1_inp_addr;

  ////---------control signals--------------------/////
  reg mode1_start;
  reg mode1_run;
  reg mode1_done;
  reg mode2_start;
  reg mode2_run;
  reg mode3_run;

  reg mode4_stage2_run;
  reg mode4_stage1_run;
  reg mode4_stage0_run;
  reg mode4_stage1_run_a;
  reg mode3_run_a;

  reg mode5_run;
  reg mode6_run;
  reg mode7_run;
  reg presub_start;
  reg presub_run;
  reg done;

  always @(posedge clk)begin
    mode4_stage1_run_a <= mode4_stage1_run;
    mode3_run_a <= mode3_run;
  end

  always @(posedge clk)
  begin
    if(reset) begin
      inp_reg <= 0;
      addr <= 0;
      sub0_inp_addr <= 0;
      sub1_inp_addr <= 0;
      sub0_inp_reg <= 0;
      sub1_inp_reg <= 0;
      mode1_start <= 0;
      mode2_start <= 0;
      presub_start <= 0;
      mode1_run <= 0;
      mode2_run <= 0;
      mode3_run <= 0;
      mode4_stage2_run <= 0;
      mode4_stage1_run <= 0;
      mode4_stage0_run <= 0;
      mode5_run <= 0;
      mode6_run <= 0;
      mode7_run <= 0;
      presub_run <= 0;
      mode1_done <= 0;
      done <= 0;
    end
    
    //init latch the input address
    if(init) begin
      addr <= start_addr;
      mode1_done <= 0;
    end

    //start the mode1 max calculation
    if(start)begin
      mode1_start <= 1;
    end    

//////////--------------control logic in between is different for larger parallelism--------------///////////

    //logic when to finish mode1 and trigger mode2 to latch the mode2 address
    if(~reset && mode1_start && addr < end_addr) begin
      addr <= addr + 1;
      inp_reg <= inp;
      mode1_run <= 1;
      if(addr == end_addr - 1) begin
        mode2_start <= 1;
        sub0_inp_addr <= start_addr;
      end
    end else if(addr == end_addr)begin
      addr <= 0;
      mode1_done <= 1;
      mode1_run <= 0;
      mode1_start <= 0;
    end else begin
      mode1_run <= 0;
    end
   
//////////--------------control logic in between is different for larger parallelism--------------///////////

    //logic when to finish mode2
    if(~reset && mode2_start && sub0_inp_addr < end_addr)begin
      sub0_inp_addr <= sub0_inp_addr + 1;
      sub0_inp_reg <= sub0_inp;
      mode2_run <= 1;
    end else if(sub0_inp_addr == end_addr)begin
      sub0_inp_addr <= 0;
      sub0_inp_reg <= 0;
      mode2_run <= 0;
      mode2_start <= 0;
    end
    
    //logic when to trigger mode3
    if(mode2_run == 1)begin
      mode3_run <= 1;
    end else begin
      mode3_run <= 0;
    end
    
    //logic when to trigger mode4 last stage adderTree, since the final results of adderTree
    //is always ready 1 cycle after mode3 finishes, so there is no need on extra
    //logic to control the adderTree outputs
    if(mode3_run == 1)begin
      mode4_stage1_run <= 1;
    end else begin
      mode4_stage1_run <= 0;
    end
 
    if(mode4_stage1_run == 1) begin
      mode4_stage0_run <= 1;
    end else begin
      mode4_stage0_run <=0;
    end

    //mode5 should be triggered right at the falling edge of mode4_stage0_run 
    if(mode4_stage1_run_a & ~mode4_stage1_run) begin
      mode5_run <= 1;
    end else if(mode4_stage0_run == 0) begin
      mode5_run <= 0;
    end

    if(mode3_run_a & ~mode3_run)begin
      presub_start <= 1;
      sub1_inp_addr <= start_addr;
      sub1_inp_reg <= sub1_inp;
    end

    if(~reset && presub_start && sub1_inp_addr < end_addr)begin
      sub1_inp_addr <= sub1_inp_addr + 1;
      sub1_inp_reg <= sub1_inp;
      presub_run <= 1;
    end else if(sub1_inp_addr == end_addr) begin
      presub_run <= 0;
      presub_start <= 0;
      sub1_inp_addr <= 0;
      sub1_inp_reg <= 0;
    end

    if(presub_run) begin
      mode6_run <= 1;
    end else begin
      mode6_run <= 0;
    end

    if(mode6_run) begin
      mode7_run <= 1;
    end else begin
      mode7_run <= 0;
    end
    
    if(mode7_run) begin
      done <= 1;
    end else begin
      done <= 0;
    end
    
  end
  
  

  ////------mode1 max block---------///////
  wire [`DATAWIDTH-1:0] max_outp;
 
  mode1_max mode1_max(.inp0(inp_reg[`DATAWIDTH-1:0]),
                      .inp1(inp_reg[`DATAWIDTH*2-1:`DATAWIDTH]),
                      .mode1_run(mode1_run),
                      .outp(max_outp),
                      .clk(clk),
                      .reset(reset)); 
  
  ////------mode2 subtraction---------///////
  wire [`DATAWIDTH-1:0] mode2_outp_sub0;
  wire [`DATAWIDTH-1:0] mode2_outp_sub1;

  mode2_sub mode2_sub(.a_inp0(sub0_inp_reg[`DATAWIDTH-1:0]),
                      .a_inp1(sub0_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH]),
                      .b_inp(max_outp),
                      .outp0(mode2_outp_sub0),
                      .outp1(mode2_outp_sub1));
 
  reg [`DATAWIDTH-1:0] mode2_outp_sub0_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub1_reg;
  
  always @(posedge clk)
  begin
    if(reset)begin
      mode2_outp_sub0_reg <= 0;
      mode2_outp_sub1_reg <= 0;
    end else if(mode2_run) begin
      mode2_outp_sub0_reg <= mode2_outp_sub0;
      mode2_outp_sub1_reg <= mode2_outp_sub1;
    end
  end
  
  ////------mode3 exponential---------///////
  wire [`DATAWIDTH-1:0] mode3_outp_exp0;
  wire [`DATAWIDTH-1:0] mode3_outp_exp1;
  
  mode3_exp mode3_exp(.inp0(mode2_outp_sub0_reg),
                      .inp1(mode2_outp_sub1_reg),
                      .outp0(mode3_outp_exp0),
                      .outp1(mode3_outp_exp1));
  
  reg [`DATAWIDTH-1:0] mode3_outp_exp0_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp1_reg;
  
  always @(posedge clk) begin
    if(reset) begin
	  mode3_outp_exp0_reg <= 0;
	  mode3_outp_exp1_reg <= 0;
	end else if(mode3_run)begin
	  mode3_outp_exp0_reg <= mode3_outp_exp0;
	  mode3_outp_exp1_reg <= mode3_outp_exp1;
	end
  end
  
  //////------mode4 pipelined adder tree---------///////
  wire  [`DATAWIDTH-1 : 0] mode4_outp;
  mode4_adderTree adderTree(.inp0(mode3_outp_exp0_reg),
  			    .inp1(mode3_outp_exp1_reg),
                           
			    .mode4_stage1_run(mode4_stage1_run),
			    .mode4_stage0_run(mode4_stage0_run),

			    .clk(clk),
			    .reset(reset),
			    .outp(mode4_outp));
  
  //////------mode5 log---------///////
  wire [`DATAWIDTH-1:0] mode5_outp_log;
  reg  [`DATAWIDTH-1:0] mode5_outp_log_reg;
  mode5_ln mode5_ln(.inp(mode4_outp), .outp(mode5_outp_log));
  
  always @(posedge clk)
  begin
	if(reset) begin
	  mode5_outp_log_reg <= 0;
	end else if(mode5_run) begin
	  mode5_outp_log_reg <= mode5_outp_log;
    end
  end
  
  //////------mode6 pre-sub---------///////
  wire [`DATAWIDTH-1:0] mode6_outp_presub0;
  wire [`DATAWIDTH-1:0] mode6_outp_presub1;

  reg  [`DATAWIDTH-1:0] mode6_outp_presub0_reg;
  reg  [`DATAWIDTH-1:0] mode6_outp_presub1_reg;
 
  mode6_sub pre_sub(.a_inp0(sub1_inp_reg[`DATAWIDTH-1:0]),
                    .a_inp1(sub1_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH]),
                    .b_inp(max_outp),
                    .outp0(mode6_outp_presub0),
                    .outp1(mode6_outp_presub1));

  always @(posedge clk)
  begin
    if(reset) begin
      mode6_outp_presub0_reg <= 0;
      mode6_outp_presub1_reg <= 0;
    end else if(presub_run) begin
      mode6_outp_presub0_reg <= mode6_outp_presub0;
      mode6_outp_presub1_reg <= mode6_outp_presub1;
    end
  end


  //////------mode6 sub log---------/////// 
  wire [`DATAWIDTH-1:0] mode6_outp_logsub0;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub1;

  reg [`DATAWIDTH-1:0] mode6_outp_logsub0_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub1_reg;

  mode6_sub mode6_sub(.a_inp0(mode6_outp_presub0_reg),
                      .a_inp1(mode6_outp_presub1_reg),
                      .b_inp(mode5_outp_log_reg),
                      .outp0(mode6_outp_logsub0),
                      .outp1(mode6_outp_logsub1));

  always @(posedge clk)
  begin
    if(reset) begin
      mode6_outp_logsub0_reg <= 0;
      mode6_outp_logsub1_reg <= 0;
    end else if(mode6_run) begin
      mode6_outp_logsub0_reg <= mode6_outp_logsub0;
      mode6_outp_logsub1_reg <= mode6_outp_logsub1;
    end
  end

  //////------mode7 exp---------///////
  wire [`DATAWIDTH-1:0] outp0_temp;
  wire [`DATAWIDTH-1:0] outp1_temp;

  reg [`DATAWIDTH-1:0] outp0;
  reg [`DATAWIDTH-1:0] outp1;

  mode7_exp mode7_exp(.inp0(mode6_outp_logsub0_reg),
                      .inp1(mode6_outp_logsub1_reg),
                      .outp0(outp0_temp),
                      .outp1(outp1_temp));

  always @(posedge clk)
  begin
    if(reset) begin
      outp0 <= 0;
      outp1 <= 0;
    end else if (mode7_run) begin
      outp0 <= outp0_temp;
      outp1 <= outp1_temp;
    end
  end
endmodule


