
`ifndef DEFINES_DONE
`define DEFINES_DONE
`define DATAWIDTH 32
`define NUM 1
`define ADDRSIZE 10
`define ADDRSIZE_FOR_TB 11
`endif


//`include "DW01_cmp2.v"
//`include "DW01_add.v"
//`include "DW01_sub.v"
//`include "DW01_addsub.v"
//`include "DW01_ash.v"
//`include "DW_lzd.v"
//`include "DW02_mult.v"
//`include "exponentialunit_fixed.v"
//`include "logunit_fixed.v"

`timescale 1ns / 1ps

//fixed adder adds unsigned fixed numbers. Overflow flag is high in case of overflow
module softmax(
  inp,      //data in from memory to max block

  start_addr,   //the first address that contains input data in the on-chip memory
  end_addr,     //max address containing required data

  addr,          //address corresponding to data inp

  outp0,

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
  input  [`ADDRSIZE-1:0]       end_addr;
  input  [`ADDRSIZE-1:0]       start_addr;

  output [`ADDRSIZE-1 :0] addr;

  output [`DATAWIDTH-1:0] outp0;
  output done;

  reg [`DATAWIDTH*`NUM-1:0] inp_reg;
  reg [`ADDRSIZE-1:0] addr;
  reg [`DATAWIDTH*`NUM-1:0] sub0_inp_reg;
  reg [`DATAWIDTH*`NUM-1:0] sub1_inp_reg;
  reg [`ADDRSIZE-1:0] sub0_inp_addr;
  reg [`ADDRSIZE-1:0] sub1_inp_addr;

  ///-------internal buffers--------//
  reg [`DATAWIDTH*`NUM-1:0] buffer[(1<<`ADDRSIZE):0];
  wire  [`DATAWIDTH*`NUM-1:0] sub0_inp;
  wire  [`DATAWIDTH*`NUM-1:0] sub1_inp;
  ///-----read logic for internal buffers-----//
  assign sub0_inp = buffer[sub0_inp_addr]; 
  assign sub1_inp = buffer[sub1_inp_addr]; 

  ////-----------control signals--------------////
  reg mode1_start;
  reg mode1_run;
  reg mode2_start;
  reg mode2_run;

  reg mode3_stage_run;
  reg mode7_stage_run;

  reg mode3_run;
  reg mode3_run_a;
  reg mode3_stage_run_a;

  wire mode1_stage0_run;
  assign mode1_stage0_run = mode1_run;

  reg mode4_stage0_run;

  reg mode5_run;
  reg mode6_run;
  reg mode7_run;
  reg presub_start;
  reg presub_run;
  reg done;

  always @(posedge clk)begin
    mode3_run_a <= mode3_run;
    mode3_stage_run_a <= mode3_stage_run;
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

      mode3_stage_run <= 0;
      mode7_stage_run <= 0;
      mode2_start <= 0;
      mode2_run <= 0;
      mode3_run <= 0;
      mode4_stage0_run <= 0;
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
    if(~reset && mode1_start && addr < end_addr) begin
      addr <= addr + 1;
      inp_reg <= inp;
    //store inputs into buffer
    buffer[addr] <= inp;
      mode1_run <= 1;
      if(addr == end_addr - 1) begin
        mode2_start <= 1;
        sub0_inp_addr <= start_addr;
      end
    end else if(addr == end_addr)begin
      addr <= 0;
      mode1_run <= 0;
      mode1_start <= 0;
    end else begin
      mode1_run <= 0;
    end


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
    if(mode2_run == 1) begin
      mode3_stage_run <= 1;
    end else begin
      mode3_stage_run <= 0;
    end

    if(mode3_stage_run == 1) begin
      mode3_run <= 1;
    end else begin
      mode3_run <= 0;
    end

    //logic when to trigger mode4 last stage adderTree, since the final results of adderTree
    //is always ready 1 cycle after mode3 finishes, so there is no need on extra
    //logic to control the adderTree outputs
    if (mode3_run == 1) begin
      mode4_stage0_run <= 1;
    end else begin
      mode4_stage0_run <= 0;
    end

    //mode5 should be triggered right at the falling edge of mode4_stage1_run
    if(mode3_run_a & ~mode3_run) begin
      mode5_run <= 1;
    end else if(mode3_run == 0) begin
      mode5_run <= 0;
    end

    if (mode3_stage_run_a & ~mode3_stage_run) begin
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

    if(mode6_run == 1) begin
      mode7_stage_run <= 1;
    end else begin
      mode7_stage_run <= 0;
    end

    if(mode7_stage_run == 1) begin
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
      .inp0(inp_reg[`DATAWIDTH*1-1:`DATAWIDTH*0]),
      .mode1_stage0_run(mode1_stage0_run),
      .clk(clk),
      .reset(reset),
      .outp(max_outp));

  ////------mode2 subtraction---------///////
  wire [`DATAWIDTH-1:0] mode2_outp_sub0;
  mode2_sub mode2_sub(
      .a_inp0(sub0_inp_reg[`DATAWIDTH*1-1:`DATAWIDTH*0]),
      .outp0(mode2_outp_sub0),
      .b_inp(max_outp));

  reg [`DATAWIDTH-1:0] mode2_outp_sub0_reg;
  always @(posedge clk) begin
    if (reset) begin
      mode2_outp_sub0_reg <= 0;
    end else if (mode2_run) begin
      mode2_outp_sub0_reg <= mode2_outp_sub0;
    end
  end

  ////------mode3 exponential---------///////
  wire [`DATAWIDTH-1:0] mode3_outp_exp0;
  mode3_exp mode3_exp(
      .inp0(mode2_outp_sub0_reg),

      .clk(clk),
      .reset(reset),
      .stage_run(mode3_stage_run),

      .outp0(mode3_outp_exp0)
  );

  reg [`DATAWIDTH-1:0] mode3_outp_exp0_reg;
  always @(posedge clk) begin
    if (reset) begin
      mode3_outp_exp0_reg <= 0;
    end else if (mode3_run) begin
      mode3_outp_exp0_reg <= mode3_outp_exp0;
    end
  end

  //////------mode4 pipelined adder tree---------///////
  wire [`DATAWIDTH-1:0] mode4_adder_tree_outp;
  mode4_adder_tree mode4_adder_tree(
    .inp0(mode3_outp_exp0_reg),
    .mode4_stage0_run(mode4_stage0_run),

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
  wire [`DATAWIDTH-1:0] mode6_outp_presub0;
  reg [`DATAWIDTH-1:0] mode6_outp_presub0_reg;

  mode6_sub pre_sub(
      .a_inp0(sub1_inp_reg[`DATAWIDTH*1-1:`DATAWIDTH*0]),
      .b_inp(max_outp),
      .outp0(mode6_outp_presub0)
  );
  always @(posedge clk) begin
    if (reset) begin
      mode6_outp_presub0_reg <= 0;
    end else if (presub_run) begin
      mode6_outp_presub0_reg <= mode6_outp_presub0;
    end
  end

  //////------mode6 logsub ---------///////
  wire [`DATAWIDTH-1:0] mode6_outp_logsub0;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub0_reg;

  mode6_sub log_sub(
      .a_inp0(mode6_outp_presub0_reg),
      .b_inp(mode5_outp_log_reg),
      .outp0(mode6_outp_logsub0)
  );
  always @(posedge clk) begin
    if (reset) begin
      mode6_outp_logsub0_reg <= 0;
    end else if (mode6_run) begin
      mode6_outp_logsub0_reg <= mode6_outp_logsub0;
    end
  end

  //////------mode7 exp---------///////
  wire [`DATAWIDTH-1:0] outp0_temp;
  reg [`DATAWIDTH-1:0] outp0;

  mode7_exp mode7_exp(
      .inp0(mode6_outp_logsub0_reg),

      .clk(clk),
      .reset(reset),
      .stage_run(mode7_stage_run),

      .outp0(outp0_temp)
  );
  always @(posedge clk) begin
    if (reset) begin
      outp0 <= 0;
    end else if (mode7_run) begin
      outp0 <= outp0_temp;
    end
  end

endmodule


module mode1_max_tree(
  inp0, 

  outp,

  mode1_stage0_run,
  clk,
  reset
);
  input clk;
  input reset;
  input mode1_stage0_run;

  input  [`DATAWIDTH-1 : 0] inp0; 

  output [`DATAWIDTH-1 : 0] outp;
  reg    [`DATAWIDTH-1 : 0] outp;

  wire   [`DATAWIDTH-1 : 0] cmp0_out_stage0;

  always @(posedge clk) begin
    if (reset) begin
      outp <= 0;
    end

    if(~reset && mode1_stage0_run) begin
      outp <= cmp0_out_stage0;
    end

  end

wire cmp0_out_stage0_ge_gt;
assign cmp0_out_stage0 = (cmp0_out_stage0_ge_gt==1'b1) ? outp : inp0;
DW01_cmp2 #(`DATAWIDTH) cmp0_stage0(.A(outp),       .B(inp0),   .LEQ(1'b0),   .TC(1'b1), .LT_LE(), .GE_GT(cmp0_out_stage0_ge_gt));

endmodule


module mode2_sub(
  a_inp0,
  b_inp,
  outp0
);

  input  [`DATAWIDTH-1 : 0] a_inp0;
  input  [`DATAWIDTH-1 : 0] b_inp;
  output  [`DATAWIDTH-1 : 0] outp0;
  DW01_sub #(`DATAWIDTH) sub0(.A(a_inp0), .B(b_inp), .CI(1'b0), .DIFF(outp0), .CO());
endmodule


module mode3_exp(
  inp0, 

  clk,
  reset,
  stage_run,

  outp0
);

  input  [`DATAWIDTH-1 : 0] inp0;

  input  clk;
  input  reset;
  input  stage_run;

  output  [`DATAWIDTH-1 : 0] outp0;
  expunit_fixed exp0(.a(inp0), .z(outp0), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
endmodule


module mode4_adder_tree(
  inp0, 
  mode4_stage0_run,

  clk,
  reset,
  outp
);

  input clk;
  input reset;
  input  [`DATAWIDTH-1 : 0] inp0; 
  output [`DATAWIDTH-1 : 0] outp;
  input mode4_stage0_run;

  wire   [`DATAWIDTH-1 : 0] add0_out_stage0;
  reg    [`DATAWIDTH-1 : 0] outp;

  always @(posedge clk) begin
    if (reset) begin
      outp <= 0;
    end

    if(~reset && mode4_stage0_run) begin
      outp <= add0_out_stage0;
    end

  end
  DW01_add #(`DATAWIDTH) add0_stage0(.A(outp),       .B(inp0),     .CI(1'b0),  .SUM(add0_out_stage0), .CO());

endmodule


module mode5_ln(
inp,
outp
);
  input  [`DATAWIDTH-1 : 0] inp;
  output [`DATAWIDTH-1 : 0] outp;
  logunit_fixed ln(.a(inp), .z(outp), .status());
endmodule


module mode6_sub(
  a_inp0,
  b_inp,
  outp0
);

  input  [`DATAWIDTH-1 : 0] a_inp0;
  input  [`DATAWIDTH-1 : 0] b_inp;
  output  [`DATAWIDTH-1 : 0] outp0;
  DW01_sub #(`DATAWIDTH) sub0(.A(a_inp0), .B(b_inp), .CI(1'b0), .DIFF(outp0), .CO());
endmodule


module mode7_exp(
  inp0, 

  clk,
  reset,
  stage_run,

  outp0
);

  input  [`DATAWIDTH-1 : 0] inp0;

  input  clk;
  input  reset;
  input  stage_run;

  output  [`DATAWIDTH-1 : 0] outp0;
  expunit_fixed exp0(.a(inp0), .z(outp0), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
endmodule

