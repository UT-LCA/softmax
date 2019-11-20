
`ifndef DEFINES_DONE
`define DEFINES_DONE
`define EXPONENT 5
`define MANTISSA 10
`define SIGN 1
`define DATAWIDTH (`SIGN+`EXPONENT+`MANTISSA)
`define IEEE_COMPLIANCE 1
`define NUM 4
`define ADDRSIZE 16
`endif


`include "DW_fp_cmp.v"
`include "DW_fp_addsub.v"
`include "DW_fp_add.v"
`include "DW_fp_sub.v"
`include "DW_fp_mult.v"
`include "DW01_ash.v"
`include "exponentialunit.v"
`include "logunit.v"

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

  outp0,
  outp1,
  outp2,
  outp3,

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
  output [`DATAWIDTH-1:0] outp2;
  output [`DATAWIDTH-1:0] outp3;
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

  reg mode3_stage_run;
  reg mode7_stage_run;

  reg mode3_run;

  wire mode1_stage0_run;
  assign mode1_stage0_run = mode1_run;

  reg mode4_stage1_run_a;
  reg mode4_stage2_run_a;
  reg mode4_stage0_run;
  reg mode4_stage1_run;
  reg mode4_stage2_run;

  reg mode5_run;
  reg mode6_run;
  reg mode7_run;
  reg presub_start;
  reg presub_run;
  reg done;

  always @(posedge clk)begin
    mode4_stage1_run_a <= mode4_stage1_run;
    mode4_stage2_run_a <= mode4_stage2_run;
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
      mode4_stage1_run <= 0;
      mode4_stage2_run <= 0;
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
      mode4_stage2_run <= 1;
    end else begin
      mode4_stage2_run <= 0;
    end
    if (mode4_stage2_run == 1) begin
      mode4_stage1_run <= 1;
    end else begin
      mode4_stage1_run <= 0;
    end

    if (mode4_stage1_run == 1) begin
      mode4_stage0_run <= 1;
    end else begin
      mode4_stage0_run <= 0;
    end


    //mode5 should be triggered right at the falling edge of mode4_stage1_run
    if(mode4_stage1_run_a & ~mode4_stage1_run) begin
      mode5_run <= 1;
    end else if(mode4_stage1_run == 0) begin
      mode5_run <= 0;
    end

    if(mode4_stage2_run_a & ~mode4_stage2_run) begin
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
      .inp1(inp_reg[`DATAWIDTH*2-1:`DATAWIDTH*1]),
      .inp2(inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
      .inp3(inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
      .mode1_stage0_run(mode1_stage0_run),
      .clk(clk),
      .reset(reset),
      .outp(max_outp));

  ////------mode2 subtraction---------///////
  wire [`DATAWIDTH-1:0] mode2_outp_sub0;
  wire [`DATAWIDTH-1:0] mode2_outp_sub1;
  wire [`DATAWIDTH-1:0] mode2_outp_sub2;
  wire [`DATAWIDTH-1:0] mode2_outp_sub3;
  mode2_sub mode2_sub(
      .a_inp0(sub0_inp_reg[`DATAWIDTH*1-1:`DATAWIDTH*0]),
      .a_inp1(sub0_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH*1]),
      .a_inp2(sub0_inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
      .a_inp3(sub0_inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
      .outp0(mode2_outp_sub0),
      .outp1(mode2_outp_sub1),
      .outp2(mode2_outp_sub2),
      .outp3(mode2_outp_sub3),
      .b_inp(max_outp));

  reg [`DATAWIDTH-1:0] mode2_outp_sub0_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub1_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub2_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub3_reg;
  always @(posedge clk) begin
    if (reset) begin
      mode2_outp_sub0_reg <= 0;
      mode2_outp_sub1_reg <= 0;
      mode2_outp_sub2_reg <= 0;
      mode2_outp_sub3_reg <= 0;
    end else if (mode2_run) begin
      mode2_outp_sub0_reg <= mode2_outp_sub0;
      mode2_outp_sub1_reg <= mode2_outp_sub1;
      mode2_outp_sub2_reg <= mode2_outp_sub2;
      mode2_outp_sub3_reg <= mode2_outp_sub3;
    end
  end

  ////------mode3 exponential---------///////
  wire [`DATAWIDTH-1:0] mode3_outp_exp0;
  wire [`DATAWIDTH-1:0] mode3_outp_exp1;
  wire [`DATAWIDTH-1:0] mode3_outp_exp2;
  wire [`DATAWIDTH-1:0] mode3_outp_exp3;
  mode3_exp mode3_exp(
      .inp0(mode2_outp_sub0_reg),
      .inp1(mode2_outp_sub1_reg),
      .inp2(mode2_outp_sub2_reg),
      .inp3(mode2_outp_sub3_reg),

      .clk(clk),
      .reset(reset),
      .stage_run(mode3_stage_run),

      .outp0(mode3_outp_exp0),
      .outp1(mode3_outp_exp1),
      .outp2(mode3_outp_exp2),
      .outp3(mode3_outp_exp3)
  );

  reg [`DATAWIDTH-1:0] mode3_outp_exp0_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp1_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp2_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp3_reg;
  always @(posedge clk) begin
    if (reset) begin
      mode3_outp_exp0_reg <= 0;
      mode3_outp_exp1_reg <= 0;
      mode3_outp_exp2_reg <= 0;
      mode3_outp_exp3_reg <= 0;
    end else if (mode3_run) begin
      mode3_outp_exp0_reg <= mode3_outp_exp0;
      mode3_outp_exp1_reg <= mode3_outp_exp1;
      mode3_outp_exp2_reg <= mode3_outp_exp2;
      mode3_outp_exp3_reg <= mode3_outp_exp3;
    end
  end

  //////------mode4 pipelined adder tree---------///////
  wire [`DATAWIDTH-1:0] mode4_adder_tree_outp;
  mode4_adder_tree mode4_adder_tree(
    .inp0(mode3_outp_exp0_reg),
    .inp1(mode3_outp_exp1_reg),
    .inp2(mode3_outp_exp2_reg),
    .inp3(mode3_outp_exp3_reg),
    .mode4_stage2_run(mode4_stage2_run),
    .mode4_stage1_run(mode4_stage1_run),
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
  wire [`DATAWIDTH-1:0] mode6_outp_presub1;
  wire [`DATAWIDTH-1:0] mode6_outp_presub2;
  wire [`DATAWIDTH-1:0] mode6_outp_presub3;
  reg [`DATAWIDTH-1:0] mode6_outp_presub0_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub1_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub2_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub3_reg;

  mode6_sub pre_sub(
      .a_inp0(sub1_inp_reg[`DATAWIDTH*1-1:`DATAWIDTH*0]),
      .a_inp1(sub1_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH*1]),
      .a_inp2(sub1_inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
      .a_inp3(sub1_inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
      .b_inp(max_outp),
      .outp0(mode6_outp_presub0),
      .outp1(mode6_outp_presub1),
      .outp2(mode6_outp_presub2),
      .outp3(mode6_outp_presub3)
  );
  always @(posedge clk) begin
    if (reset) begin
      mode6_outp_presub0_reg <= 0;
      mode6_outp_presub1_reg <= 0;
      mode6_outp_presub2_reg <= 0;
      mode6_outp_presub3_reg <= 0;
    end else if (presub_run) begin
      mode6_outp_presub0_reg <= mode6_outp_presub0;
      mode6_outp_presub1_reg <= mode6_outp_presub1;
      mode6_outp_presub2_reg <= mode6_outp_presub2;
      mode6_outp_presub3_reg <= mode6_outp_presub3;
    end
  end

  //////------mode6 logsub ---------///////
  wire [`DATAWIDTH-1:0] mode6_outp_logsub0;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub1;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub2;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub3;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub0_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub1_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub2_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub3_reg;

  mode6_sub log_sub(
      .a_inp0(mode6_outp_presub0_reg),
      .a_inp1(mode6_outp_presub1_reg),
      .a_inp2(mode6_outp_presub2_reg),
      .a_inp3(mode6_outp_presub3_reg),
      .b_inp(mode5_outp_log_reg),
      .outp0(mode6_outp_logsub0),
      .outp1(mode6_outp_logsub1),
      .outp2(mode6_outp_logsub2),
      .outp3(mode6_outp_logsub3)
  );
  always @(posedge clk) begin
    if (reset) begin
      mode6_outp_logsub0_reg <= 0;
      mode6_outp_logsub1_reg <= 0;
      mode6_outp_logsub2_reg <= 0;
      mode6_outp_logsub3_reg <= 0;
    end else if (mode6_run) begin
      mode6_outp_logsub0_reg <= mode6_outp_logsub0;
      mode6_outp_logsub1_reg <= mode6_outp_logsub1;
      mode6_outp_logsub2_reg <= mode6_outp_logsub2;
      mode6_outp_logsub3_reg <= mode6_outp_logsub3;
    end
  end

  //////------mode7 exp---------///////
  wire [`DATAWIDTH-1:0] outp0_temp;
  wire [`DATAWIDTH-1:0] outp1_temp;
  wire [`DATAWIDTH-1:0] outp2_temp;
  wire [`DATAWIDTH-1:0] outp3_temp;
  reg [`DATAWIDTH-1:0] outp0;
  reg [`DATAWIDTH-1:0] outp1;
  reg [`DATAWIDTH-1:0] outp2;
  reg [`DATAWIDTH-1:0] outp3;

  mode7_exp mode7_exp(
      .inp0(mode6_outp_logsub0_reg),
      .inp1(mode6_outp_logsub1_reg),
      .inp2(mode6_outp_logsub2_reg),
      .inp3(mode6_outp_logsub3_reg),

      .clk(clk),
      .reset(reset),
      .stage_run(mode7_stage_run),

      .outp0(outp0_temp),
      .outp1(outp1_temp),
      .outp2(outp2_temp),
      .outp3(outp3_temp)
  );
  always @(posedge clk) begin
    if (reset) begin
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


module mode1_max_tree(
  inp0, 
  inp1, 
  inp2, 
  inp3, 

  outp,

  mode1_stage0_run,
  clk,
  reset
);
  input clk;
  input reset;
  input mode1_stage0_run;

  input  [`DATAWIDTH-1 : 0] inp0; 
  input  [`DATAWIDTH-1 : 0] inp1; 
  input  [`DATAWIDTH-1 : 0] inp2; 
  input  [`DATAWIDTH-1 : 0] inp3; 

  output [`DATAWIDTH-1 : 0] outp;
  reg    [`DATAWIDTH-1 : 0] outp;

  wire   [`DATAWIDTH-1 : 0] cmp0_out_stage2;
  wire   [`DATAWIDTH-1 : 0] cmp1_out_stage2;
  wire   [`DATAWIDTH-1 : 0] cmp0_out_stage1;
  wire   [`DATAWIDTH-1 : 0] cmp0_out_stage0;

  always @(posedge clk) begin
    if (reset) begin
      outp <= 0;
    end

    if(~reset && mode1_stage0_run) begin
      outp <= cmp0_out_stage0;
    end

  end

DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage2(.a(inp0),       .b(inp1),      .z1(cmp0_out_stage2), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp1_stage2(.a(inp2),       .b(inp3),      .z1(cmp1_out_stage2), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());

DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage1(.a(cmp0_out_stage2),       .b(cmp1_out_stage2),      .z1(cmp0_out_stage1), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());

DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage0(.a(outp),       .b(cmp0_out_stage1),      .z1(cmp0_out_stage0), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());

endmodule


module mode2_sub(
  a_inp0,
  a_inp1,
  a_inp2,
  a_inp3,
  b_inp,
  outp0,
  outp1,
  outp2,
  outp3
);

  input  [`DATAWIDTH-1 : 0] a_inp0;
  input  [`DATAWIDTH-1 : 0] a_inp1;
  input  [`DATAWIDTH-1 : 0] a_inp2;
  input  [`DATAWIDTH-1 : 0] a_inp3;
  input  [`DATAWIDTH-1 : 0] b_inp;
  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub0(.a(a_inp0), .b(b_inp), .z(outp0), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub1(.a(a_inp1), .b(b_inp), .z(outp1), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub2(.a(a_inp2), .b(b_inp), .z(outp2), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub3(.a(a_inp3), .b(b_inp), .z(outp3), .rnd(3'b000), .status());
endmodule


module mode3_exp(
  inp0, 
  inp1, 
  inp2, 
  inp3, 

  clk,
  reset,
  stage_run,

  outp0, 
  outp1, 
  outp2, 
  outp3
);

  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;

  input  clk;
  input  reset;
  input  stage_run;

  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  expunit exp0(.a(inp0), .z(outp0), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp1(.a(inp1), .z(outp1), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp2(.a(inp2), .z(outp2), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp3(.a(inp3), .z(outp3), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
endmodule


module mode4_adder_tree(
  inp0, 
  inp1, 
  inp2, 
  inp3, 
  mode4_stage0_run,
  mode4_stage1_run,
  mode4_stage2_run,

  clk,
  reset,
  outp
);

  input clk;
  input reset;
  input  [`DATAWIDTH-1 : 0] inp0; 
  input  [`DATAWIDTH-1 : 0] inp1; 
  input  [`DATAWIDTH-1 : 0] inp2; 
  input  [`DATAWIDTH-1 : 0] inp3; 
  output [`DATAWIDTH-1 : 0] outp;
  input mode4_stage0_run;
  input mode4_stage1_run;
  input mode4_stage2_run;

  wire   [`DATAWIDTH-1 : 0] add0_out_stage2;
  reg    [`DATAWIDTH-1 : 0] add0_out_stage2_reg;
  wire   [`DATAWIDTH-1 : 0] add1_out_stage2;
  reg    [`DATAWIDTH-1 : 0] add1_out_stage2_reg;

  wire   [`DATAWIDTH-1 : 0] add0_out_stage1;
  reg    [`DATAWIDTH-1 : 0] add0_out_stage1_reg;

  wire   [`DATAWIDTH-1 : 0] add0_out_stage0;
  reg    [`DATAWIDTH-1 : 0] outp;

  always @(posedge clk) begin
    if (reset) begin
      outp <= 0;
      add0_out_stage2_reg <= 0;
      add1_out_stage2_reg <= 0;
      add0_out_stage1_reg <= 0;
    end

    if(~reset && mode4_stage2_run) begin
      add0_out_stage2_reg <= add0_out_stage2;
      add1_out_stage2_reg <= add1_out_stage2;
    end

    if(~reset && mode4_stage1_run) begin
      add0_out_stage1_reg <= add0_out_stage1;
    end

    if(~reset && mode4_stage0_run) begin
      outp <= add0_out_stage0;
    end

  end
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage2(.a(inp0),       .b(inp1),      .z(add0_out_stage2), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add1_stage2(.a(inp2),       .b(inp3),      .z(add1_out_stage2), .rnd(3'b000),    .status());

  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage1(.a(add0_out_stage2_reg),       .b(add1_out_stage2_reg),      .z(add0_out_stage1), .rnd(3'b000),    .status());

  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage0(.a(outp),       .b(add0_out_stage1_reg),      .z(add0_out_stage0), .rnd(3'b000),    .status());

endmodule


module mode5_ln(
inp,
outp
);
  input  [`DATAWIDTH-1 : 0] inp;
  output [`DATAWIDTH-1 : 0] outp;
  logunit ln(.a(inp), .z(outp), .status());
endmodule


module mode6_sub(
  a_inp0,
  a_inp1,
  a_inp2,
  a_inp3,
  b_inp,
  outp0,
  outp1,
  outp2,
  outp3
);

  input  [`DATAWIDTH-1 : 0] a_inp0;
  input  [`DATAWIDTH-1 : 0] a_inp1;
  input  [`DATAWIDTH-1 : 0] a_inp2;
  input  [`DATAWIDTH-1 : 0] a_inp3;
  input  [`DATAWIDTH-1 : 0] b_inp;
  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub0(.a(a_inp0), .b(b_inp), .z(outp0), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub1(.a(a_inp1), .b(b_inp), .z(outp1), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub2(.a(a_inp2), .b(b_inp), .z(outp2), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub3(.a(a_inp3), .b(b_inp), .z(outp3), .rnd(3'b000), .status());
endmodule


module mode7_exp(
  inp0, 
  inp1, 
  inp2, 
  inp3, 

  clk,
  reset,
  stage_run,

  outp0, 
  outp1, 
  outp2, 
  outp3
);

  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;

  input  clk;
  input  reset;
  input  stage_run;

  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  expunit exp0(.a(inp0), .z(outp0), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp1(.a(inp1), .z(outp1), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp2(.a(inp2), .z(outp2), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp3(.a(inp3), .z(outp3), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
endmodule

