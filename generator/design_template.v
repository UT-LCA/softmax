`timescale 1ns / 1ps

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

  <outp_ports>
  
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

  <outp_declaration>
  output done;

  reg [`DATAWIDTH*`NUM-1:0] inp_reg;
  reg [`ADDRSIZE-1:0] addr;
  reg [`DATAWIDTH*`NUM-1:0] sub0_inp_reg;
  reg [`DATAWIDTH*`NUM-1:0] sub1_inp_reg;
  reg [`ADDRSIZE-1:0] sub0_inp_addr;
  reg [`ADDRSIZE-1:0] sub1_inp_addr;

  ////-----------control signals--------------////
  reg mode1_start;
  reg mode1_run;
  reg mode2_start;
  reg mode2_run;
  reg mode3_run;

  <mode1_stage_run_regs>

  <mode4_stage_run_regs>

  reg mode5_run;
  reg mode6_run;
  reg mode7_run;
  reg presub_start;
  reg presub_run;
  reg done;

  always @(posedge clk)begin
    <mode4_stage_run_regs_assign>
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
      mode1_run <= 0;

      <mode1_run_reset>

      mode2_start <= 0;
      mode2_run <= 0;
      mode3_run <= 0;
      <mode4_run_reset>
      mode5_run <= 0;
      mode6_run <= 0;
      mode7_run <= 0;
      presub_start <= 0;
      presub_run <= 0;
      done <= 0;
    end
    
    //init latch the input address
    if(init) begin
      addr <= start_addr;
    end

    //start the mode1 max calculation
    if(start)begin
      mode1_start <= 1;
    end    

    //logic when to finish mode1 and trigger mode2 to latch the mode2 address
    <mode1_finish_mode2_trigger>
   
    <mode1_stagex_run>

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
    <mode4_stagex_run>
   
    //mode5 should be triggered right at the falling edge of mode4_stage1_run 
    if(mode4_stage1_run_a & ~mode4_stage1_run) begin
      mode5_run <= 1;
    end else if(mode4_stage1_run == 0) begin
      mode5_run <= 0;
    end

    <presub_trigger>
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

  mode1_max_tree mode1_max(
      <mode1_max>
      .clk(clk),
      .reset(reset),
      .outp(max_outp)); 

  ////------mode2 subtraction---------///////
  <mode2_sub>

  ////------mode3 exponential---------///////
  <mode3_exp>

  //////------mode4 pipelined adder tree---------///////
  wire [`DATAWIDTH-1:0] mode4_adder_tree_outp;
  mode4_adder_tree mode4_adder_tree(
    <mode4_adder_tree>

    .clk(clk),
    .reset(reset),
    .outp(mode4_adder_tree_outp)
  );


  //////------mode5 log---------///////
  wire [`DATAWIDTH-1:0] mode5_outp_log;
  reg  [`DATAWIDTH-1:0] mode5_outp_log_reg;
  mode5_ln mode5_ln(.inp(mode4_adder_tree_outp), .outp(mode5_outp_log));
  
  always @(posedge clk) begin
    if(reset) begin
      mode5_outp_log_reg <= 0;
    end else if(mode5_run) begin
      mode5_outp_log_reg <= mode5_outp_log;
    end
  end

  //////------mode6 pre-sub---------///////
  <mode6_presub>

  //////------mode6 logsub ---------/////// 
  <mode6_logsub>

  //////------mode7 exp---------///////
  <mode7_exp>

endmodule

