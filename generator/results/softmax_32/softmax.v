
`ifndef DEFINES_DONE
`define DEFINES_DONE
`define EXPONENT 5
`define MANTISSA 10
`define SIGN 1
`define DATAWIDTH (`SIGN+`EXPONENT+`MANTISSA)
`define IEEE_COMPLIANCE 1
`define NUM 32
`define ADDRSIZE 16
`endif


//`include "DW_fp_cmp.v"
//`include "DW_fp_addsub.v"
//`include "DW_fp_add.v"
//`include "DW_fp_sub.v"
//`include "DW_fp_mult.v"
//`include "DW01_ash.v"
//`include "exponentialunit.v"
//`include "logunit.v"

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
  outp4,
  outp5,
  outp6,
  outp7,
  outp8,
  outp9,
  outp10,
  outp11,
  outp12,
  outp13,
  outp14,
  outp15,
  outp16,
  outp17,
  outp18,
  outp19,
  outp20,
  outp21,
  outp22,
  outp23,
  outp24,
  outp25,
  outp26,
  outp27,
  outp28,
  outp29,
  outp30,
  outp31,

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
  output [`DATAWIDTH-1:0] outp4;
  output [`DATAWIDTH-1:0] outp5;
  output [`DATAWIDTH-1:0] outp6;
  output [`DATAWIDTH-1:0] outp7;
  output [`DATAWIDTH-1:0] outp8;
  output [`DATAWIDTH-1:0] outp9;
  output [`DATAWIDTH-1:0] outp10;
  output [`DATAWIDTH-1:0] outp11;
  output [`DATAWIDTH-1:0] outp12;
  output [`DATAWIDTH-1:0] outp13;
  output [`DATAWIDTH-1:0] outp14;
  output [`DATAWIDTH-1:0] outp15;
  output [`DATAWIDTH-1:0] outp16;
  output [`DATAWIDTH-1:0] outp17;
  output [`DATAWIDTH-1:0] outp18;
  output [`DATAWIDTH-1:0] outp19;
  output [`DATAWIDTH-1:0] outp20;
  output [`DATAWIDTH-1:0] outp21;
  output [`DATAWIDTH-1:0] outp22;
  output [`DATAWIDTH-1:0] outp23;
  output [`DATAWIDTH-1:0] outp24;
  output [`DATAWIDTH-1:0] outp25;
  output [`DATAWIDTH-1:0] outp26;
  output [`DATAWIDTH-1:0] outp27;
  output [`DATAWIDTH-1:0] outp28;
  output [`DATAWIDTH-1:0] outp29;
  output [`DATAWIDTH-1:0] outp30;
  output [`DATAWIDTH-1:0] outp31;
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

  reg mode1_stage0_run;
  wire mode1_stage3_run;
  assign mode1_stage3_run = mode1_run;

  reg mode4_stage1_run_a;
  reg mode4_stage2_run_a;
  reg mode4_stage0_run;
  reg mode4_stage1_run;
  reg mode4_stage2_run;
  reg mode4_stage3_run;
  reg mode4_stage4_run;
  reg mode4_stage5_run;

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

      mode1_stage0_run <= 0;
      mode3_stage_run <= 0;
      mode7_stage_run <= 0;
      mode2_start <= 0;
      mode2_run <= 0;
      mode3_run <= 0;
      mode4_stage0_run <= 0;
      mode4_stage1_run <= 0;
      mode4_stage2_run <= 0;
      mode4_stage3_run <= 0;
      mode4_stage4_run <= 0;
      mode4_stage5_run <= 0;
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
    end else if(addr == end_addr)begin
      mode2_start <= 1;
      sub0_inp_addr <= start_addr;
      addr <= 0;
      mode1_run <= 0;
      mode1_start <= 0;
    end else begin
      mode1_run <= 0;
    end

    if (mode1_stage3_run == 1) begin
      mode1_stage0_run <= 1;
    end else begin
      mode1_stage0_run <= 0;
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
      mode4_stage5_run <= 1;
    end else begin
      mode4_stage5_run <= 0;
    end
    if (mode4_stage5_run == 1) begin
      mode4_stage4_run <= 1;
    end else begin
      mode4_stage4_run <= 0;
    end

    if (mode4_stage4_run == 1) begin
      mode4_stage3_run <= 1;
    end else begin
      mode4_stage3_run <= 0;
    end

    if (mode4_stage3_run == 1) begin
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
      .inp4(inp_reg[`DATAWIDTH*5-1:`DATAWIDTH*4]),
      .inp5(inp_reg[`DATAWIDTH*6-1:`DATAWIDTH*5]),
      .inp6(inp_reg[`DATAWIDTH*7-1:`DATAWIDTH*6]),
      .inp7(inp_reg[`DATAWIDTH*8-1:`DATAWIDTH*7]),
      .inp8(inp_reg[`DATAWIDTH*9-1:`DATAWIDTH*8]),
      .inp9(inp_reg[`DATAWIDTH*10-1:`DATAWIDTH*9]),
      .inp10(inp_reg[`DATAWIDTH*11-1:`DATAWIDTH*10]),
      .inp11(inp_reg[`DATAWIDTH*12-1:`DATAWIDTH*11]),
      .inp12(inp_reg[`DATAWIDTH*13-1:`DATAWIDTH*12]),
      .inp13(inp_reg[`DATAWIDTH*14-1:`DATAWIDTH*13]),
      .inp14(inp_reg[`DATAWIDTH*15-1:`DATAWIDTH*14]),
      .inp15(inp_reg[`DATAWIDTH*16-1:`DATAWIDTH*15]),
      .inp16(inp_reg[`DATAWIDTH*17-1:`DATAWIDTH*16]),
      .inp17(inp_reg[`DATAWIDTH*18-1:`DATAWIDTH*17]),
      .inp18(inp_reg[`DATAWIDTH*19-1:`DATAWIDTH*18]),
      .inp19(inp_reg[`DATAWIDTH*20-1:`DATAWIDTH*19]),
      .inp20(inp_reg[`DATAWIDTH*21-1:`DATAWIDTH*20]),
      .inp21(inp_reg[`DATAWIDTH*22-1:`DATAWIDTH*21]),
      .inp22(inp_reg[`DATAWIDTH*23-1:`DATAWIDTH*22]),
      .inp23(inp_reg[`DATAWIDTH*24-1:`DATAWIDTH*23]),
      .inp24(inp_reg[`DATAWIDTH*25-1:`DATAWIDTH*24]),
      .inp25(inp_reg[`DATAWIDTH*26-1:`DATAWIDTH*25]),
      .inp26(inp_reg[`DATAWIDTH*27-1:`DATAWIDTH*26]),
      .inp27(inp_reg[`DATAWIDTH*28-1:`DATAWIDTH*27]),
      .inp28(inp_reg[`DATAWIDTH*29-1:`DATAWIDTH*28]),
      .inp29(inp_reg[`DATAWIDTH*30-1:`DATAWIDTH*29]),
      .inp30(inp_reg[`DATAWIDTH*31-1:`DATAWIDTH*30]),
      .inp31(inp_reg[`DATAWIDTH*32-1:`DATAWIDTH*31]),
      .mode1_stage0_run(mode1_stage0_run),
      .mode1_stage3_run(mode1_stage3_run),
      .clk(clk),
      .reset(reset),
      .outp(max_outp));

  ////------mode2 subtraction---------///////
  wire [`DATAWIDTH-1:0] mode2_outp_sub0;
  wire [`DATAWIDTH-1:0] mode2_outp_sub1;
  wire [`DATAWIDTH-1:0] mode2_outp_sub2;
  wire [`DATAWIDTH-1:0] mode2_outp_sub3;
  wire [`DATAWIDTH-1:0] mode2_outp_sub4;
  wire [`DATAWIDTH-1:0] mode2_outp_sub5;
  wire [`DATAWIDTH-1:0] mode2_outp_sub6;
  wire [`DATAWIDTH-1:0] mode2_outp_sub7;
  wire [`DATAWIDTH-1:0] mode2_outp_sub8;
  wire [`DATAWIDTH-1:0] mode2_outp_sub9;
  wire [`DATAWIDTH-1:0] mode2_outp_sub10;
  wire [`DATAWIDTH-1:0] mode2_outp_sub11;
  wire [`DATAWIDTH-1:0] mode2_outp_sub12;
  wire [`DATAWIDTH-1:0] mode2_outp_sub13;
  wire [`DATAWIDTH-1:0] mode2_outp_sub14;
  wire [`DATAWIDTH-1:0] mode2_outp_sub15;
  wire [`DATAWIDTH-1:0] mode2_outp_sub16;
  wire [`DATAWIDTH-1:0] mode2_outp_sub17;
  wire [`DATAWIDTH-1:0] mode2_outp_sub18;
  wire [`DATAWIDTH-1:0] mode2_outp_sub19;
  wire [`DATAWIDTH-1:0] mode2_outp_sub20;
  wire [`DATAWIDTH-1:0] mode2_outp_sub21;
  wire [`DATAWIDTH-1:0] mode2_outp_sub22;
  wire [`DATAWIDTH-1:0] mode2_outp_sub23;
  wire [`DATAWIDTH-1:0] mode2_outp_sub24;
  wire [`DATAWIDTH-1:0] mode2_outp_sub25;
  wire [`DATAWIDTH-1:0] mode2_outp_sub26;
  wire [`DATAWIDTH-1:0] mode2_outp_sub27;
  wire [`DATAWIDTH-1:0] mode2_outp_sub28;
  wire [`DATAWIDTH-1:0] mode2_outp_sub29;
  wire [`DATAWIDTH-1:0] mode2_outp_sub30;
  wire [`DATAWIDTH-1:0] mode2_outp_sub31;
  mode2_sub mode2_sub(
      .a_inp0(sub0_inp_reg[`DATAWIDTH*1-1:`DATAWIDTH*0]),
      .a_inp1(sub0_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH*1]),
      .a_inp2(sub0_inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
      .a_inp3(sub0_inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
      .a_inp4(sub0_inp_reg[`DATAWIDTH*5-1:`DATAWIDTH*4]),
      .a_inp5(sub0_inp_reg[`DATAWIDTH*6-1:`DATAWIDTH*5]),
      .a_inp6(sub0_inp_reg[`DATAWIDTH*7-1:`DATAWIDTH*6]),
      .a_inp7(sub0_inp_reg[`DATAWIDTH*8-1:`DATAWIDTH*7]),
      .a_inp8(sub0_inp_reg[`DATAWIDTH*9-1:`DATAWIDTH*8]),
      .a_inp9(sub0_inp_reg[`DATAWIDTH*10-1:`DATAWIDTH*9]),
      .a_inp10(sub0_inp_reg[`DATAWIDTH*11-1:`DATAWIDTH*10]),
      .a_inp11(sub0_inp_reg[`DATAWIDTH*12-1:`DATAWIDTH*11]),
      .a_inp12(sub0_inp_reg[`DATAWIDTH*13-1:`DATAWIDTH*12]),
      .a_inp13(sub0_inp_reg[`DATAWIDTH*14-1:`DATAWIDTH*13]),
      .a_inp14(sub0_inp_reg[`DATAWIDTH*15-1:`DATAWIDTH*14]),
      .a_inp15(sub0_inp_reg[`DATAWIDTH*16-1:`DATAWIDTH*15]),
      .a_inp16(sub0_inp_reg[`DATAWIDTH*17-1:`DATAWIDTH*16]),
      .a_inp17(sub0_inp_reg[`DATAWIDTH*18-1:`DATAWIDTH*17]),
      .a_inp18(sub0_inp_reg[`DATAWIDTH*19-1:`DATAWIDTH*18]),
      .a_inp19(sub0_inp_reg[`DATAWIDTH*20-1:`DATAWIDTH*19]),
      .a_inp20(sub0_inp_reg[`DATAWIDTH*21-1:`DATAWIDTH*20]),
      .a_inp21(sub0_inp_reg[`DATAWIDTH*22-1:`DATAWIDTH*21]),
      .a_inp22(sub0_inp_reg[`DATAWIDTH*23-1:`DATAWIDTH*22]),
      .a_inp23(sub0_inp_reg[`DATAWIDTH*24-1:`DATAWIDTH*23]),
      .a_inp24(sub0_inp_reg[`DATAWIDTH*25-1:`DATAWIDTH*24]),
      .a_inp25(sub0_inp_reg[`DATAWIDTH*26-1:`DATAWIDTH*25]),
      .a_inp26(sub0_inp_reg[`DATAWIDTH*27-1:`DATAWIDTH*26]),
      .a_inp27(sub0_inp_reg[`DATAWIDTH*28-1:`DATAWIDTH*27]),
      .a_inp28(sub0_inp_reg[`DATAWIDTH*29-1:`DATAWIDTH*28]),
      .a_inp29(sub0_inp_reg[`DATAWIDTH*30-1:`DATAWIDTH*29]),
      .a_inp30(sub0_inp_reg[`DATAWIDTH*31-1:`DATAWIDTH*30]),
      .a_inp31(sub0_inp_reg[`DATAWIDTH*32-1:`DATAWIDTH*31]),
      .outp0(mode2_outp_sub0),
      .outp1(mode2_outp_sub1),
      .outp2(mode2_outp_sub2),
      .outp3(mode2_outp_sub3),
      .outp4(mode2_outp_sub4),
      .outp5(mode2_outp_sub5),
      .outp6(mode2_outp_sub6),
      .outp7(mode2_outp_sub7),
      .outp8(mode2_outp_sub8),
      .outp9(mode2_outp_sub9),
      .outp10(mode2_outp_sub10),
      .outp11(mode2_outp_sub11),
      .outp12(mode2_outp_sub12),
      .outp13(mode2_outp_sub13),
      .outp14(mode2_outp_sub14),
      .outp15(mode2_outp_sub15),
      .outp16(mode2_outp_sub16),
      .outp17(mode2_outp_sub17),
      .outp18(mode2_outp_sub18),
      .outp19(mode2_outp_sub19),
      .outp20(mode2_outp_sub20),
      .outp21(mode2_outp_sub21),
      .outp22(mode2_outp_sub22),
      .outp23(mode2_outp_sub23),
      .outp24(mode2_outp_sub24),
      .outp25(mode2_outp_sub25),
      .outp26(mode2_outp_sub26),
      .outp27(mode2_outp_sub27),
      .outp28(mode2_outp_sub28),
      .outp29(mode2_outp_sub29),
      .outp30(mode2_outp_sub30),
      .outp31(mode2_outp_sub31),
      .b_inp(max_outp));

  reg [`DATAWIDTH-1:0] mode2_outp_sub0_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub1_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub2_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub3_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub4_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub5_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub6_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub7_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub8_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub9_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub10_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub11_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub12_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub13_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub14_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub15_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub16_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub17_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub18_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub19_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub20_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub21_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub22_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub23_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub24_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub25_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub26_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub27_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub28_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub29_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub30_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub31_reg;
  always @(posedge clk) begin
    if (reset) begin
      mode2_outp_sub0_reg <= 0;
      mode2_outp_sub1_reg <= 0;
      mode2_outp_sub2_reg <= 0;
      mode2_outp_sub3_reg <= 0;
      mode2_outp_sub4_reg <= 0;
      mode2_outp_sub5_reg <= 0;
      mode2_outp_sub6_reg <= 0;
      mode2_outp_sub7_reg <= 0;
      mode2_outp_sub8_reg <= 0;
      mode2_outp_sub9_reg <= 0;
      mode2_outp_sub10_reg <= 0;
      mode2_outp_sub11_reg <= 0;
      mode2_outp_sub12_reg <= 0;
      mode2_outp_sub13_reg <= 0;
      mode2_outp_sub14_reg <= 0;
      mode2_outp_sub15_reg <= 0;
      mode2_outp_sub16_reg <= 0;
      mode2_outp_sub17_reg <= 0;
      mode2_outp_sub18_reg <= 0;
      mode2_outp_sub19_reg <= 0;
      mode2_outp_sub20_reg <= 0;
      mode2_outp_sub21_reg <= 0;
      mode2_outp_sub22_reg <= 0;
      mode2_outp_sub23_reg <= 0;
      mode2_outp_sub24_reg <= 0;
      mode2_outp_sub25_reg <= 0;
      mode2_outp_sub26_reg <= 0;
      mode2_outp_sub27_reg <= 0;
      mode2_outp_sub28_reg <= 0;
      mode2_outp_sub29_reg <= 0;
      mode2_outp_sub30_reg <= 0;
      mode2_outp_sub31_reg <= 0;
    end else if (mode2_run) begin
      mode2_outp_sub0_reg <= mode2_outp_sub0;
      mode2_outp_sub1_reg <= mode2_outp_sub1;
      mode2_outp_sub2_reg <= mode2_outp_sub2;
      mode2_outp_sub3_reg <= mode2_outp_sub3;
      mode2_outp_sub4_reg <= mode2_outp_sub4;
      mode2_outp_sub5_reg <= mode2_outp_sub5;
      mode2_outp_sub6_reg <= mode2_outp_sub6;
      mode2_outp_sub7_reg <= mode2_outp_sub7;
      mode2_outp_sub8_reg <= mode2_outp_sub8;
      mode2_outp_sub9_reg <= mode2_outp_sub9;
      mode2_outp_sub10_reg <= mode2_outp_sub10;
      mode2_outp_sub11_reg <= mode2_outp_sub11;
      mode2_outp_sub12_reg <= mode2_outp_sub12;
      mode2_outp_sub13_reg <= mode2_outp_sub13;
      mode2_outp_sub14_reg <= mode2_outp_sub14;
      mode2_outp_sub15_reg <= mode2_outp_sub15;
      mode2_outp_sub16_reg <= mode2_outp_sub16;
      mode2_outp_sub17_reg <= mode2_outp_sub17;
      mode2_outp_sub18_reg <= mode2_outp_sub18;
      mode2_outp_sub19_reg <= mode2_outp_sub19;
      mode2_outp_sub20_reg <= mode2_outp_sub20;
      mode2_outp_sub21_reg <= mode2_outp_sub21;
      mode2_outp_sub22_reg <= mode2_outp_sub22;
      mode2_outp_sub23_reg <= mode2_outp_sub23;
      mode2_outp_sub24_reg <= mode2_outp_sub24;
      mode2_outp_sub25_reg <= mode2_outp_sub25;
      mode2_outp_sub26_reg <= mode2_outp_sub26;
      mode2_outp_sub27_reg <= mode2_outp_sub27;
      mode2_outp_sub28_reg <= mode2_outp_sub28;
      mode2_outp_sub29_reg <= mode2_outp_sub29;
      mode2_outp_sub30_reg <= mode2_outp_sub30;
      mode2_outp_sub31_reg <= mode2_outp_sub31;
    end
  end

  ////------mode3 exponential---------///////
  wire [`DATAWIDTH-1:0] mode3_outp_exp0;
  wire [`DATAWIDTH-1:0] mode3_outp_exp1;
  wire [`DATAWIDTH-1:0] mode3_outp_exp2;
  wire [`DATAWIDTH-1:0] mode3_outp_exp3;
  wire [`DATAWIDTH-1:0] mode3_outp_exp4;
  wire [`DATAWIDTH-1:0] mode3_outp_exp5;
  wire [`DATAWIDTH-1:0] mode3_outp_exp6;
  wire [`DATAWIDTH-1:0] mode3_outp_exp7;
  wire [`DATAWIDTH-1:0] mode3_outp_exp8;
  wire [`DATAWIDTH-1:0] mode3_outp_exp9;
  wire [`DATAWIDTH-1:0] mode3_outp_exp10;
  wire [`DATAWIDTH-1:0] mode3_outp_exp11;
  wire [`DATAWIDTH-1:0] mode3_outp_exp12;
  wire [`DATAWIDTH-1:0] mode3_outp_exp13;
  wire [`DATAWIDTH-1:0] mode3_outp_exp14;
  wire [`DATAWIDTH-1:0] mode3_outp_exp15;
  wire [`DATAWIDTH-1:0] mode3_outp_exp16;
  wire [`DATAWIDTH-1:0] mode3_outp_exp17;
  wire [`DATAWIDTH-1:0] mode3_outp_exp18;
  wire [`DATAWIDTH-1:0] mode3_outp_exp19;
  wire [`DATAWIDTH-1:0] mode3_outp_exp20;
  wire [`DATAWIDTH-1:0] mode3_outp_exp21;
  wire [`DATAWIDTH-1:0] mode3_outp_exp22;
  wire [`DATAWIDTH-1:0] mode3_outp_exp23;
  wire [`DATAWIDTH-1:0] mode3_outp_exp24;
  wire [`DATAWIDTH-1:0] mode3_outp_exp25;
  wire [`DATAWIDTH-1:0] mode3_outp_exp26;
  wire [`DATAWIDTH-1:0] mode3_outp_exp27;
  wire [`DATAWIDTH-1:0] mode3_outp_exp28;
  wire [`DATAWIDTH-1:0] mode3_outp_exp29;
  wire [`DATAWIDTH-1:0] mode3_outp_exp30;
  wire [`DATAWIDTH-1:0] mode3_outp_exp31;
  mode3_exp mode3_exp(
      .inp0(mode2_outp_sub0_reg),
      .inp1(mode2_outp_sub1_reg),
      .inp2(mode2_outp_sub2_reg),
      .inp3(mode2_outp_sub3_reg),
      .inp4(mode2_outp_sub4_reg),
      .inp5(mode2_outp_sub5_reg),
      .inp6(mode2_outp_sub6_reg),
      .inp7(mode2_outp_sub7_reg),
      .inp8(mode2_outp_sub8_reg),
      .inp9(mode2_outp_sub9_reg),
      .inp10(mode2_outp_sub10_reg),
      .inp11(mode2_outp_sub11_reg),
      .inp12(mode2_outp_sub12_reg),
      .inp13(mode2_outp_sub13_reg),
      .inp14(mode2_outp_sub14_reg),
      .inp15(mode2_outp_sub15_reg),
      .inp16(mode2_outp_sub16_reg),
      .inp17(mode2_outp_sub17_reg),
      .inp18(mode2_outp_sub18_reg),
      .inp19(mode2_outp_sub19_reg),
      .inp20(mode2_outp_sub20_reg),
      .inp21(mode2_outp_sub21_reg),
      .inp22(mode2_outp_sub22_reg),
      .inp23(mode2_outp_sub23_reg),
      .inp24(mode2_outp_sub24_reg),
      .inp25(mode2_outp_sub25_reg),
      .inp26(mode2_outp_sub26_reg),
      .inp27(mode2_outp_sub27_reg),
      .inp28(mode2_outp_sub28_reg),
      .inp29(mode2_outp_sub29_reg),
      .inp30(mode2_outp_sub30_reg),
      .inp31(mode2_outp_sub31_reg),

      .clk(clk),
      .reset(reset),
      .stage_run(mode3_stage_run),

      .outp0(mode3_outp_exp0),
      .outp1(mode3_outp_exp1),
      .outp2(mode3_outp_exp2),
      .outp3(mode3_outp_exp3),
      .outp4(mode3_outp_exp4),
      .outp5(mode3_outp_exp5),
      .outp6(mode3_outp_exp6),
      .outp7(mode3_outp_exp7),
      .outp8(mode3_outp_exp8),
      .outp9(mode3_outp_exp9),
      .outp10(mode3_outp_exp10),
      .outp11(mode3_outp_exp11),
      .outp12(mode3_outp_exp12),
      .outp13(mode3_outp_exp13),
      .outp14(mode3_outp_exp14),
      .outp15(mode3_outp_exp15),
      .outp16(mode3_outp_exp16),
      .outp17(mode3_outp_exp17),
      .outp18(mode3_outp_exp18),
      .outp19(mode3_outp_exp19),
      .outp20(mode3_outp_exp20),
      .outp21(mode3_outp_exp21),
      .outp22(mode3_outp_exp22),
      .outp23(mode3_outp_exp23),
      .outp24(mode3_outp_exp24),
      .outp25(mode3_outp_exp25),
      .outp26(mode3_outp_exp26),
      .outp27(mode3_outp_exp27),
      .outp28(mode3_outp_exp28),
      .outp29(mode3_outp_exp29),
      .outp30(mode3_outp_exp30),
      .outp31(mode3_outp_exp31)
  );

  reg [`DATAWIDTH-1:0] mode3_outp_exp0_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp1_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp2_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp3_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp4_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp5_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp6_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp7_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp8_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp9_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp10_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp11_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp12_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp13_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp14_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp15_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp16_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp17_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp18_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp19_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp20_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp21_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp22_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp23_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp24_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp25_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp26_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp27_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp28_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp29_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp30_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp31_reg;
  always @(posedge clk) begin
    if (reset) begin
      mode3_outp_exp0_reg <= 0;
      mode3_outp_exp1_reg <= 0;
      mode3_outp_exp2_reg <= 0;
      mode3_outp_exp3_reg <= 0;
      mode3_outp_exp4_reg <= 0;
      mode3_outp_exp5_reg <= 0;
      mode3_outp_exp6_reg <= 0;
      mode3_outp_exp7_reg <= 0;
      mode3_outp_exp8_reg <= 0;
      mode3_outp_exp9_reg <= 0;
      mode3_outp_exp10_reg <= 0;
      mode3_outp_exp11_reg <= 0;
      mode3_outp_exp12_reg <= 0;
      mode3_outp_exp13_reg <= 0;
      mode3_outp_exp14_reg <= 0;
      mode3_outp_exp15_reg <= 0;
      mode3_outp_exp16_reg <= 0;
      mode3_outp_exp17_reg <= 0;
      mode3_outp_exp18_reg <= 0;
      mode3_outp_exp19_reg <= 0;
      mode3_outp_exp20_reg <= 0;
      mode3_outp_exp21_reg <= 0;
      mode3_outp_exp22_reg <= 0;
      mode3_outp_exp23_reg <= 0;
      mode3_outp_exp24_reg <= 0;
      mode3_outp_exp25_reg <= 0;
      mode3_outp_exp26_reg <= 0;
      mode3_outp_exp27_reg <= 0;
      mode3_outp_exp28_reg <= 0;
      mode3_outp_exp29_reg <= 0;
      mode3_outp_exp30_reg <= 0;
      mode3_outp_exp31_reg <= 0;
    end else if (mode3_run) begin
      mode3_outp_exp0_reg <= mode3_outp_exp0;
      mode3_outp_exp1_reg <= mode3_outp_exp1;
      mode3_outp_exp2_reg <= mode3_outp_exp2;
      mode3_outp_exp3_reg <= mode3_outp_exp3;
      mode3_outp_exp4_reg <= mode3_outp_exp4;
      mode3_outp_exp5_reg <= mode3_outp_exp5;
      mode3_outp_exp6_reg <= mode3_outp_exp6;
      mode3_outp_exp7_reg <= mode3_outp_exp7;
      mode3_outp_exp8_reg <= mode3_outp_exp8;
      mode3_outp_exp9_reg <= mode3_outp_exp9;
      mode3_outp_exp10_reg <= mode3_outp_exp10;
      mode3_outp_exp11_reg <= mode3_outp_exp11;
      mode3_outp_exp12_reg <= mode3_outp_exp12;
      mode3_outp_exp13_reg <= mode3_outp_exp13;
      mode3_outp_exp14_reg <= mode3_outp_exp14;
      mode3_outp_exp15_reg <= mode3_outp_exp15;
      mode3_outp_exp16_reg <= mode3_outp_exp16;
      mode3_outp_exp17_reg <= mode3_outp_exp17;
      mode3_outp_exp18_reg <= mode3_outp_exp18;
      mode3_outp_exp19_reg <= mode3_outp_exp19;
      mode3_outp_exp20_reg <= mode3_outp_exp20;
      mode3_outp_exp21_reg <= mode3_outp_exp21;
      mode3_outp_exp22_reg <= mode3_outp_exp22;
      mode3_outp_exp23_reg <= mode3_outp_exp23;
      mode3_outp_exp24_reg <= mode3_outp_exp24;
      mode3_outp_exp25_reg <= mode3_outp_exp25;
      mode3_outp_exp26_reg <= mode3_outp_exp26;
      mode3_outp_exp27_reg <= mode3_outp_exp27;
      mode3_outp_exp28_reg <= mode3_outp_exp28;
      mode3_outp_exp29_reg <= mode3_outp_exp29;
      mode3_outp_exp30_reg <= mode3_outp_exp30;
      mode3_outp_exp31_reg <= mode3_outp_exp31;
    end
  end

  //////------mode4 pipelined adder tree---------///////
  wire [`DATAWIDTH-1:0] mode4_adder_tree_outp;
  mode4_adder_tree mode4_adder_tree(
    .inp0(mode3_outp_exp0_reg),
    .inp1(mode3_outp_exp1_reg),
    .inp2(mode3_outp_exp2_reg),
    .inp3(mode3_outp_exp3_reg),
    .inp4(mode3_outp_exp4_reg),
    .inp5(mode3_outp_exp5_reg),
    .inp6(mode3_outp_exp6_reg),
    .inp7(mode3_outp_exp7_reg),
    .inp8(mode3_outp_exp8_reg),
    .inp9(mode3_outp_exp9_reg),
    .inp10(mode3_outp_exp10_reg),
    .inp11(mode3_outp_exp11_reg),
    .inp12(mode3_outp_exp12_reg),
    .inp13(mode3_outp_exp13_reg),
    .inp14(mode3_outp_exp14_reg),
    .inp15(mode3_outp_exp15_reg),
    .inp16(mode3_outp_exp16_reg),
    .inp17(mode3_outp_exp17_reg),
    .inp18(mode3_outp_exp18_reg),
    .inp19(mode3_outp_exp19_reg),
    .inp20(mode3_outp_exp20_reg),
    .inp21(mode3_outp_exp21_reg),
    .inp22(mode3_outp_exp22_reg),
    .inp23(mode3_outp_exp23_reg),
    .inp24(mode3_outp_exp24_reg),
    .inp25(mode3_outp_exp25_reg),
    .inp26(mode3_outp_exp26_reg),
    .inp27(mode3_outp_exp27_reg),
    .inp28(mode3_outp_exp28_reg),
    .inp29(mode3_outp_exp29_reg),
    .inp30(mode3_outp_exp30_reg),
    .inp31(mode3_outp_exp31_reg),
    .mode4_stage5_run(mode4_stage5_run),
    .mode4_stage4_run(mode4_stage4_run),
    .mode4_stage3_run(mode4_stage3_run),
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
  wire [`DATAWIDTH-1:0] mode6_outp_presub4;
  wire [`DATAWIDTH-1:0] mode6_outp_presub5;
  wire [`DATAWIDTH-1:0] mode6_outp_presub6;
  wire [`DATAWIDTH-1:0] mode6_outp_presub7;
  wire [`DATAWIDTH-1:0] mode6_outp_presub8;
  wire [`DATAWIDTH-1:0] mode6_outp_presub9;
  wire [`DATAWIDTH-1:0] mode6_outp_presub10;
  wire [`DATAWIDTH-1:0] mode6_outp_presub11;
  wire [`DATAWIDTH-1:0] mode6_outp_presub12;
  wire [`DATAWIDTH-1:0] mode6_outp_presub13;
  wire [`DATAWIDTH-1:0] mode6_outp_presub14;
  wire [`DATAWIDTH-1:0] mode6_outp_presub15;
  wire [`DATAWIDTH-1:0] mode6_outp_presub16;
  wire [`DATAWIDTH-1:0] mode6_outp_presub17;
  wire [`DATAWIDTH-1:0] mode6_outp_presub18;
  wire [`DATAWIDTH-1:0] mode6_outp_presub19;
  wire [`DATAWIDTH-1:0] mode6_outp_presub20;
  wire [`DATAWIDTH-1:0] mode6_outp_presub21;
  wire [`DATAWIDTH-1:0] mode6_outp_presub22;
  wire [`DATAWIDTH-1:0] mode6_outp_presub23;
  wire [`DATAWIDTH-1:0] mode6_outp_presub24;
  wire [`DATAWIDTH-1:0] mode6_outp_presub25;
  wire [`DATAWIDTH-1:0] mode6_outp_presub26;
  wire [`DATAWIDTH-1:0] mode6_outp_presub27;
  wire [`DATAWIDTH-1:0] mode6_outp_presub28;
  wire [`DATAWIDTH-1:0] mode6_outp_presub29;
  wire [`DATAWIDTH-1:0] mode6_outp_presub30;
  wire [`DATAWIDTH-1:0] mode6_outp_presub31;
  reg [`DATAWIDTH-1:0] mode6_outp_presub0_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub1_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub2_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub3_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub4_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub5_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub6_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub7_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub8_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub9_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub10_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub11_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub12_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub13_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub14_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub15_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub16_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub17_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub18_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub19_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub20_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub21_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub22_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub23_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub24_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub25_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub26_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub27_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub28_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub29_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub30_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub31_reg;

  mode6_sub pre_sub(
      .a_inp0(sub1_inp_reg[`DATAWIDTH*1-1:`DATAWIDTH*0]),
      .a_inp1(sub1_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH*1]),
      .a_inp2(sub1_inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
      .a_inp3(sub1_inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
      .a_inp4(sub1_inp_reg[`DATAWIDTH*5-1:`DATAWIDTH*4]),
      .a_inp5(sub1_inp_reg[`DATAWIDTH*6-1:`DATAWIDTH*5]),
      .a_inp6(sub1_inp_reg[`DATAWIDTH*7-1:`DATAWIDTH*6]),
      .a_inp7(sub1_inp_reg[`DATAWIDTH*8-1:`DATAWIDTH*7]),
      .a_inp8(sub1_inp_reg[`DATAWIDTH*9-1:`DATAWIDTH*8]),
      .a_inp9(sub1_inp_reg[`DATAWIDTH*10-1:`DATAWIDTH*9]),
      .a_inp10(sub1_inp_reg[`DATAWIDTH*11-1:`DATAWIDTH*10]),
      .a_inp11(sub1_inp_reg[`DATAWIDTH*12-1:`DATAWIDTH*11]),
      .a_inp12(sub1_inp_reg[`DATAWIDTH*13-1:`DATAWIDTH*12]),
      .a_inp13(sub1_inp_reg[`DATAWIDTH*14-1:`DATAWIDTH*13]),
      .a_inp14(sub1_inp_reg[`DATAWIDTH*15-1:`DATAWIDTH*14]),
      .a_inp15(sub1_inp_reg[`DATAWIDTH*16-1:`DATAWIDTH*15]),
      .a_inp16(sub1_inp_reg[`DATAWIDTH*17-1:`DATAWIDTH*16]),
      .a_inp17(sub1_inp_reg[`DATAWIDTH*18-1:`DATAWIDTH*17]),
      .a_inp18(sub1_inp_reg[`DATAWIDTH*19-1:`DATAWIDTH*18]),
      .a_inp19(sub1_inp_reg[`DATAWIDTH*20-1:`DATAWIDTH*19]),
      .a_inp20(sub1_inp_reg[`DATAWIDTH*21-1:`DATAWIDTH*20]),
      .a_inp21(sub1_inp_reg[`DATAWIDTH*22-1:`DATAWIDTH*21]),
      .a_inp22(sub1_inp_reg[`DATAWIDTH*23-1:`DATAWIDTH*22]),
      .a_inp23(sub1_inp_reg[`DATAWIDTH*24-1:`DATAWIDTH*23]),
      .a_inp24(sub1_inp_reg[`DATAWIDTH*25-1:`DATAWIDTH*24]),
      .a_inp25(sub1_inp_reg[`DATAWIDTH*26-1:`DATAWIDTH*25]),
      .a_inp26(sub1_inp_reg[`DATAWIDTH*27-1:`DATAWIDTH*26]),
      .a_inp27(sub1_inp_reg[`DATAWIDTH*28-1:`DATAWIDTH*27]),
      .a_inp28(sub1_inp_reg[`DATAWIDTH*29-1:`DATAWIDTH*28]),
      .a_inp29(sub1_inp_reg[`DATAWIDTH*30-1:`DATAWIDTH*29]),
      .a_inp30(sub1_inp_reg[`DATAWIDTH*31-1:`DATAWIDTH*30]),
      .a_inp31(sub1_inp_reg[`DATAWIDTH*32-1:`DATAWIDTH*31]),
      .b_inp(max_outp),
      .outp0(mode6_outp_presub0),
      .outp1(mode6_outp_presub1),
      .outp2(mode6_outp_presub2),
      .outp3(mode6_outp_presub3),
      .outp4(mode6_outp_presub4),
      .outp5(mode6_outp_presub5),
      .outp6(mode6_outp_presub6),
      .outp7(mode6_outp_presub7),
      .outp8(mode6_outp_presub8),
      .outp9(mode6_outp_presub9),
      .outp10(mode6_outp_presub10),
      .outp11(mode6_outp_presub11),
      .outp12(mode6_outp_presub12),
      .outp13(mode6_outp_presub13),
      .outp14(mode6_outp_presub14),
      .outp15(mode6_outp_presub15),
      .outp16(mode6_outp_presub16),
      .outp17(mode6_outp_presub17),
      .outp18(mode6_outp_presub18),
      .outp19(mode6_outp_presub19),
      .outp20(mode6_outp_presub20),
      .outp21(mode6_outp_presub21),
      .outp22(mode6_outp_presub22),
      .outp23(mode6_outp_presub23),
      .outp24(mode6_outp_presub24),
      .outp25(mode6_outp_presub25),
      .outp26(mode6_outp_presub26),
      .outp27(mode6_outp_presub27),
      .outp28(mode6_outp_presub28),
      .outp29(mode6_outp_presub29),
      .outp30(mode6_outp_presub30),
      .outp31(mode6_outp_presub31)
  );
  always @(posedge clk) begin
    if (reset) begin
      mode6_outp_presub0_reg <= 0;
      mode6_outp_presub1_reg <= 0;
      mode6_outp_presub2_reg <= 0;
      mode6_outp_presub3_reg <= 0;
      mode6_outp_presub4_reg <= 0;
      mode6_outp_presub5_reg <= 0;
      mode6_outp_presub6_reg <= 0;
      mode6_outp_presub7_reg <= 0;
      mode6_outp_presub8_reg <= 0;
      mode6_outp_presub9_reg <= 0;
      mode6_outp_presub10_reg <= 0;
      mode6_outp_presub11_reg <= 0;
      mode6_outp_presub12_reg <= 0;
      mode6_outp_presub13_reg <= 0;
      mode6_outp_presub14_reg <= 0;
      mode6_outp_presub15_reg <= 0;
      mode6_outp_presub16_reg <= 0;
      mode6_outp_presub17_reg <= 0;
      mode6_outp_presub18_reg <= 0;
      mode6_outp_presub19_reg <= 0;
      mode6_outp_presub20_reg <= 0;
      mode6_outp_presub21_reg <= 0;
      mode6_outp_presub22_reg <= 0;
      mode6_outp_presub23_reg <= 0;
      mode6_outp_presub24_reg <= 0;
      mode6_outp_presub25_reg <= 0;
      mode6_outp_presub26_reg <= 0;
      mode6_outp_presub27_reg <= 0;
      mode6_outp_presub28_reg <= 0;
      mode6_outp_presub29_reg <= 0;
      mode6_outp_presub30_reg <= 0;
      mode6_outp_presub31_reg <= 0;
    end else if (presub_run) begin
      mode6_outp_presub0_reg <= mode6_outp_presub0;
      mode6_outp_presub1_reg <= mode6_outp_presub1;
      mode6_outp_presub2_reg <= mode6_outp_presub2;
      mode6_outp_presub3_reg <= mode6_outp_presub3;
      mode6_outp_presub4_reg <= mode6_outp_presub4;
      mode6_outp_presub5_reg <= mode6_outp_presub5;
      mode6_outp_presub6_reg <= mode6_outp_presub6;
      mode6_outp_presub7_reg <= mode6_outp_presub7;
      mode6_outp_presub8_reg <= mode6_outp_presub8;
      mode6_outp_presub9_reg <= mode6_outp_presub9;
      mode6_outp_presub10_reg <= mode6_outp_presub10;
      mode6_outp_presub11_reg <= mode6_outp_presub11;
      mode6_outp_presub12_reg <= mode6_outp_presub12;
      mode6_outp_presub13_reg <= mode6_outp_presub13;
      mode6_outp_presub14_reg <= mode6_outp_presub14;
      mode6_outp_presub15_reg <= mode6_outp_presub15;
      mode6_outp_presub16_reg <= mode6_outp_presub16;
      mode6_outp_presub17_reg <= mode6_outp_presub17;
      mode6_outp_presub18_reg <= mode6_outp_presub18;
      mode6_outp_presub19_reg <= mode6_outp_presub19;
      mode6_outp_presub20_reg <= mode6_outp_presub20;
      mode6_outp_presub21_reg <= mode6_outp_presub21;
      mode6_outp_presub22_reg <= mode6_outp_presub22;
      mode6_outp_presub23_reg <= mode6_outp_presub23;
      mode6_outp_presub24_reg <= mode6_outp_presub24;
      mode6_outp_presub25_reg <= mode6_outp_presub25;
      mode6_outp_presub26_reg <= mode6_outp_presub26;
      mode6_outp_presub27_reg <= mode6_outp_presub27;
      mode6_outp_presub28_reg <= mode6_outp_presub28;
      mode6_outp_presub29_reg <= mode6_outp_presub29;
      mode6_outp_presub30_reg <= mode6_outp_presub30;
      mode6_outp_presub31_reg <= mode6_outp_presub31;
    end
  end

  //////------mode6 logsub ---------///////
  wire [`DATAWIDTH-1:0] mode6_outp_logsub0;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub1;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub2;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub3;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub4;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub5;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub6;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub7;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub8;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub9;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub10;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub11;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub12;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub13;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub14;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub15;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub16;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub17;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub18;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub19;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub20;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub21;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub22;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub23;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub24;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub25;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub26;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub27;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub28;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub29;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub30;
  wire [`DATAWIDTH-1:0] mode6_outp_logsub31;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub0_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub1_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub2_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub3_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub4_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub5_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub6_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub7_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub8_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub9_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub10_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub11_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub12_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub13_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub14_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub15_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub16_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub17_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub18_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub19_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub20_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub21_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub22_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub23_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub24_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub25_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub26_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub27_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub28_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub29_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub30_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub31_reg;

  mode6_sub log_sub(
      .a_inp0(mode6_outp_presub0_reg),
      .a_inp1(mode6_outp_presub1_reg),
      .a_inp2(mode6_outp_presub2_reg),
      .a_inp3(mode6_outp_presub3_reg),
      .a_inp4(mode6_outp_presub4_reg),
      .a_inp5(mode6_outp_presub5_reg),
      .a_inp6(mode6_outp_presub6_reg),
      .a_inp7(mode6_outp_presub7_reg),
      .a_inp8(mode6_outp_presub8_reg),
      .a_inp9(mode6_outp_presub9_reg),
      .a_inp10(mode6_outp_presub10_reg),
      .a_inp11(mode6_outp_presub11_reg),
      .a_inp12(mode6_outp_presub12_reg),
      .a_inp13(mode6_outp_presub13_reg),
      .a_inp14(mode6_outp_presub14_reg),
      .a_inp15(mode6_outp_presub15_reg),
      .a_inp16(mode6_outp_presub16_reg),
      .a_inp17(mode6_outp_presub17_reg),
      .a_inp18(mode6_outp_presub18_reg),
      .a_inp19(mode6_outp_presub19_reg),
      .a_inp20(mode6_outp_presub20_reg),
      .a_inp21(mode6_outp_presub21_reg),
      .a_inp22(mode6_outp_presub22_reg),
      .a_inp23(mode6_outp_presub23_reg),
      .a_inp24(mode6_outp_presub24_reg),
      .a_inp25(mode6_outp_presub25_reg),
      .a_inp26(mode6_outp_presub26_reg),
      .a_inp27(mode6_outp_presub27_reg),
      .a_inp28(mode6_outp_presub28_reg),
      .a_inp29(mode6_outp_presub29_reg),
      .a_inp30(mode6_outp_presub30_reg),
      .a_inp31(mode6_outp_presub31_reg),
      .b_inp(mode5_outp_log_reg),
      .outp0(mode6_outp_logsub0),
      .outp1(mode6_outp_logsub1),
      .outp2(mode6_outp_logsub2),
      .outp3(mode6_outp_logsub3),
      .outp4(mode6_outp_logsub4),
      .outp5(mode6_outp_logsub5),
      .outp6(mode6_outp_logsub6),
      .outp7(mode6_outp_logsub7),
      .outp8(mode6_outp_logsub8),
      .outp9(mode6_outp_logsub9),
      .outp10(mode6_outp_logsub10),
      .outp11(mode6_outp_logsub11),
      .outp12(mode6_outp_logsub12),
      .outp13(mode6_outp_logsub13),
      .outp14(mode6_outp_logsub14),
      .outp15(mode6_outp_logsub15),
      .outp16(mode6_outp_logsub16),
      .outp17(mode6_outp_logsub17),
      .outp18(mode6_outp_logsub18),
      .outp19(mode6_outp_logsub19),
      .outp20(mode6_outp_logsub20),
      .outp21(mode6_outp_logsub21),
      .outp22(mode6_outp_logsub22),
      .outp23(mode6_outp_logsub23),
      .outp24(mode6_outp_logsub24),
      .outp25(mode6_outp_logsub25),
      .outp26(mode6_outp_logsub26),
      .outp27(mode6_outp_logsub27),
      .outp28(mode6_outp_logsub28),
      .outp29(mode6_outp_logsub29),
      .outp30(mode6_outp_logsub30),
      .outp31(mode6_outp_logsub31)
  );
  always @(posedge clk) begin
    if (reset) begin
      mode6_outp_logsub0_reg <= 0;
      mode6_outp_logsub1_reg <= 0;
      mode6_outp_logsub2_reg <= 0;
      mode6_outp_logsub3_reg <= 0;
      mode6_outp_logsub4_reg <= 0;
      mode6_outp_logsub5_reg <= 0;
      mode6_outp_logsub6_reg <= 0;
      mode6_outp_logsub7_reg <= 0;
      mode6_outp_logsub8_reg <= 0;
      mode6_outp_logsub9_reg <= 0;
      mode6_outp_logsub10_reg <= 0;
      mode6_outp_logsub11_reg <= 0;
      mode6_outp_logsub12_reg <= 0;
      mode6_outp_logsub13_reg <= 0;
      mode6_outp_logsub14_reg <= 0;
      mode6_outp_logsub15_reg <= 0;
      mode6_outp_logsub16_reg <= 0;
      mode6_outp_logsub17_reg <= 0;
      mode6_outp_logsub18_reg <= 0;
      mode6_outp_logsub19_reg <= 0;
      mode6_outp_logsub20_reg <= 0;
      mode6_outp_logsub21_reg <= 0;
      mode6_outp_logsub22_reg <= 0;
      mode6_outp_logsub23_reg <= 0;
      mode6_outp_logsub24_reg <= 0;
      mode6_outp_logsub25_reg <= 0;
      mode6_outp_logsub26_reg <= 0;
      mode6_outp_logsub27_reg <= 0;
      mode6_outp_logsub28_reg <= 0;
      mode6_outp_logsub29_reg <= 0;
      mode6_outp_logsub30_reg <= 0;
      mode6_outp_logsub31_reg <= 0;
    end else if (mode6_run) begin
      mode6_outp_logsub0_reg <= mode6_outp_logsub0;
      mode6_outp_logsub1_reg <= mode6_outp_logsub1;
      mode6_outp_logsub2_reg <= mode6_outp_logsub2;
      mode6_outp_logsub3_reg <= mode6_outp_logsub3;
      mode6_outp_logsub4_reg <= mode6_outp_logsub4;
      mode6_outp_logsub5_reg <= mode6_outp_logsub5;
      mode6_outp_logsub6_reg <= mode6_outp_logsub6;
      mode6_outp_logsub7_reg <= mode6_outp_logsub7;
      mode6_outp_logsub8_reg <= mode6_outp_logsub8;
      mode6_outp_logsub9_reg <= mode6_outp_logsub9;
      mode6_outp_logsub10_reg <= mode6_outp_logsub10;
      mode6_outp_logsub11_reg <= mode6_outp_logsub11;
      mode6_outp_logsub12_reg <= mode6_outp_logsub12;
      mode6_outp_logsub13_reg <= mode6_outp_logsub13;
      mode6_outp_logsub14_reg <= mode6_outp_logsub14;
      mode6_outp_logsub15_reg <= mode6_outp_logsub15;
      mode6_outp_logsub16_reg <= mode6_outp_logsub16;
      mode6_outp_logsub17_reg <= mode6_outp_logsub17;
      mode6_outp_logsub18_reg <= mode6_outp_logsub18;
      mode6_outp_logsub19_reg <= mode6_outp_logsub19;
      mode6_outp_logsub20_reg <= mode6_outp_logsub20;
      mode6_outp_logsub21_reg <= mode6_outp_logsub21;
      mode6_outp_logsub22_reg <= mode6_outp_logsub22;
      mode6_outp_logsub23_reg <= mode6_outp_logsub23;
      mode6_outp_logsub24_reg <= mode6_outp_logsub24;
      mode6_outp_logsub25_reg <= mode6_outp_logsub25;
      mode6_outp_logsub26_reg <= mode6_outp_logsub26;
      mode6_outp_logsub27_reg <= mode6_outp_logsub27;
      mode6_outp_logsub28_reg <= mode6_outp_logsub28;
      mode6_outp_logsub29_reg <= mode6_outp_logsub29;
      mode6_outp_logsub30_reg <= mode6_outp_logsub30;
      mode6_outp_logsub31_reg <= mode6_outp_logsub31;
    end
  end

  //////------mode7 exp---------///////
  wire [`DATAWIDTH-1:0] outp0_temp;
  wire [`DATAWIDTH-1:0] outp1_temp;
  wire [`DATAWIDTH-1:0] outp2_temp;
  wire [`DATAWIDTH-1:0] outp3_temp;
  wire [`DATAWIDTH-1:0] outp4_temp;
  wire [`DATAWIDTH-1:0] outp5_temp;
  wire [`DATAWIDTH-1:0] outp6_temp;
  wire [`DATAWIDTH-1:0] outp7_temp;
  wire [`DATAWIDTH-1:0] outp8_temp;
  wire [`DATAWIDTH-1:0] outp9_temp;
  wire [`DATAWIDTH-1:0] outp10_temp;
  wire [`DATAWIDTH-1:0] outp11_temp;
  wire [`DATAWIDTH-1:0] outp12_temp;
  wire [`DATAWIDTH-1:0] outp13_temp;
  wire [`DATAWIDTH-1:0] outp14_temp;
  wire [`DATAWIDTH-1:0] outp15_temp;
  wire [`DATAWIDTH-1:0] outp16_temp;
  wire [`DATAWIDTH-1:0] outp17_temp;
  wire [`DATAWIDTH-1:0] outp18_temp;
  wire [`DATAWIDTH-1:0] outp19_temp;
  wire [`DATAWIDTH-1:0] outp20_temp;
  wire [`DATAWIDTH-1:0] outp21_temp;
  wire [`DATAWIDTH-1:0] outp22_temp;
  wire [`DATAWIDTH-1:0] outp23_temp;
  wire [`DATAWIDTH-1:0] outp24_temp;
  wire [`DATAWIDTH-1:0] outp25_temp;
  wire [`DATAWIDTH-1:0] outp26_temp;
  wire [`DATAWIDTH-1:0] outp27_temp;
  wire [`DATAWIDTH-1:0] outp28_temp;
  wire [`DATAWIDTH-1:0] outp29_temp;
  wire [`DATAWIDTH-1:0] outp30_temp;
  wire [`DATAWIDTH-1:0] outp31_temp;
  reg [`DATAWIDTH-1:0] outp0;
  reg [`DATAWIDTH-1:0] outp1;
  reg [`DATAWIDTH-1:0] outp2;
  reg [`DATAWIDTH-1:0] outp3;
  reg [`DATAWIDTH-1:0] outp4;
  reg [`DATAWIDTH-1:0] outp5;
  reg [`DATAWIDTH-1:0] outp6;
  reg [`DATAWIDTH-1:0] outp7;
  reg [`DATAWIDTH-1:0] outp8;
  reg [`DATAWIDTH-1:0] outp9;
  reg [`DATAWIDTH-1:0] outp10;
  reg [`DATAWIDTH-1:0] outp11;
  reg [`DATAWIDTH-1:0] outp12;
  reg [`DATAWIDTH-1:0] outp13;
  reg [`DATAWIDTH-1:0] outp14;
  reg [`DATAWIDTH-1:0] outp15;
  reg [`DATAWIDTH-1:0] outp16;
  reg [`DATAWIDTH-1:0] outp17;
  reg [`DATAWIDTH-1:0] outp18;
  reg [`DATAWIDTH-1:0] outp19;
  reg [`DATAWIDTH-1:0] outp20;
  reg [`DATAWIDTH-1:0] outp21;
  reg [`DATAWIDTH-1:0] outp22;
  reg [`DATAWIDTH-1:0] outp23;
  reg [`DATAWIDTH-1:0] outp24;
  reg [`DATAWIDTH-1:0] outp25;
  reg [`DATAWIDTH-1:0] outp26;
  reg [`DATAWIDTH-1:0] outp27;
  reg [`DATAWIDTH-1:0] outp28;
  reg [`DATAWIDTH-1:0] outp29;
  reg [`DATAWIDTH-1:0] outp30;
  reg [`DATAWIDTH-1:0] outp31;

  mode7_exp mode7_exp(
      .inp0(mode6_outp_logsub0_reg),
      .inp1(mode6_outp_logsub1_reg),
      .inp2(mode6_outp_logsub2_reg),
      .inp3(mode6_outp_logsub3_reg),
      .inp4(mode6_outp_logsub4_reg),
      .inp5(mode6_outp_logsub5_reg),
      .inp6(mode6_outp_logsub6_reg),
      .inp7(mode6_outp_logsub7_reg),
      .inp8(mode6_outp_logsub8_reg),
      .inp9(mode6_outp_logsub9_reg),
      .inp10(mode6_outp_logsub10_reg),
      .inp11(mode6_outp_logsub11_reg),
      .inp12(mode6_outp_logsub12_reg),
      .inp13(mode6_outp_logsub13_reg),
      .inp14(mode6_outp_logsub14_reg),
      .inp15(mode6_outp_logsub15_reg),
      .inp16(mode6_outp_logsub16_reg),
      .inp17(mode6_outp_logsub17_reg),
      .inp18(mode6_outp_logsub18_reg),
      .inp19(mode6_outp_logsub19_reg),
      .inp20(mode6_outp_logsub20_reg),
      .inp21(mode6_outp_logsub21_reg),
      .inp22(mode6_outp_logsub22_reg),
      .inp23(mode6_outp_logsub23_reg),
      .inp24(mode6_outp_logsub24_reg),
      .inp25(mode6_outp_logsub25_reg),
      .inp26(mode6_outp_logsub26_reg),
      .inp27(mode6_outp_logsub27_reg),
      .inp28(mode6_outp_logsub28_reg),
      .inp29(mode6_outp_logsub29_reg),
      .inp30(mode6_outp_logsub30_reg),
      .inp31(mode6_outp_logsub31_reg),

      .clk(clk),
      .reset(reset),
      .stage_run(mode7_stage_run),

      .outp0(outp0_temp),
      .outp1(outp1_temp),
      .outp2(outp2_temp),
      .outp3(outp3_temp),
      .outp4(outp4_temp),
      .outp5(outp5_temp),
      .outp6(outp6_temp),
      .outp7(outp7_temp),
      .outp8(outp8_temp),
      .outp9(outp9_temp),
      .outp10(outp10_temp),
      .outp11(outp11_temp),
      .outp12(outp12_temp),
      .outp13(outp13_temp),
      .outp14(outp14_temp),
      .outp15(outp15_temp),
      .outp16(outp16_temp),
      .outp17(outp17_temp),
      .outp18(outp18_temp),
      .outp19(outp19_temp),
      .outp20(outp20_temp),
      .outp21(outp21_temp),
      .outp22(outp22_temp),
      .outp23(outp23_temp),
      .outp24(outp24_temp),
      .outp25(outp25_temp),
      .outp26(outp26_temp),
      .outp27(outp27_temp),
      .outp28(outp28_temp),
      .outp29(outp29_temp),
      .outp30(outp30_temp),
      .outp31(outp31_temp)
  );
  always @(posedge clk) begin
    if (reset) begin
      outp0 <= 0;
      outp1 <= 0;
      outp2 <= 0;
      outp3 <= 0;
      outp4 <= 0;
      outp5 <= 0;
      outp6 <= 0;
      outp7 <= 0;
      outp8 <= 0;
      outp9 <= 0;
      outp10 <= 0;
      outp11 <= 0;
      outp12 <= 0;
      outp13 <= 0;
      outp14 <= 0;
      outp15 <= 0;
      outp16 <= 0;
      outp17 <= 0;
      outp18 <= 0;
      outp19 <= 0;
      outp20 <= 0;
      outp21 <= 0;
      outp22 <= 0;
      outp23 <= 0;
      outp24 <= 0;
      outp25 <= 0;
      outp26 <= 0;
      outp27 <= 0;
      outp28 <= 0;
      outp29 <= 0;
      outp30 <= 0;
      outp31 <= 0;
    end else if (mode7_run) begin
      outp0 <= outp0_temp;
      outp1 <= outp1_temp;
      outp2 <= outp2_temp;
      outp3 <= outp3_temp;
      outp4 <= outp4_temp;
      outp5 <= outp5_temp;
      outp6 <= outp6_temp;
      outp7 <= outp7_temp;
      outp8 <= outp8_temp;
      outp9 <= outp9_temp;
      outp10 <= outp10_temp;
      outp11 <= outp11_temp;
      outp12 <= outp12_temp;
      outp13 <= outp13_temp;
      outp14 <= outp14_temp;
      outp15 <= outp15_temp;
      outp16 <= outp16_temp;
      outp17 <= outp17_temp;
      outp18 <= outp18_temp;
      outp19 <= outp19_temp;
      outp20 <= outp20_temp;
      outp21 <= outp21_temp;
      outp22 <= outp22_temp;
      outp23 <= outp23_temp;
      outp24 <= outp24_temp;
      outp25 <= outp25_temp;
      outp26 <= outp26_temp;
      outp27 <= outp27_temp;
      outp28 <= outp28_temp;
      outp29 <= outp29_temp;
      outp30 <= outp30_temp;
      outp31 <= outp31_temp;
    end
  end

endmodule


module mode1_max_tree(
  inp0, 
  inp1, 
  inp2, 
  inp3, 
  inp4, 
  inp5, 
  inp6, 
  inp7, 
  inp8, 
  inp9, 
  inp10, 
  inp11, 
  inp12, 
  inp13, 
  inp14, 
  inp15, 
  inp16, 
  inp17, 
  inp18, 
  inp19, 
  inp20, 
  inp21, 
  inp22, 
  inp23, 
  inp24, 
  inp25, 
  inp26, 
  inp27, 
  inp28, 
  inp29, 
  inp30, 
  inp31, 

  outp,

  mode1_stage3_run,
  mode1_stage0_run,
  clk,
  reset
);
  input clk;
  input reset;
  input mode1_stage0_run;
  input mode1_stage3_run;

  input  [`DATAWIDTH-1 : 0] inp0; 
  input  [`DATAWIDTH-1 : 0] inp1; 
  input  [`DATAWIDTH-1 : 0] inp2; 
  input  [`DATAWIDTH-1 : 0] inp3; 
  input  [`DATAWIDTH-1 : 0] inp4; 
  input  [`DATAWIDTH-1 : 0] inp5; 
  input  [`DATAWIDTH-1 : 0] inp6; 
  input  [`DATAWIDTH-1 : 0] inp7; 
  input  [`DATAWIDTH-1 : 0] inp8; 
  input  [`DATAWIDTH-1 : 0] inp9; 
  input  [`DATAWIDTH-1 : 0] inp10; 
  input  [`DATAWIDTH-1 : 0] inp11; 
  input  [`DATAWIDTH-1 : 0] inp12; 
  input  [`DATAWIDTH-1 : 0] inp13; 
  input  [`DATAWIDTH-1 : 0] inp14; 
  input  [`DATAWIDTH-1 : 0] inp15; 
  input  [`DATAWIDTH-1 : 0] inp16; 
  input  [`DATAWIDTH-1 : 0] inp17; 
  input  [`DATAWIDTH-1 : 0] inp18; 
  input  [`DATAWIDTH-1 : 0] inp19; 
  input  [`DATAWIDTH-1 : 0] inp20; 
  input  [`DATAWIDTH-1 : 0] inp21; 
  input  [`DATAWIDTH-1 : 0] inp22; 
  input  [`DATAWIDTH-1 : 0] inp23; 
  input  [`DATAWIDTH-1 : 0] inp24; 
  input  [`DATAWIDTH-1 : 0] inp25; 
  input  [`DATAWIDTH-1 : 0] inp26; 
  input  [`DATAWIDTH-1 : 0] inp27; 
  input  [`DATAWIDTH-1 : 0] inp28; 
  input  [`DATAWIDTH-1 : 0] inp29; 
  input  [`DATAWIDTH-1 : 0] inp30; 
  input  [`DATAWIDTH-1 : 0] inp31; 

  output [`DATAWIDTH-1 : 0] outp;
  reg    [`DATAWIDTH-1 : 0] outp;

  wire   [`DATAWIDTH-1 : 0] cmp0_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp1_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp2_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp3_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp4_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp5_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp6_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp7_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp8_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp9_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp10_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp11_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp12_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp13_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp14_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp15_out_stage5;
  wire   [`DATAWIDTH-1 : 0] cmp0_out_stage4;
  wire   [`DATAWIDTH-1 : 0] cmp1_out_stage4;
  wire   [`DATAWIDTH-1 : 0] cmp2_out_stage4;
  wire   [`DATAWIDTH-1 : 0] cmp3_out_stage4;
  wire   [`DATAWIDTH-1 : 0] cmp4_out_stage4;
  wire   [`DATAWIDTH-1 : 0] cmp5_out_stage4;
  wire   [`DATAWIDTH-1 : 0] cmp6_out_stage4;
  wire   [`DATAWIDTH-1 : 0] cmp7_out_stage4;
  reg    [`DATAWIDTH-1 : 0] cmp0_out_stage3_reg;
  wire   [`DATAWIDTH-1 : 0] cmp0_out_stage3;
  reg    [`DATAWIDTH-1 : 0] cmp1_out_stage3_reg;
  wire   [`DATAWIDTH-1 : 0] cmp1_out_stage3;
  reg    [`DATAWIDTH-1 : 0] cmp2_out_stage3_reg;
  wire   [`DATAWIDTH-1 : 0] cmp2_out_stage3;
  reg    [`DATAWIDTH-1 : 0] cmp3_out_stage3_reg;
  wire   [`DATAWIDTH-1 : 0] cmp3_out_stage3;
  wire   [`DATAWIDTH-1 : 0] cmp0_out_stage2;
  wire   [`DATAWIDTH-1 : 0] cmp1_out_stage2;
  wire   [`DATAWIDTH-1 : 0] cmp0_out_stage1;
  wire   [`DATAWIDTH-1 : 0] cmp0_out_stage0;

  always @(posedge clk) begin
    if (reset) begin
      outp <= 0;
      cmp0_out_stage3_reg <= 0;
      cmp1_out_stage3_reg <= 0;
      cmp2_out_stage3_reg <= 0;
      cmp3_out_stage3_reg <= 0;
    end

    if(~reset && mode1_stage3_run) begin
      cmp0_out_stage3_reg <= cmp0_out_stage3;
      cmp1_out_stage3_reg <= cmp1_out_stage3;
      cmp2_out_stage3_reg <= cmp2_out_stage3;
      cmp3_out_stage3_reg <= cmp3_out_stage3;
    end

    if(~reset && mode1_stage0_run) begin
      outp <= cmp0_out_stage0;
    end

  end

DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage5(.a(inp0),       .b(inp1),      .z1(cmp0_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp1_stage5(.a(inp2),       .b(inp3),      .z1(cmp1_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp2_stage5(.a(inp4),       .b(inp5),      .z1(cmp2_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp3_stage5(.a(inp6),       .b(inp7),      .z1(cmp3_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp4_stage5(.a(inp8),       .b(inp9),      .z1(cmp4_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp5_stage5(.a(inp10),       .b(inp11),      .z1(cmp5_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp6_stage5(.a(inp12),       .b(inp13),      .z1(cmp6_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp7_stage5(.a(inp14),       .b(inp15),      .z1(cmp7_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp8_stage5(.a(inp16),       .b(inp17),      .z1(cmp8_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp9_stage5(.a(inp18),       .b(inp19),      .z1(cmp9_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp10_stage5(.a(inp20),       .b(inp21),      .z1(cmp10_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp11_stage5(.a(inp22),       .b(inp23),      .z1(cmp11_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp12_stage5(.a(inp24),       .b(inp25),      .z1(cmp12_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp13_stage5(.a(inp26),       .b(inp27),      .z1(cmp13_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp14_stage5(.a(inp28),       .b(inp29),      .z1(cmp14_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp15_stage5(.a(inp30),       .b(inp31),      .z1(cmp15_out_stage5), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());

DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage4(.a(cmp0_out_stage5),       .b(cmp1_out_stage5),      .z1(cmp0_out_stage4), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp1_stage4(.a(cmp2_out_stage5),       .b(cmp3_out_stage5),      .z1(cmp1_out_stage4), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp2_stage4(.a(cmp4_out_stage5),       .b(cmp5_out_stage5),      .z1(cmp2_out_stage4), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp3_stage4(.a(cmp6_out_stage5),       .b(cmp7_out_stage5),      .z1(cmp3_out_stage4), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp4_stage4(.a(cmp8_out_stage5),       .b(cmp9_out_stage5),      .z1(cmp4_out_stage4), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp5_stage4(.a(cmp10_out_stage5),       .b(cmp11_out_stage5),      .z1(cmp5_out_stage4), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp6_stage4(.a(cmp12_out_stage5),       .b(cmp13_out_stage5),      .z1(cmp6_out_stage4), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp7_stage4(.a(cmp14_out_stage5),       .b(cmp15_out_stage5),      .z1(cmp7_out_stage4), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());

DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage3(.a(cmp0_out_stage4),       .b(cmp1_out_stage4),      .z1(cmp0_out_stage3), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp1_stage3(.a(cmp2_out_stage4),       .b(cmp3_out_stage4),      .z1(cmp1_out_stage3), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp2_stage3(.a(cmp4_out_stage4),       .b(cmp5_out_stage4),      .z1(cmp2_out_stage3), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp3_stage3(.a(cmp6_out_stage4),       .b(cmp7_out_stage4),      .z1(cmp3_out_stage3), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());

DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage2(.a(cmp0_out_stage3_reg),       .b(cmp1_out_stage3_reg),      .z1(cmp0_out_stage2), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp1_stage2(.a(cmp2_out_stage3_reg),       .b(cmp3_out_stage3_reg),      .z1(cmp1_out_stage2), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());

DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage1(.a(cmp0_out_stage2),       .b(cmp1_out_stage2),      .z1(cmp0_out_stage1), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());

DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage0(.a(outp),       .b(cmp0_out_stage1),      .z1(cmp0_out_stage0), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());

endmodule


module mode2_sub(
  a_inp0,
  a_inp1,
  a_inp2,
  a_inp3,
  a_inp4,
  a_inp5,
  a_inp6,
  a_inp7,
  a_inp8,
  a_inp9,
  a_inp10,
  a_inp11,
  a_inp12,
  a_inp13,
  a_inp14,
  a_inp15,
  a_inp16,
  a_inp17,
  a_inp18,
  a_inp19,
  a_inp20,
  a_inp21,
  a_inp22,
  a_inp23,
  a_inp24,
  a_inp25,
  a_inp26,
  a_inp27,
  a_inp28,
  a_inp29,
  a_inp30,
  a_inp31,
  b_inp,
  outp0,
  outp1,
  outp2,
  outp3,
  outp4,
  outp5,
  outp6,
  outp7,
  outp8,
  outp9,
  outp10,
  outp11,
  outp12,
  outp13,
  outp14,
  outp15,
  outp16,
  outp17,
  outp18,
  outp19,
  outp20,
  outp21,
  outp22,
  outp23,
  outp24,
  outp25,
  outp26,
  outp27,
  outp28,
  outp29,
  outp30,
  outp31
);

  input  [`DATAWIDTH-1 : 0] a_inp0;
  input  [`DATAWIDTH-1 : 0] a_inp1;
  input  [`DATAWIDTH-1 : 0] a_inp2;
  input  [`DATAWIDTH-1 : 0] a_inp3;
  input  [`DATAWIDTH-1 : 0] a_inp4;
  input  [`DATAWIDTH-1 : 0] a_inp5;
  input  [`DATAWIDTH-1 : 0] a_inp6;
  input  [`DATAWIDTH-1 : 0] a_inp7;
  input  [`DATAWIDTH-1 : 0] a_inp8;
  input  [`DATAWIDTH-1 : 0] a_inp9;
  input  [`DATAWIDTH-1 : 0] a_inp10;
  input  [`DATAWIDTH-1 : 0] a_inp11;
  input  [`DATAWIDTH-1 : 0] a_inp12;
  input  [`DATAWIDTH-1 : 0] a_inp13;
  input  [`DATAWIDTH-1 : 0] a_inp14;
  input  [`DATAWIDTH-1 : 0] a_inp15;
  input  [`DATAWIDTH-1 : 0] a_inp16;
  input  [`DATAWIDTH-1 : 0] a_inp17;
  input  [`DATAWIDTH-1 : 0] a_inp18;
  input  [`DATAWIDTH-1 : 0] a_inp19;
  input  [`DATAWIDTH-1 : 0] a_inp20;
  input  [`DATAWIDTH-1 : 0] a_inp21;
  input  [`DATAWIDTH-1 : 0] a_inp22;
  input  [`DATAWIDTH-1 : 0] a_inp23;
  input  [`DATAWIDTH-1 : 0] a_inp24;
  input  [`DATAWIDTH-1 : 0] a_inp25;
  input  [`DATAWIDTH-1 : 0] a_inp26;
  input  [`DATAWIDTH-1 : 0] a_inp27;
  input  [`DATAWIDTH-1 : 0] a_inp28;
  input  [`DATAWIDTH-1 : 0] a_inp29;
  input  [`DATAWIDTH-1 : 0] a_inp30;
  input  [`DATAWIDTH-1 : 0] a_inp31;
  input  [`DATAWIDTH-1 : 0] b_inp;
  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  output  [`DATAWIDTH-1 : 0] outp4;
  output  [`DATAWIDTH-1 : 0] outp5;
  output  [`DATAWIDTH-1 : 0] outp6;
  output  [`DATAWIDTH-1 : 0] outp7;
  output  [`DATAWIDTH-1 : 0] outp8;
  output  [`DATAWIDTH-1 : 0] outp9;
  output  [`DATAWIDTH-1 : 0] outp10;
  output  [`DATAWIDTH-1 : 0] outp11;
  output  [`DATAWIDTH-1 : 0] outp12;
  output  [`DATAWIDTH-1 : 0] outp13;
  output  [`DATAWIDTH-1 : 0] outp14;
  output  [`DATAWIDTH-1 : 0] outp15;
  output  [`DATAWIDTH-1 : 0] outp16;
  output  [`DATAWIDTH-1 : 0] outp17;
  output  [`DATAWIDTH-1 : 0] outp18;
  output  [`DATAWIDTH-1 : 0] outp19;
  output  [`DATAWIDTH-1 : 0] outp20;
  output  [`DATAWIDTH-1 : 0] outp21;
  output  [`DATAWIDTH-1 : 0] outp22;
  output  [`DATAWIDTH-1 : 0] outp23;
  output  [`DATAWIDTH-1 : 0] outp24;
  output  [`DATAWIDTH-1 : 0] outp25;
  output  [`DATAWIDTH-1 : 0] outp26;
  output  [`DATAWIDTH-1 : 0] outp27;
  output  [`DATAWIDTH-1 : 0] outp28;
  output  [`DATAWIDTH-1 : 0] outp29;
  output  [`DATAWIDTH-1 : 0] outp30;
  output  [`DATAWIDTH-1 : 0] outp31;
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub0(.a(a_inp0), .b(b_inp), .z(outp0), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub1(.a(a_inp1), .b(b_inp), .z(outp1), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub2(.a(a_inp2), .b(b_inp), .z(outp2), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub3(.a(a_inp3), .b(b_inp), .z(outp3), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub4(.a(a_inp4), .b(b_inp), .z(outp4), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub5(.a(a_inp5), .b(b_inp), .z(outp5), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub6(.a(a_inp6), .b(b_inp), .z(outp6), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub7(.a(a_inp7), .b(b_inp), .z(outp7), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub8(.a(a_inp8), .b(b_inp), .z(outp8), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub9(.a(a_inp9), .b(b_inp), .z(outp9), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub10(.a(a_inp10), .b(b_inp), .z(outp10), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub11(.a(a_inp11), .b(b_inp), .z(outp11), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub12(.a(a_inp12), .b(b_inp), .z(outp12), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub13(.a(a_inp13), .b(b_inp), .z(outp13), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub14(.a(a_inp14), .b(b_inp), .z(outp14), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub15(.a(a_inp15), .b(b_inp), .z(outp15), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub16(.a(a_inp16), .b(b_inp), .z(outp16), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub17(.a(a_inp17), .b(b_inp), .z(outp17), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub18(.a(a_inp18), .b(b_inp), .z(outp18), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub19(.a(a_inp19), .b(b_inp), .z(outp19), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub20(.a(a_inp20), .b(b_inp), .z(outp20), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub21(.a(a_inp21), .b(b_inp), .z(outp21), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub22(.a(a_inp22), .b(b_inp), .z(outp22), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub23(.a(a_inp23), .b(b_inp), .z(outp23), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub24(.a(a_inp24), .b(b_inp), .z(outp24), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub25(.a(a_inp25), .b(b_inp), .z(outp25), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub26(.a(a_inp26), .b(b_inp), .z(outp26), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub27(.a(a_inp27), .b(b_inp), .z(outp27), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub28(.a(a_inp28), .b(b_inp), .z(outp28), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub29(.a(a_inp29), .b(b_inp), .z(outp29), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub30(.a(a_inp30), .b(b_inp), .z(outp30), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub31(.a(a_inp31), .b(b_inp), .z(outp31), .rnd(3'b000), .status());
endmodule


module mode3_exp(
  inp0, 
  inp1, 
  inp2, 
  inp3, 
  inp4, 
  inp5, 
  inp6, 
  inp7, 
  inp8, 
  inp9, 
  inp10, 
  inp11, 
  inp12, 
  inp13, 
  inp14, 
  inp15, 
  inp16, 
  inp17, 
  inp18, 
  inp19, 
  inp20, 
  inp21, 
  inp22, 
  inp23, 
  inp24, 
  inp25, 
  inp26, 
  inp27, 
  inp28, 
  inp29, 
  inp30, 
  inp31, 

  clk,
  reset,
  stage_run,

  outp0, 
  outp1, 
  outp2, 
  outp3, 
  outp4, 
  outp5, 
  outp6, 
  outp7, 
  outp8, 
  outp9, 
  outp10, 
  outp11, 
  outp12, 
  outp13, 
  outp14, 
  outp15, 
  outp16, 
  outp17, 
  outp18, 
  outp19, 
  outp20, 
  outp21, 
  outp22, 
  outp23, 
  outp24, 
  outp25, 
  outp26, 
  outp27, 
  outp28, 
  outp29, 
  outp30, 
  outp31
);

  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;
  input  [`DATAWIDTH-1 : 0] inp4;
  input  [`DATAWIDTH-1 : 0] inp5;
  input  [`DATAWIDTH-1 : 0] inp6;
  input  [`DATAWIDTH-1 : 0] inp7;
  input  [`DATAWIDTH-1 : 0] inp8;
  input  [`DATAWIDTH-1 : 0] inp9;
  input  [`DATAWIDTH-1 : 0] inp10;
  input  [`DATAWIDTH-1 : 0] inp11;
  input  [`DATAWIDTH-1 : 0] inp12;
  input  [`DATAWIDTH-1 : 0] inp13;
  input  [`DATAWIDTH-1 : 0] inp14;
  input  [`DATAWIDTH-1 : 0] inp15;
  input  [`DATAWIDTH-1 : 0] inp16;
  input  [`DATAWIDTH-1 : 0] inp17;
  input  [`DATAWIDTH-1 : 0] inp18;
  input  [`DATAWIDTH-1 : 0] inp19;
  input  [`DATAWIDTH-1 : 0] inp20;
  input  [`DATAWIDTH-1 : 0] inp21;
  input  [`DATAWIDTH-1 : 0] inp22;
  input  [`DATAWIDTH-1 : 0] inp23;
  input  [`DATAWIDTH-1 : 0] inp24;
  input  [`DATAWIDTH-1 : 0] inp25;
  input  [`DATAWIDTH-1 : 0] inp26;
  input  [`DATAWIDTH-1 : 0] inp27;
  input  [`DATAWIDTH-1 : 0] inp28;
  input  [`DATAWIDTH-1 : 0] inp29;
  input  [`DATAWIDTH-1 : 0] inp30;
  input  [`DATAWIDTH-1 : 0] inp31;

  input  clk;
  input  reset;
  input  stage_run;

  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  output  [`DATAWIDTH-1 : 0] outp4;
  output  [`DATAWIDTH-1 : 0] outp5;
  output  [`DATAWIDTH-1 : 0] outp6;
  output  [`DATAWIDTH-1 : 0] outp7;
  output  [`DATAWIDTH-1 : 0] outp8;
  output  [`DATAWIDTH-1 : 0] outp9;
  output  [`DATAWIDTH-1 : 0] outp10;
  output  [`DATAWIDTH-1 : 0] outp11;
  output  [`DATAWIDTH-1 : 0] outp12;
  output  [`DATAWIDTH-1 : 0] outp13;
  output  [`DATAWIDTH-1 : 0] outp14;
  output  [`DATAWIDTH-1 : 0] outp15;
  output  [`DATAWIDTH-1 : 0] outp16;
  output  [`DATAWIDTH-1 : 0] outp17;
  output  [`DATAWIDTH-1 : 0] outp18;
  output  [`DATAWIDTH-1 : 0] outp19;
  output  [`DATAWIDTH-1 : 0] outp20;
  output  [`DATAWIDTH-1 : 0] outp21;
  output  [`DATAWIDTH-1 : 0] outp22;
  output  [`DATAWIDTH-1 : 0] outp23;
  output  [`DATAWIDTH-1 : 0] outp24;
  output  [`DATAWIDTH-1 : 0] outp25;
  output  [`DATAWIDTH-1 : 0] outp26;
  output  [`DATAWIDTH-1 : 0] outp27;
  output  [`DATAWIDTH-1 : 0] outp28;
  output  [`DATAWIDTH-1 : 0] outp29;
  output  [`DATAWIDTH-1 : 0] outp30;
  output  [`DATAWIDTH-1 : 0] outp31;
  expunit exp0(.a(inp0), .z(outp0), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp1(.a(inp1), .z(outp1), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp2(.a(inp2), .z(outp2), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp3(.a(inp3), .z(outp3), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp4(.a(inp4), .z(outp4), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp5(.a(inp5), .z(outp5), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp6(.a(inp6), .z(outp6), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp7(.a(inp7), .z(outp7), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp8(.a(inp8), .z(outp8), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp9(.a(inp9), .z(outp9), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp10(.a(inp10), .z(outp10), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp11(.a(inp11), .z(outp11), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp12(.a(inp12), .z(outp12), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp13(.a(inp13), .z(outp13), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp14(.a(inp14), .z(outp14), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp15(.a(inp15), .z(outp15), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp16(.a(inp16), .z(outp16), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp17(.a(inp17), .z(outp17), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp18(.a(inp18), .z(outp18), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp19(.a(inp19), .z(outp19), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp20(.a(inp20), .z(outp20), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp21(.a(inp21), .z(outp21), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp22(.a(inp22), .z(outp22), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp23(.a(inp23), .z(outp23), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp24(.a(inp24), .z(outp24), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp25(.a(inp25), .z(outp25), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp26(.a(inp26), .z(outp26), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp27(.a(inp27), .z(outp27), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp28(.a(inp28), .z(outp28), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp29(.a(inp29), .z(outp29), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp30(.a(inp30), .z(outp30), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp31(.a(inp31), .z(outp31), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
endmodule


module mode4_adder_tree(
  inp0, 
  inp1, 
  inp2, 
  inp3, 
  inp4, 
  inp5, 
  inp6, 
  inp7, 
  inp8, 
  inp9, 
  inp10, 
  inp11, 
  inp12, 
  inp13, 
  inp14, 
  inp15, 
  inp16, 
  inp17, 
  inp18, 
  inp19, 
  inp20, 
  inp21, 
  inp22, 
  inp23, 
  inp24, 
  inp25, 
  inp26, 
  inp27, 
  inp28, 
  inp29, 
  inp30, 
  inp31, 
  mode4_stage0_run,
  mode4_stage1_run,
  mode4_stage2_run,
  mode4_stage3_run,
  mode4_stage4_run,
  mode4_stage5_run,

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
  input  [`DATAWIDTH-1 : 0] inp4; 
  input  [`DATAWIDTH-1 : 0] inp5; 
  input  [`DATAWIDTH-1 : 0] inp6; 
  input  [`DATAWIDTH-1 : 0] inp7; 
  input  [`DATAWIDTH-1 : 0] inp8; 
  input  [`DATAWIDTH-1 : 0] inp9; 
  input  [`DATAWIDTH-1 : 0] inp10; 
  input  [`DATAWIDTH-1 : 0] inp11; 
  input  [`DATAWIDTH-1 : 0] inp12; 
  input  [`DATAWIDTH-1 : 0] inp13; 
  input  [`DATAWIDTH-1 : 0] inp14; 
  input  [`DATAWIDTH-1 : 0] inp15; 
  input  [`DATAWIDTH-1 : 0] inp16; 
  input  [`DATAWIDTH-1 : 0] inp17; 
  input  [`DATAWIDTH-1 : 0] inp18; 
  input  [`DATAWIDTH-1 : 0] inp19; 
  input  [`DATAWIDTH-1 : 0] inp20; 
  input  [`DATAWIDTH-1 : 0] inp21; 
  input  [`DATAWIDTH-1 : 0] inp22; 
  input  [`DATAWIDTH-1 : 0] inp23; 
  input  [`DATAWIDTH-1 : 0] inp24; 
  input  [`DATAWIDTH-1 : 0] inp25; 
  input  [`DATAWIDTH-1 : 0] inp26; 
  input  [`DATAWIDTH-1 : 0] inp27; 
  input  [`DATAWIDTH-1 : 0] inp28; 
  input  [`DATAWIDTH-1 : 0] inp29; 
  input  [`DATAWIDTH-1 : 0] inp30; 
  input  [`DATAWIDTH-1 : 0] inp31; 
  output [`DATAWIDTH-1 : 0] outp;
  input mode4_stage0_run;
  input mode4_stage1_run;
  input mode4_stage2_run;
  input mode4_stage3_run;
  input mode4_stage4_run;
  input mode4_stage5_run;

  wire   [`DATAWIDTH-1 : 0] add0_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add0_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add1_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add1_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add2_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add2_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add3_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add3_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add4_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add4_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add5_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add5_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add6_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add6_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add7_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add7_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add8_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add8_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add9_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add9_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add10_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add10_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add11_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add11_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add12_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add12_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add13_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add13_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add14_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add14_out_stage5_reg;
  wire   [`DATAWIDTH-1 : 0] add15_out_stage5;
  reg    [`DATAWIDTH-1 : 0] add15_out_stage5_reg;

  wire   [`DATAWIDTH-1 : 0] add0_out_stage4;
  reg    [`DATAWIDTH-1 : 0] add0_out_stage4_reg;
  wire   [`DATAWIDTH-1 : 0] add1_out_stage4;
  reg    [`DATAWIDTH-1 : 0] add1_out_stage4_reg;
  wire   [`DATAWIDTH-1 : 0] add2_out_stage4;
  reg    [`DATAWIDTH-1 : 0] add2_out_stage4_reg;
  wire   [`DATAWIDTH-1 : 0] add3_out_stage4;
  reg    [`DATAWIDTH-1 : 0] add3_out_stage4_reg;
  wire   [`DATAWIDTH-1 : 0] add4_out_stage4;
  reg    [`DATAWIDTH-1 : 0] add4_out_stage4_reg;
  wire   [`DATAWIDTH-1 : 0] add5_out_stage4;
  reg    [`DATAWIDTH-1 : 0] add5_out_stage4_reg;
  wire   [`DATAWIDTH-1 : 0] add6_out_stage4;
  reg    [`DATAWIDTH-1 : 0] add6_out_stage4_reg;
  wire   [`DATAWIDTH-1 : 0] add7_out_stage4;
  reg    [`DATAWIDTH-1 : 0] add7_out_stage4_reg;

  wire   [`DATAWIDTH-1 : 0] add0_out_stage3;
  reg    [`DATAWIDTH-1 : 0] add0_out_stage3_reg;
  wire   [`DATAWIDTH-1 : 0] add1_out_stage3;
  reg    [`DATAWIDTH-1 : 0] add1_out_stage3_reg;
  wire   [`DATAWIDTH-1 : 0] add2_out_stage3;
  reg    [`DATAWIDTH-1 : 0] add2_out_stage3_reg;
  wire   [`DATAWIDTH-1 : 0] add3_out_stage3;
  reg    [`DATAWIDTH-1 : 0] add3_out_stage3_reg;

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
      add0_out_stage5_reg <= 0;
      add1_out_stage5_reg <= 0;
      add2_out_stage5_reg <= 0;
      add3_out_stage5_reg <= 0;
      add4_out_stage5_reg <= 0;
      add5_out_stage5_reg <= 0;
      add6_out_stage5_reg <= 0;
      add7_out_stage5_reg <= 0;
      add8_out_stage5_reg <= 0;
      add9_out_stage5_reg <= 0;
      add10_out_stage5_reg <= 0;
      add11_out_stage5_reg <= 0;
      add12_out_stage5_reg <= 0;
      add13_out_stage5_reg <= 0;
      add14_out_stage5_reg <= 0;
      add15_out_stage5_reg <= 0;
      add0_out_stage4_reg <= 0;
      add1_out_stage4_reg <= 0;
      add2_out_stage4_reg <= 0;
      add3_out_stage4_reg <= 0;
      add4_out_stage4_reg <= 0;
      add5_out_stage4_reg <= 0;
      add6_out_stage4_reg <= 0;
      add7_out_stage4_reg <= 0;
      add0_out_stage3_reg <= 0;
      add1_out_stage3_reg <= 0;
      add2_out_stage3_reg <= 0;
      add3_out_stage3_reg <= 0;
      add0_out_stage2_reg <= 0;
      add1_out_stage2_reg <= 0;
      add0_out_stage1_reg <= 0;
    end

    if(~reset && mode4_stage5_run) begin
      add0_out_stage5_reg <= add0_out_stage5;
      add1_out_stage5_reg <= add1_out_stage5;
      add2_out_stage5_reg <= add2_out_stage5;
      add3_out_stage5_reg <= add3_out_stage5;
      add4_out_stage5_reg <= add4_out_stage5;
      add5_out_stage5_reg <= add5_out_stage5;
      add6_out_stage5_reg <= add6_out_stage5;
      add7_out_stage5_reg <= add7_out_stage5;
      add8_out_stage5_reg <= add8_out_stage5;
      add9_out_stage5_reg <= add9_out_stage5;
      add10_out_stage5_reg <= add10_out_stage5;
      add11_out_stage5_reg <= add11_out_stage5;
      add12_out_stage5_reg <= add12_out_stage5;
      add13_out_stage5_reg <= add13_out_stage5;
      add14_out_stage5_reg <= add14_out_stage5;
      add15_out_stage5_reg <= add15_out_stage5;
    end

    if(~reset && mode4_stage4_run) begin
      add0_out_stage4_reg <= add0_out_stage4;
      add1_out_stage4_reg <= add1_out_stage4;
      add2_out_stage4_reg <= add2_out_stage4;
      add3_out_stage4_reg <= add3_out_stage4;
      add4_out_stage4_reg <= add4_out_stage4;
      add5_out_stage4_reg <= add5_out_stage4;
      add6_out_stage4_reg <= add6_out_stage4;
      add7_out_stage4_reg <= add7_out_stage4;
    end

    if(~reset && mode4_stage3_run) begin
      add0_out_stage3_reg <= add0_out_stage3;
      add1_out_stage3_reg <= add1_out_stage3;
      add2_out_stage3_reg <= add2_out_stage3;
      add3_out_stage3_reg <= add3_out_stage3;
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
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage5(.a(inp0),       .b(inp1),      .z(add0_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add1_stage5(.a(inp2),       .b(inp3),      .z(add1_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add2_stage5(.a(inp4),       .b(inp5),      .z(add2_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add3_stage5(.a(inp6),       .b(inp7),      .z(add3_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add4_stage5(.a(inp8),       .b(inp9),      .z(add4_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add5_stage5(.a(inp10),       .b(inp11),      .z(add5_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add6_stage5(.a(inp12),       .b(inp13),      .z(add6_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add7_stage5(.a(inp14),       .b(inp15),      .z(add7_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add8_stage5(.a(inp16),       .b(inp17),      .z(add8_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add9_stage5(.a(inp18),       .b(inp19),      .z(add9_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add10_stage5(.a(inp20),       .b(inp21),      .z(add10_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add11_stage5(.a(inp22),       .b(inp23),      .z(add11_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add12_stage5(.a(inp24),       .b(inp25),      .z(add12_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add13_stage5(.a(inp26),       .b(inp27),      .z(add13_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add14_stage5(.a(inp28),       .b(inp29),      .z(add14_out_stage5), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add15_stage5(.a(inp30),       .b(inp31),      .z(add15_out_stage5), .rnd(3'b000),    .status());

  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage4(.a(add0_out_stage5_reg),       .b(add1_out_stage5_reg),      .z(add0_out_stage4), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add1_stage4(.a(add2_out_stage5_reg),       .b(add3_out_stage5_reg),      .z(add1_out_stage4), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add2_stage4(.a(add4_out_stage5_reg),       .b(add5_out_stage5_reg),      .z(add2_out_stage4), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add3_stage4(.a(add6_out_stage5_reg),       .b(add7_out_stage5_reg),      .z(add3_out_stage4), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add4_stage4(.a(add8_out_stage5_reg),       .b(add9_out_stage5_reg),      .z(add4_out_stage4), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add5_stage4(.a(add10_out_stage5_reg),       .b(add11_out_stage5_reg),      .z(add5_out_stage4), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add6_stage4(.a(add12_out_stage5_reg),       .b(add13_out_stage5_reg),      .z(add6_out_stage4), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add7_stage4(.a(add14_out_stage5_reg),       .b(add15_out_stage5_reg),      .z(add7_out_stage4), .rnd(3'b000),    .status());

  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage3(.a(add0_out_stage4_reg),       .b(add1_out_stage4_reg),      .z(add0_out_stage3), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add1_stage3(.a(add2_out_stage4_reg),       .b(add3_out_stage4_reg),      .z(add1_out_stage3), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add2_stage3(.a(add4_out_stage4_reg),       .b(add5_out_stage4_reg),      .z(add2_out_stage3), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add3_stage3(.a(add6_out_stage4_reg),       .b(add7_out_stage4_reg),      .z(add3_out_stage3), .rnd(3'b000),    .status());

  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage2(.a(add0_out_stage3_reg),       .b(add1_out_stage3_reg),      .z(add0_out_stage2), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add1_stage2(.a(add2_out_stage3_reg),       .b(add3_out_stage3_reg),      .z(add1_out_stage2), .rnd(3'b000),    .status());

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
  a_inp4,
  a_inp5,
  a_inp6,
  a_inp7,
  a_inp8,
  a_inp9,
  a_inp10,
  a_inp11,
  a_inp12,
  a_inp13,
  a_inp14,
  a_inp15,
  a_inp16,
  a_inp17,
  a_inp18,
  a_inp19,
  a_inp20,
  a_inp21,
  a_inp22,
  a_inp23,
  a_inp24,
  a_inp25,
  a_inp26,
  a_inp27,
  a_inp28,
  a_inp29,
  a_inp30,
  a_inp31,
  b_inp,
  outp0,
  outp1,
  outp2,
  outp3,
  outp4,
  outp5,
  outp6,
  outp7,
  outp8,
  outp9,
  outp10,
  outp11,
  outp12,
  outp13,
  outp14,
  outp15,
  outp16,
  outp17,
  outp18,
  outp19,
  outp20,
  outp21,
  outp22,
  outp23,
  outp24,
  outp25,
  outp26,
  outp27,
  outp28,
  outp29,
  outp30,
  outp31
);

  input  [`DATAWIDTH-1 : 0] a_inp0;
  input  [`DATAWIDTH-1 : 0] a_inp1;
  input  [`DATAWIDTH-1 : 0] a_inp2;
  input  [`DATAWIDTH-1 : 0] a_inp3;
  input  [`DATAWIDTH-1 : 0] a_inp4;
  input  [`DATAWIDTH-1 : 0] a_inp5;
  input  [`DATAWIDTH-1 : 0] a_inp6;
  input  [`DATAWIDTH-1 : 0] a_inp7;
  input  [`DATAWIDTH-1 : 0] a_inp8;
  input  [`DATAWIDTH-1 : 0] a_inp9;
  input  [`DATAWIDTH-1 : 0] a_inp10;
  input  [`DATAWIDTH-1 : 0] a_inp11;
  input  [`DATAWIDTH-1 : 0] a_inp12;
  input  [`DATAWIDTH-1 : 0] a_inp13;
  input  [`DATAWIDTH-1 : 0] a_inp14;
  input  [`DATAWIDTH-1 : 0] a_inp15;
  input  [`DATAWIDTH-1 : 0] a_inp16;
  input  [`DATAWIDTH-1 : 0] a_inp17;
  input  [`DATAWIDTH-1 : 0] a_inp18;
  input  [`DATAWIDTH-1 : 0] a_inp19;
  input  [`DATAWIDTH-1 : 0] a_inp20;
  input  [`DATAWIDTH-1 : 0] a_inp21;
  input  [`DATAWIDTH-1 : 0] a_inp22;
  input  [`DATAWIDTH-1 : 0] a_inp23;
  input  [`DATAWIDTH-1 : 0] a_inp24;
  input  [`DATAWIDTH-1 : 0] a_inp25;
  input  [`DATAWIDTH-1 : 0] a_inp26;
  input  [`DATAWIDTH-1 : 0] a_inp27;
  input  [`DATAWIDTH-1 : 0] a_inp28;
  input  [`DATAWIDTH-1 : 0] a_inp29;
  input  [`DATAWIDTH-1 : 0] a_inp30;
  input  [`DATAWIDTH-1 : 0] a_inp31;
  input  [`DATAWIDTH-1 : 0] b_inp;
  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  output  [`DATAWIDTH-1 : 0] outp4;
  output  [`DATAWIDTH-1 : 0] outp5;
  output  [`DATAWIDTH-1 : 0] outp6;
  output  [`DATAWIDTH-1 : 0] outp7;
  output  [`DATAWIDTH-1 : 0] outp8;
  output  [`DATAWIDTH-1 : 0] outp9;
  output  [`DATAWIDTH-1 : 0] outp10;
  output  [`DATAWIDTH-1 : 0] outp11;
  output  [`DATAWIDTH-1 : 0] outp12;
  output  [`DATAWIDTH-1 : 0] outp13;
  output  [`DATAWIDTH-1 : 0] outp14;
  output  [`DATAWIDTH-1 : 0] outp15;
  output  [`DATAWIDTH-1 : 0] outp16;
  output  [`DATAWIDTH-1 : 0] outp17;
  output  [`DATAWIDTH-1 : 0] outp18;
  output  [`DATAWIDTH-1 : 0] outp19;
  output  [`DATAWIDTH-1 : 0] outp20;
  output  [`DATAWIDTH-1 : 0] outp21;
  output  [`DATAWIDTH-1 : 0] outp22;
  output  [`DATAWIDTH-1 : 0] outp23;
  output  [`DATAWIDTH-1 : 0] outp24;
  output  [`DATAWIDTH-1 : 0] outp25;
  output  [`DATAWIDTH-1 : 0] outp26;
  output  [`DATAWIDTH-1 : 0] outp27;
  output  [`DATAWIDTH-1 : 0] outp28;
  output  [`DATAWIDTH-1 : 0] outp29;
  output  [`DATAWIDTH-1 : 0] outp30;
  output  [`DATAWIDTH-1 : 0] outp31;
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub0(.a(a_inp0), .b(b_inp), .z(outp0), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub1(.a(a_inp1), .b(b_inp), .z(outp1), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub2(.a(a_inp2), .b(b_inp), .z(outp2), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub3(.a(a_inp3), .b(b_inp), .z(outp3), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub4(.a(a_inp4), .b(b_inp), .z(outp4), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub5(.a(a_inp5), .b(b_inp), .z(outp5), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub6(.a(a_inp6), .b(b_inp), .z(outp6), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub7(.a(a_inp7), .b(b_inp), .z(outp7), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub8(.a(a_inp8), .b(b_inp), .z(outp8), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub9(.a(a_inp9), .b(b_inp), .z(outp9), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub10(.a(a_inp10), .b(b_inp), .z(outp10), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub11(.a(a_inp11), .b(b_inp), .z(outp11), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub12(.a(a_inp12), .b(b_inp), .z(outp12), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub13(.a(a_inp13), .b(b_inp), .z(outp13), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub14(.a(a_inp14), .b(b_inp), .z(outp14), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub15(.a(a_inp15), .b(b_inp), .z(outp15), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub16(.a(a_inp16), .b(b_inp), .z(outp16), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub17(.a(a_inp17), .b(b_inp), .z(outp17), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub18(.a(a_inp18), .b(b_inp), .z(outp18), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub19(.a(a_inp19), .b(b_inp), .z(outp19), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub20(.a(a_inp20), .b(b_inp), .z(outp20), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub21(.a(a_inp21), .b(b_inp), .z(outp21), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub22(.a(a_inp22), .b(b_inp), .z(outp22), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub23(.a(a_inp23), .b(b_inp), .z(outp23), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub24(.a(a_inp24), .b(b_inp), .z(outp24), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub25(.a(a_inp25), .b(b_inp), .z(outp25), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub26(.a(a_inp26), .b(b_inp), .z(outp26), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub27(.a(a_inp27), .b(b_inp), .z(outp27), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub28(.a(a_inp28), .b(b_inp), .z(outp28), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub29(.a(a_inp29), .b(b_inp), .z(outp29), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub30(.a(a_inp30), .b(b_inp), .z(outp30), .rnd(3'b000), .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub31(.a(a_inp31), .b(b_inp), .z(outp31), .rnd(3'b000), .status());
endmodule


module mode7_exp(
  inp0, 
  inp1, 
  inp2, 
  inp3, 
  inp4, 
  inp5, 
  inp6, 
  inp7, 
  inp8, 
  inp9, 
  inp10, 
  inp11, 
  inp12, 
  inp13, 
  inp14, 
  inp15, 
  inp16, 
  inp17, 
  inp18, 
  inp19, 
  inp20, 
  inp21, 
  inp22, 
  inp23, 
  inp24, 
  inp25, 
  inp26, 
  inp27, 
  inp28, 
  inp29, 
  inp30, 
  inp31, 

  clk,
  reset,
  stage_run,

  outp0, 
  outp1, 
  outp2, 
  outp3, 
  outp4, 
  outp5, 
  outp6, 
  outp7, 
  outp8, 
  outp9, 
  outp10, 
  outp11, 
  outp12, 
  outp13, 
  outp14, 
  outp15, 
  outp16, 
  outp17, 
  outp18, 
  outp19, 
  outp20, 
  outp21, 
  outp22, 
  outp23, 
  outp24, 
  outp25, 
  outp26, 
  outp27, 
  outp28, 
  outp29, 
  outp30, 
  outp31
);

  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;
  input  [`DATAWIDTH-1 : 0] inp4;
  input  [`DATAWIDTH-1 : 0] inp5;
  input  [`DATAWIDTH-1 : 0] inp6;
  input  [`DATAWIDTH-1 : 0] inp7;
  input  [`DATAWIDTH-1 : 0] inp8;
  input  [`DATAWIDTH-1 : 0] inp9;
  input  [`DATAWIDTH-1 : 0] inp10;
  input  [`DATAWIDTH-1 : 0] inp11;
  input  [`DATAWIDTH-1 : 0] inp12;
  input  [`DATAWIDTH-1 : 0] inp13;
  input  [`DATAWIDTH-1 : 0] inp14;
  input  [`DATAWIDTH-1 : 0] inp15;
  input  [`DATAWIDTH-1 : 0] inp16;
  input  [`DATAWIDTH-1 : 0] inp17;
  input  [`DATAWIDTH-1 : 0] inp18;
  input  [`DATAWIDTH-1 : 0] inp19;
  input  [`DATAWIDTH-1 : 0] inp20;
  input  [`DATAWIDTH-1 : 0] inp21;
  input  [`DATAWIDTH-1 : 0] inp22;
  input  [`DATAWIDTH-1 : 0] inp23;
  input  [`DATAWIDTH-1 : 0] inp24;
  input  [`DATAWIDTH-1 : 0] inp25;
  input  [`DATAWIDTH-1 : 0] inp26;
  input  [`DATAWIDTH-1 : 0] inp27;
  input  [`DATAWIDTH-1 : 0] inp28;
  input  [`DATAWIDTH-1 : 0] inp29;
  input  [`DATAWIDTH-1 : 0] inp30;
  input  [`DATAWIDTH-1 : 0] inp31;

  input  clk;
  input  reset;
  input  stage_run;

  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  output  [`DATAWIDTH-1 : 0] outp4;
  output  [`DATAWIDTH-1 : 0] outp5;
  output  [`DATAWIDTH-1 : 0] outp6;
  output  [`DATAWIDTH-1 : 0] outp7;
  output  [`DATAWIDTH-1 : 0] outp8;
  output  [`DATAWIDTH-1 : 0] outp9;
  output  [`DATAWIDTH-1 : 0] outp10;
  output  [`DATAWIDTH-1 : 0] outp11;
  output  [`DATAWIDTH-1 : 0] outp12;
  output  [`DATAWIDTH-1 : 0] outp13;
  output  [`DATAWIDTH-1 : 0] outp14;
  output  [`DATAWIDTH-1 : 0] outp15;
  output  [`DATAWIDTH-1 : 0] outp16;
  output  [`DATAWIDTH-1 : 0] outp17;
  output  [`DATAWIDTH-1 : 0] outp18;
  output  [`DATAWIDTH-1 : 0] outp19;
  output  [`DATAWIDTH-1 : 0] outp20;
  output  [`DATAWIDTH-1 : 0] outp21;
  output  [`DATAWIDTH-1 : 0] outp22;
  output  [`DATAWIDTH-1 : 0] outp23;
  output  [`DATAWIDTH-1 : 0] outp24;
  output  [`DATAWIDTH-1 : 0] outp25;
  output  [`DATAWIDTH-1 : 0] outp26;
  output  [`DATAWIDTH-1 : 0] outp27;
  output  [`DATAWIDTH-1 : 0] outp28;
  output  [`DATAWIDTH-1 : 0] outp29;
  output  [`DATAWIDTH-1 : 0] outp30;
  output  [`DATAWIDTH-1 : 0] outp31;
  expunit exp0(.a(inp0), .z(outp0), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp1(.a(inp1), .z(outp1), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp2(.a(inp2), .z(outp2), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp3(.a(inp3), .z(outp3), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp4(.a(inp4), .z(outp4), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp5(.a(inp5), .z(outp5), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp6(.a(inp6), .z(outp6), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp7(.a(inp7), .z(outp7), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp8(.a(inp8), .z(outp8), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp9(.a(inp9), .z(outp9), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp10(.a(inp10), .z(outp10), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp11(.a(inp11), .z(outp11), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp12(.a(inp12), .z(outp12), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp13(.a(inp13), .z(outp13), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp14(.a(inp14), .z(outp14), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp15(.a(inp15), .z(outp15), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp16(.a(inp16), .z(outp16), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp17(.a(inp17), .z(outp17), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp18(.a(inp18), .z(outp18), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp19(.a(inp19), .z(outp19), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp20(.a(inp20), .z(outp20), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp21(.a(inp21), .z(outp21), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp22(.a(inp22), .z(outp22), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp23(.a(inp23), .z(outp23), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp24(.a(inp24), .z(outp24), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp25(.a(inp25), .z(outp25), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp26(.a(inp26), .z(outp26), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp27(.a(inp27), .z(outp27), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp28(.a(inp28), .z(outp28), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp29(.a(inp29), .z(outp29), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp30(.a(inp30), .z(outp30), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
  expunit exp31(.a(inp31), .z(outp31), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));
endmodule

