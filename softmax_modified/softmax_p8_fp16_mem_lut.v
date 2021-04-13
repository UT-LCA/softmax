//softmax_p8_smem_rfloat16_alut_v512_b2_-0.1_0.1.v
`ifndef DEFINES_DONE
`define DEFINES_DONE
`define EXPONENT 5
`define MANTISSA 10
`define SIGN 1
`define DATAWIDTH (`SIGN+`EXPONENT+`MANTISSA)
`define IEEE_COMPLIANCE 1
`define NUM 8
`define ADDRSIZE 7
`define ADDRSIZE_FOR_TB 10
`endif


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
  output  [`ADDRSIZE-1:0] sub0_inp_addr;
  output  [`ADDRSIZE-1:0] sub1_inp_addr;

  output [`DATAWIDTH-1:0] outp0;
  output [`DATAWIDTH-1:0] outp1;
  output [`DATAWIDTH-1:0] outp2;
  output [`DATAWIDTH-1:0] outp3;
  output [`DATAWIDTH-1:0] outp4;
  output [`DATAWIDTH-1:0] outp5;
  output [`DATAWIDTH-1:0] outp6;
  output [`DATAWIDTH-1:0] outp7;
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

  reg mode3_stage_run2;
  reg mode3_stage_run;
  reg mode7_stage_run2;
  reg mode7_stage_run;

  reg mode3_run;

  reg mode1_stage0_run;
  reg mode1_stage1_run;
  reg mode1_stage2_run;
  wire mode1_stage3_run;
  assign mode1_stage3_run = mode1_run;

  reg mode4_stage1_run_a;
  reg mode4_stage2_run_a;
  reg mode4_stage0_run;
  reg mode4_stage1_run;
  reg mode4_stage2_run;
  reg mode4_stage3_run;

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

  always @(posedge clk) begin
    if(reset) begin
      inp_reg <= 0;
      addr <= 0;
      mode1_start <= 0;
      mode1_run <= 0;
    end
    //init latch the input address
    else if(init) begin
      addr <= start_addr;
    end
    //start the mode1 max calculation
    else if(start)begin
      mode1_start <= 1;
    end
    //logic when to finish mode1 and trigger mode2 to latch the mode2 address
    else if(mode1_start && addr < end_addr) begin
      addr <= addr + 1;
      inp_reg <= inp;
      mode1_run <= 1;
    end else if(addr == end_addr)begin
      addr <= 0;
      mode1_run <= 0;
      mode1_start <= 0;
    end else begin
      mode1_run <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      mode1_stage2_run <= 0;
    end
    else if (mode1_stage3_run == 1) begin
      mode1_stage2_run <= 1;
    end
    else begin
      mode1_stage2_run <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      mode1_stage1_run <= 0;
    end
    else if (mode1_stage2_run == 1) begin
      mode1_stage1_run <= 1;
    end
    else begin
      mode1_stage1_run <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      mode1_stage0_run <= 0;
    end
    else if (mode1_stage1_run == 1) begin
      mode1_stage0_run <= 1;
    end
    else begin
      mode1_stage0_run <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      sub0_inp_addr <= 0;
      sub0_inp_reg <= 0;
      mode2_start <= 0;
      mode2_run <= 0;
    end
    else if ((addr == end_addr) && ~(mode1_start && (addr<end_addr))) begin
        mode2_start <= 1;
        sub0_inp_addr <= start_addr;
	  end
    //logic when to finish mode2
    else if(mode2_start && sub0_inp_addr < end_addr) begin
      sub0_inp_addr <= sub0_inp_addr + 1;
      sub0_inp_reg <= sub0_inp;
      mode2_run <= 1;
    end 
	else if(sub0_inp_addr == end_addr)begin
      sub0_inp_addr <= 0;
      sub0_inp_reg <= 0;
      mode2_run <= 0;
      mode2_start <= 0;
    end
  end	

  always @(posedge clk) begin
    if(reset) begin
      mode3_stage_run2 <= 0;
    end
    //logic when to trigger mode3
    else if(mode2_run == 1) begin
      mode3_stage_run2 <= 1;
    end else begin
      mode3_stage_run2 <= 0;
    end
  end	

  always @(posedge clk) begin
    if(reset) begin
      mode3_stage_run <= 0;
    end
    else if(mode3_stage_run2 == 1) begin
      mode3_stage_run <= 1;
    end else begin
      mode3_stage_run <= 0;
    end
  end	
  
  always @(posedge clk) begin
    if(reset) begin
      mode3_run <= 0;
    end
    else if(mode3_stage_run == 1) begin
      mode3_run <= 1;
    end else begin
      mode3_run <= 0;
    end
  end

    //logic when to trigger mode4 last stage adderTree, since the final results of adderTree
    //is always ready 1 cycle after mode3 finishes, so there is no need on extra
    //logic to control the adderTree outputs
  always @(posedge clk) begin
    if(reset) begin
      mode4_stage3_run <= 0;
    end
    else if (mode3_run == 1) begin
      mode4_stage3_run <= 1;
    end else begin
      mode4_stage3_run <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      mode4_stage2_run <= 0;
    end
    else if (mode4_stage3_run == 1) begin
      mode4_stage2_run <= 1;
    end else begin
      mode4_stage2_run <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      mode4_stage1_run <= 0;
    end
    else if (mode4_stage2_run == 1) begin
      mode4_stage1_run <= 1;
    end else begin
      mode4_stage1_run <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      mode4_stage0_run <= 0;
    end
    else if (mode4_stage1_run == 1) begin
      mode4_stage0_run <= 1;
    end else begin
      mode4_stage0_run <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      mode5_run <= 0;
    end
    //mode5 should be triggered right at the falling edge of mode4_stage1_run
    else if(mode4_stage1_run_a & ~mode4_stage1_run) begin
      mode5_run <= 1;
    end 
	else if(mode4_stage1_run == 0) begin
      mode5_run <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      presub_start <= 0;
      sub1_inp_addr <= 0;
      sub1_inp_reg <= 0;
      presub_run <= 0;
    end
    else if(mode4_stage2_run_a & ~mode4_stage2_run) begin
      presub_start <= 1;
      sub1_inp_addr <= start_addr;
      sub1_inp_reg <= sub1_inp;
    end
    else if(~reset && presub_start && sub1_inp_addr < end_addr)begin
      sub1_inp_addr <= sub1_inp_addr + 1;
      sub1_inp_reg <= sub1_inp;
      presub_run <= 1;
    end 
	else if(sub1_inp_addr == end_addr) begin
      presub_run <= 0;
      presub_start <= 0;
      sub1_inp_addr <= 0;
      sub1_inp_reg <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      mode6_run <= 0;
	end  
    else if(presub_run) begin
      mode6_run <= 1;
    end else begin
      mode6_run <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      mode7_stage_run2 <= 0;
	end
    else if(mode6_run == 1) begin
      mode7_stage_run2 <= 1;
    end else begin
      mode7_stage_run2 <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      mode7_stage_run <= 0;
	end
    else if(mode7_stage_run2 == 1) begin
      mode7_stage_run <= 1;
    end else begin
      mode7_stage_run <= 0;
    end
  end 

  always @(posedge clk) begin
    if(reset) begin
      mode7_run <= 0;
	end
	else if(mode7_stage_run == 1) begin
      mode7_run <= 1;
    end else begin
      mode7_run <= 0;
    end
  end

  always @(posedge clk) begin
    if(reset) begin
      done <= 0;
	end  
    else if(mode7_run) begin
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
      .mode1_stage0_run(mode1_stage0_run),
	  .mode1_stage1_run(mode1_stage1_run),
      .mode1_stage2_run(mode1_stage2_run), 
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
  mode2_sub mode2_sub(
      .a_inp0(sub0_inp_reg[`DATAWIDTH*1-1:`DATAWIDTH*0]),
      .a_inp1(sub0_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH*1]),
      .a_inp2(sub0_inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
      .a_inp3(sub0_inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
      .a_inp4(sub0_inp_reg[`DATAWIDTH*5-1:`DATAWIDTH*4]),
      .a_inp5(sub0_inp_reg[`DATAWIDTH*6-1:`DATAWIDTH*5]),
      .a_inp6(sub0_inp_reg[`DATAWIDTH*7-1:`DATAWIDTH*6]),
      .a_inp7(sub0_inp_reg[`DATAWIDTH*8-1:`DATAWIDTH*7]),
      .outp0(mode2_outp_sub0),
      .outp1(mode2_outp_sub1),
      .outp2(mode2_outp_sub2),
      .outp3(mode2_outp_sub3),
      .outp4(mode2_outp_sub4),
      .outp5(mode2_outp_sub5),
      .outp6(mode2_outp_sub6),
      .outp7(mode2_outp_sub7),
      .b_inp(max_outp));

  reg [`DATAWIDTH-1:0] mode2_outp_sub0_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub1_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub2_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub3_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub4_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub5_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub6_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub7_reg;
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
    end else if (mode2_run) begin
      mode2_outp_sub0_reg <= mode2_outp_sub0;
      mode2_outp_sub1_reg <= mode2_outp_sub1;
      mode2_outp_sub2_reg <= mode2_outp_sub2;
      mode2_outp_sub3_reg <= mode2_outp_sub3;
      mode2_outp_sub4_reg <= mode2_outp_sub4;
      mode2_outp_sub5_reg <= mode2_outp_sub5;
      mode2_outp_sub6_reg <= mode2_outp_sub6;
      mode2_outp_sub7_reg <= mode2_outp_sub7;
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
  mode3_exp mode3_exp(
      .inp0(mode2_outp_sub0_reg),
      .inp1(mode2_outp_sub1_reg),
      .inp2(mode2_outp_sub2_reg),
      .inp3(mode2_outp_sub3_reg),
      .inp4(mode2_outp_sub4_reg),
      .inp5(mode2_outp_sub5_reg),
      .inp6(mode2_outp_sub6_reg),
      .inp7(mode2_outp_sub7_reg),

      .clk(clk),
      .reset(reset),
      .stage_run(mode3_stage_run),
      .stage_run2(mode3_stage_run2),
      .outp0(mode3_outp_exp0),
      .outp1(mode3_outp_exp1),
      .outp2(mode3_outp_exp2),
      .outp3(mode3_outp_exp3),
      .outp4(mode3_outp_exp4),
      .outp5(mode3_outp_exp5),
      .outp6(mode3_outp_exp6),
      .outp7(mode3_outp_exp7)
  );

  reg [`DATAWIDTH-1:0] mode3_outp_exp0_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp1_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp2_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp3_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp4_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp5_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp6_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp7_reg;
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
    end else if (mode3_run) begin
      mode3_outp_exp0_reg <= mode3_outp_exp0;
      mode3_outp_exp1_reg <= mode3_outp_exp1;
      mode3_outp_exp2_reg <= mode3_outp_exp2;
      mode3_outp_exp3_reg <= mode3_outp_exp3;
      mode3_outp_exp4_reg <= mode3_outp_exp4;
      mode3_outp_exp5_reg <= mode3_outp_exp5;
      mode3_outp_exp6_reg <= mode3_outp_exp6;
      mode3_outp_exp7_reg <= mode3_outp_exp7;
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
  reg [`DATAWIDTH-1:0] mode6_outp_presub0_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub1_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub2_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub3_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub4_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub5_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub6_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_presub7_reg;

  mode6_sub pre_sub(
      .a_inp0(sub1_inp_reg[`DATAWIDTH*1-1:`DATAWIDTH*0]),
      .a_inp1(sub1_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH*1]),
      .a_inp2(sub1_inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
      .a_inp3(sub1_inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
      .a_inp4(sub1_inp_reg[`DATAWIDTH*5-1:`DATAWIDTH*4]),
      .a_inp5(sub1_inp_reg[`DATAWIDTH*6-1:`DATAWIDTH*5]),
      .a_inp6(sub1_inp_reg[`DATAWIDTH*7-1:`DATAWIDTH*6]),
      .a_inp7(sub1_inp_reg[`DATAWIDTH*8-1:`DATAWIDTH*7]),
      .b_inp(max_outp),
      .outp0(mode6_outp_presub0),
      .outp1(mode6_outp_presub1),
      .outp2(mode6_outp_presub2),
      .outp3(mode6_outp_presub3),
      .outp4(mode6_outp_presub4),
      .outp5(mode6_outp_presub5),
      .outp6(mode6_outp_presub6),
      .outp7(mode6_outp_presub7)
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
    end else if (presub_run) begin
      mode6_outp_presub0_reg <= mode6_outp_presub0;
      mode6_outp_presub1_reg <= mode6_outp_presub1;
      mode6_outp_presub2_reg <= mode6_outp_presub2;
      mode6_outp_presub3_reg <= mode6_outp_presub3;
      mode6_outp_presub4_reg <= mode6_outp_presub4;
      mode6_outp_presub5_reg <= mode6_outp_presub5;
      mode6_outp_presub6_reg <= mode6_outp_presub6;
      mode6_outp_presub7_reg <= mode6_outp_presub7;
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
  reg [`DATAWIDTH-1:0] mode6_outp_logsub0_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub1_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub2_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub3_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub4_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub5_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub6_reg;
  reg [`DATAWIDTH-1:0] mode6_outp_logsub7_reg;

  mode6_sub log_sub(
      .a_inp0(mode6_outp_presub0_reg),
      .a_inp1(mode6_outp_presub1_reg),
      .a_inp2(mode6_outp_presub2_reg),
      .a_inp3(mode6_outp_presub3_reg),
      .a_inp4(mode6_outp_presub4_reg),
      .a_inp5(mode6_outp_presub5_reg),
      .a_inp6(mode6_outp_presub6_reg),
      .a_inp7(mode6_outp_presub7_reg),
      .b_inp(mode5_outp_log_reg),
      .outp0(mode6_outp_logsub0),
      .outp1(mode6_outp_logsub1),
      .outp2(mode6_outp_logsub2),
      .outp3(mode6_outp_logsub3),
      .outp4(mode6_outp_logsub4),
      .outp5(mode6_outp_logsub5),
      .outp6(mode6_outp_logsub6),
      .outp7(mode6_outp_logsub7)
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
    end else if (mode6_run) begin
      mode6_outp_logsub0_reg <= mode6_outp_logsub0;
      mode6_outp_logsub1_reg <= mode6_outp_logsub1;
      mode6_outp_logsub2_reg <= mode6_outp_logsub2;
      mode6_outp_logsub3_reg <= mode6_outp_logsub3;
      mode6_outp_logsub4_reg <= mode6_outp_logsub4;
      mode6_outp_logsub5_reg <= mode6_outp_logsub5;
      mode6_outp_logsub6_reg <= mode6_outp_logsub6;
      mode6_outp_logsub7_reg <= mode6_outp_logsub7;
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
  reg [`DATAWIDTH-1:0] outp0;
  reg [`DATAWIDTH-1:0] outp1;
  reg [`DATAWIDTH-1:0] outp2;
  reg [`DATAWIDTH-1:0] outp3;
  reg [`DATAWIDTH-1:0] outp4;
  reg [`DATAWIDTH-1:0] outp5;
  reg [`DATAWIDTH-1:0] outp6;
  reg [`DATAWIDTH-1:0] outp7;

  mode7_exp mode7_exp(
      .inp0(mode6_outp_logsub0_reg),
      .inp1(mode6_outp_logsub1_reg),
      .inp2(mode6_outp_logsub2_reg),
      .inp3(mode6_outp_logsub3_reg),
      .inp4(mode6_outp_logsub4_reg),
      .inp5(mode6_outp_logsub5_reg),
      .inp6(mode6_outp_logsub6_reg),
      .inp7(mode6_outp_logsub7_reg),

      .clk(clk),
      .reset(reset),
      .stage_run(mode7_stage_run),
      .stage_run2(mode7_stage_run2),

      .outp0(outp0_temp),
      .outp1(outp1_temp),
      .outp2(outp2_temp),
      .outp3(outp3_temp),
      .outp4(outp4_temp),
      .outp5(outp5_temp),
      .outp6(outp6_temp),
      .outp7(outp7_temp)
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
    end else if (mode7_run) begin
      outp0 <= outp0_temp;
      outp1 <= outp1_temp;
      outp2 <= outp2_temp;
      outp3 <= outp3_temp;
      outp4 <= outp4_temp;
      outp5 <= outp5_temp;
      outp6 <= outp6_temp;
      outp7 <= outp7_temp;
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
  mode1_stage3_run,
  mode1_stage2_run,
  mode1_stage1_run,  
  mode1_stage0_run,
  clk,
  reset,
  outp,
);

  input  [`DATAWIDTH-1 : 0] inp0; 
  input  [`DATAWIDTH-1 : 0] inp1; 
  input  [`DATAWIDTH-1 : 0] inp2; 
  input  [`DATAWIDTH-1 : 0] inp3; 
  input  [`DATAWIDTH-1 : 0] inp4; 
  input  [`DATAWIDTH-1 : 0] inp5; 
  input  [`DATAWIDTH-1 : 0] inp6; 
  input  [`DATAWIDTH-1 : 0] inp7; 
  input mode1_stage3_run;
  input mode1_stage2_run;
  input mode1_stage1_run;
  input mode1_stage0_run;
  input clk;
  input reset;
  output [`DATAWIDTH-1 : 0] outp;

  reg    [`DATAWIDTH-1 : 0] outp;

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
  reg    [`DATAWIDTH-1 : 0] cmp1_out_stage2_reg;
  reg    [`DATAWIDTH-1 : 0] cmp0_out_stage2_reg;
  reg    [`DATAWIDTH-1 : 0] cmp0_out_stage1_reg;


  always @(posedge clk) begin
    if (reset) begin
      outp <= 0;
      cmp0_out_stage3_reg <= 0;
      cmp1_out_stage3_reg <= 0;
      cmp2_out_stage3_reg <= 0;
      cmp3_out_stage3_reg <= 0;
	  cmp0_out_stage2_reg <= 0;
      cmp1_out_stage2_reg <= 0;
	  cmp0_out_stage1_reg <= 0;
    end

    else if(~reset && mode1_stage3_run) begin
      cmp0_out_stage3_reg <= cmp0_out_stage3;
      cmp1_out_stage3_reg <= cmp1_out_stage3;
      cmp2_out_stage3_reg <= cmp2_out_stage3;
      cmp3_out_stage3_reg <= cmp3_out_stage3;
    end
	
	else if(~reset && mode1_stage2_run) begin
      cmp0_out_stage2_reg <= cmp0_out_stage2;
      cmp1_out_stage2_reg <= cmp1_out_stage2;
    end
	
	else if(~reset && mode1_stage1_run) begin
      cmp0_out_stage1_reg <= cmp0_out_stage1;
    end

    else if(~reset && mode1_stage0_run) begin
      outp <= cmp0_out_stage0;
    end

  end

wire cmp0_stage3_aeb;
wire cmp0_stage3_aneb;
wire cmp0_stage3_alb;
wire cmp0_stage3_aleb;
wire cmp0_stage3_agb;
wire cmp0_stage3_ageb;
wire cmp0_stage3_unordered;

wire cmp1_stage3_aeb;
wire cmp1_stage3_aneb;
wire cmp1_stage3_alb;
wire cmp1_stage3_aleb;
wire cmp1_stage3_agb;
wire cmp1_stage3_ageb;
wire cmp1_stage3_unordered;

wire cmp2_stage3_aeb;
wire cmp2_stage3_aneb;
wire cmp2_stage3_alb;
wire cmp2_stage3_aleb;
wire cmp2_stage3_agb;
wire cmp2_stage3_ageb;
wire cmp2_stage3_unordered;

wire cmp3_stage3_aeb;
wire cmp3_stage3_aneb;
wire cmp3_stage3_alb;
wire cmp3_stage3_aleb;
wire cmp3_stage3_agb;
wire cmp3_stage3_ageb;
wire cmp3_stage3_unordered;

wire cmp0_stage2_aeb;
wire cmp0_stage2_aneb;
wire cmp0_stage2_alb;
wire cmp0_stage2_aleb;
wire cmp0_stage2_agb;
wire cmp0_stage2_ageb;
wire cmp0_stage2_unordered;

wire cmp1_stage2_aeb;
wire cmp1_stage2_aneb;
wire cmp1_stage2_alb;
wire cmp1_stage2_aleb;
wire cmp1_stage2_agb;
wire cmp1_stage2_ageb;
wire cmp1_stage2_unordered;

wire cmp0_stage1_aeb;
wire cmp0_stage1_aneb;
wire cmp0_stage1_alb;
wire cmp0_stage1_aleb;
wire cmp0_stage1_agb;
wire cmp0_stage1_ageb;
wire cmp0_stage1_unordered;

wire cmp0_stage0_aeb;
wire cmp0_stage0_aneb;
wire cmp0_stage0_alb;
wire cmp0_stage0_aleb;
wire cmp0_stage0_agb;
wire cmp0_stage0_ageb;
wire cmp0_stage0_unordered;

//Stage3
comparator cmp0_stage3(.a(inp0),       .b(inp1),        .aeb(cmp0_stage3_aeb), .aneb(cmp0_stage3_aneb), .alb(cmp0_stage3_alb), .aleb(cmp0_stage3_aleb), .agb(cmp0_stage3_agb), .ageb(cmp0_stage3_ageb), .unordered(cmp0_stage3_unordered));
assign cmp0_out_stage3 = (cmp0_stage3_ageb==1'b1) ? inp0 : inp1;

comparator cmp1_stage3(.a(inp2),       .b(inp3),         .aeb(cmp1_stage3_aeb), .aneb(cmp1_stage3_aneb), .alb(cmp1_stage3_alb), .aleb(cmp1_stage3_aleb), .agb(cmp1_stage3_agb), .ageb(cmp1_stage3_ageb), .unordered(cmp1_stage3_unordered));   
assign cmp1_out_stage3 = (cmp1_stage3_ageb==1'b1) ? inp2 : inp3;

comparator cmp2_stage3(.a(inp4),       .b(inp5),         .aeb(cmp2_stage3_aeb), .aneb(cmp2_stage3_aneb), .alb(cmp2_stage3_alb), .aleb(cmp2_stage3_aleb), .agb(cmp2_stage3_agb), .ageb(cmp2_stage3_ageb), .unordered(cmp2_stage3_unordered));   
assign cmp2_out_stage3 = (cmp2_stage3_ageb==1'b1) ? inp4 : inp5;

comparator cmp3_stage3(.a(inp6),       .b(inp7),         .aeb(cmp3_stage3_aeb), .aneb(cmp3_stage3_aneb), .alb(cmp3_stage3_alb), .aleb(cmp3_stage3_aleb), .agb(cmp3_stage3_agb), .ageb(cmp3_stage3_ageb), .unordered(cmp3_stage3_unordered));   
assign cmp3_out_stage3 = (cmp3_stage3_ageb==1'b1) ? inp6 : inp7;

//Stage2
comparator cmp0_stage2(.a(cmp0_out_stage3_reg),       .b(cmp1_out_stage3_reg),        .aeb(cmp0_stage2_aeb), .aneb(cmp0_stage2_aneb), .alb(cmp0_stage2_alb), .aleb(cmp0_stage2_aleb), .agb(cmp0_stage2_agb), .ageb(cmp0_stage2_ageb), .unordered(cmp0_stage2_unordered));
assign cmp0_out_stage2 = (cmp0_stage2_ageb==1'b1) ? cmp0_out_stage3_reg : cmp1_out_stage3_reg;

comparator cmp1_stage2(.a(cmp2_out_stage3_reg),       .b(cmp3_out_stage3_reg),         .aeb(cmp1_stage2_aeb), .aneb(cmp1_stage2_aneb), .alb(cmp1_stage2_alb), .aleb(cmp1_stage2_aleb), .agb(cmp1_stage2_agb), .ageb(cmp1_stage2_ageb), .unordered(cmp1_stage2_unordered));   
assign cmp1_out_stage2 = (cmp1_stage2_ageb==1'b1) ? cmp2_out_stage3_reg : cmp3_out_stage3_reg;

//Stage1
comparator cmp0_stage1(.a(cmp0_out_stage2_reg),       .b(cmp1_out_stage2_reg),          .aeb(cmp0_stage1_aeb), .aneb(cmp0_stage1_aneb), .alb(cmp0_stage1_alb), .aleb(cmp0_stage1_aleb), .agb(cmp0_stage1_agb), .ageb(cmp0_stage1_ageb), .unordered(cmp0_stage1_unordered));
assign cmp0_out_stage1 = (cmp0_stage1_ageb==1'b1) ? cmp0_out_stage2_reg: cmp1_out_stage2_reg;

//Stage0
comparator cmp0_stage0(.a(outp),       .b(cmp0_out_stage1_reg),         .aeb(cmp0_stage0_aeb), .aneb(cmp0_stage0_aneb), .alb(cmp0_stage0_alb), .aleb(cmp0_stage0_aleb), .agb(cmp0_stage0_agb), .ageb(cmp0_stage0_ageb), .unordered(cmp0_stage0_unordered));
assign cmp0_out_stage0 = (cmp0_stage0_ageb==1'b1) ? outp : cmp0_out_stage1_reg;

//DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage3(.a(inp0),       .b(inp1),      .z1(cmp0_out_stage3), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
//DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp1_stage3(.a(inp2),       .b(inp3),      .z1(cmp1_out_stage3), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
//DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp2_stage3(.a(inp4),       .b(inp5),      .z1(cmp2_out_stage3), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
//DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp3_stage3(.a(inp6),       .b(inp7),      .z1(cmp3_out_stage3), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
//
//DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage2(.a(cmp0_out_stage3_reg),       .b(cmp1_out_stage3_reg),      .z1(cmp0_out_stage2), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
//DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp1_stage2(.a(cmp2_out_stage3_reg),       .b(cmp3_out_stage3_reg),      .z1(cmp1_out_stage2), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
//
//DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage1(.a(cmp0_out_stage2),       .b(cmp1_out_stage2),      .z1(cmp0_out_stage1), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
//
//DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage0(.a(outp),       .b(cmp0_out_stage1),      .z1(cmp0_out_stage0), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());

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
  outp0,
  outp1,
  outp2,
  outp3,
  outp4,
  outp5,
  outp6,
  outp7,
  b_inp,
);

  input  [`DATAWIDTH-1 : 0] a_inp0;
  input  [`DATAWIDTH-1 : 0] a_inp1;
  input  [`DATAWIDTH-1 : 0] a_inp2;
  input  [`DATAWIDTH-1 : 0] a_inp3;
  input  [`DATAWIDTH-1 : 0] a_inp4;
  input  [`DATAWIDTH-1 : 0] a_inp5;
  input  [`DATAWIDTH-1 : 0] a_inp6;
  input  [`DATAWIDTH-1 : 0] a_inp7;
  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  output  [`DATAWIDTH-1 : 0] outp4;
  output  [`DATAWIDTH-1 : 0] outp5;
  output  [`DATAWIDTH-1 : 0] outp6;
  output  [`DATAWIDTH-1 : 0] outp7;
  input  [`DATAWIDTH-1 : 0] b_inp;

  wire clk_NC;
  wire rst_NC;
  wire [4:0] flags_NC0, flags_NC1, flags_NC2, flags_NC3;
  wire [4:0] flags_NC4, flags_NC5, flags_NC6, flags_NC7;

  // 0 add, 1 sub
  FPAddSub sub0(.clk(clk_NC), .rst(rst_NC), .a(a_inp0),	.b(b_inp), .operation(1'b1),	.result(outp0), .flags(flags_NC0));
  FPAddSub sub1(.clk(clk_NC), .rst(rst_NC), .a(a_inp1),	.b(b_inp), .operation(1'b1),	.result(outp1), .flags(flags_NC1));
  FPAddSub sub2(.clk(clk_NC), .rst(rst_NC), .a(a_inp2),	.b(b_inp), .operation(1'b1),	.result(outp2), .flags(flags_NC2));
  FPAddSub sub3(.clk(clk_NC), .rst(rst_NC), .a(a_inp3),	.b(b_inp), .operation(1'b1),	.result(outp3), .flags(flags_NC3));
  FPAddSub sub4(.clk(clk_NC), .rst(rst_NC), .a(a_inp4),	.b(b_inp), .operation(1'b1),	.result(outp4), .flags(flags_NC4));
  FPAddSub sub5(.clk(clk_NC), .rst(rst_NC), .a(a_inp5),	.b(b_inp), .operation(1'b1),	.result(outp5), .flags(flags_NC5));
  FPAddSub sub6(.clk(clk_NC), .rst(rst_NC), .a(a_inp6),	.b(b_inp), .operation(1'b1),	.result(outp6), .flags(flags_NC6));
  FPAddSub sub7(.clk(clk_NC), .rst(rst_NC), .a(a_inp7),	.b(b_inp), .operation(1'b1),	.result(outp7), .flags(flags_NC7));

//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub0(.a(a_inp0), .b(b_inp), .z(outp0), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub1(.a(a_inp1), .b(b_inp), .z(outp1), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub2(.a(a_inp2), .b(b_inp), .z(outp2), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub3(.a(a_inp3), .b(b_inp), .z(outp3), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub4(.a(a_inp4), .b(b_inp), .z(outp4), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub5(.a(a_inp5), .b(b_inp), .z(outp5), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub6(.a(a_inp6), .b(b_inp), .z(outp6), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub7(.a(a_inp7), .b(b_inp), .z(outp7), .rnd(3'b000), .status());
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

  clk,
  reset,
  stage_run,
  stage_run2,
  
  outp0, 
  outp1, 
  outp2, 
  outp3, 
  outp4, 
  outp5, 
  outp6, 
  outp7
);

  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;
  input  [`DATAWIDTH-1 : 0] inp4;
  input  [`DATAWIDTH-1 : 0] inp5;
  input  [`DATAWIDTH-1 : 0] inp6;
  input  [`DATAWIDTH-1 : 0] inp7;

  input  clk;
  input  reset;
  input  stage_run;
  input  stage_run2; 
  
  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  output  [`DATAWIDTH-1 : 0] outp4;
  output  [`DATAWIDTH-1 : 0] outp5;
  output  [`DATAWIDTH-1 : 0] outp6;
  output  [`DATAWIDTH-1 : 0] outp7;
  expunit exp0(.a(inp0), .z(outp0), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp1(.a(inp1), .z(outp1), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp2(.a(inp2), .z(outp2), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp3(.a(inp3), .z(outp3), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp4(.a(inp4), .z(outp4), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp5(.a(inp5), .z(outp5), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp6(.a(inp6), .z(outp6), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp7(.a(inp7), .z(outp7), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
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
  mode4_stage0_run,
  mode4_stage1_run,
  mode4_stage2_run,
  mode4_stage3_run,

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
  output [`DATAWIDTH-1 : 0] outp;
  input mode4_stage0_run;
  input mode4_stage1_run;
  input mode4_stage2_run;
  input mode4_stage3_run;

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

//  always @(posedge clk) begin
//    if (reset) begin
//      outp <= 0;
//      add0_out_stage3_reg <= 0;
//      add1_out_stage3_reg <= 0;
//      add2_out_stage3_reg <= 0;
//      add3_out_stage3_reg <= 0;
//      add0_out_stage2_reg <= 0;
//      add1_out_stage2_reg <= 0;
//      add0_out_stage1_reg <= 0;
//    end
//
//    if(~reset && mode4_stage3_run) begin
//      add0_out_stage3_reg <= add0_out_stage3;
//      add1_out_stage3_reg <= add1_out_stage3;
//      add2_out_stage3_reg <= add2_out_stage3;
//      add3_out_stage3_reg <= add3_out_stage3;
//    end
//
//    if(~reset && mode4_stage2_run) begin
//      add0_out_stage2_reg <= add0_out_stage2;
//      add1_out_stage2_reg <= add1_out_stage2;
//    end
//
//    if(~reset && mode4_stage1_run) begin
//      add0_out_stage1_reg <= add0_out_stage1;
//    end
//
//    if(~reset && mode4_stage0_run) begin
//      outp <= add0_out_stage0;
//    end
//
//  end


always @ (posedge clk) begin
	if(~reset && mode4_stage3_run) begin
      add0_out_stage3_reg <= add0_out_stage3;
      add1_out_stage3_reg <= add1_out_stage3;
      add2_out_stage3_reg <= add2_out_stage3;
      add3_out_stage3_reg <= add3_out_stage3;
    end
	
	else if (reset) begin
		add0_out_stage3_reg <= 0;
		add1_out_stage3_reg <= 0;
		add2_out_stage3_reg <= 0;
		add3_out_stage3_reg <= 0;
	end
end		

always @ (posedge clk) begin
	if(~reset && mode4_stage2_run) begin
      add0_out_stage2_reg <= add0_out_stage2;
      add1_out_stage2_reg <= add1_out_stage2;
    end
	
	else if (reset) begin
		add0_out_stage2_reg <= 0;
		add1_out_stage2_reg <= 0;
	end
end		

always @ (posedge clk) begin
	if(~reset && mode4_stage1_run) begin
      add0_out_stage1_reg <= add0_out_stage1;
    end
	else if (reset) begin
	add0_out_stage1_reg <= 0;
	end
end

always @ (posedge clk) begin
	if(~reset && mode4_stage0_run) begin
		outp <= add0_out_stage0;
    end
	else if (reset) begin
		outp <= 0;
	end
end	

  wire clk_NC;
  wire rst_NC;
  wire [4:0] flags_NC0, flags_NC1, flags_NC2, flags_NC3;
  wire [4:0] flags_NC4, flags_NC5, flags_NC6, flags_NC7;

  // 0 add, 1 sub
  FPAddSub add0_stage3(.clk(clk_NC), .rst(rst_NC), .a(inp0),	.b(inp1), .operation(1'b0),	.result(add0_out_stage3), .flags(flags_NC0));
  FPAddSub add1_stage3(.clk(clk_NC), .rst(rst_NC), .a(inp2),	.b(inp3), .operation(1'b0),	.result(add1_out_stage3), .flags(flags_NC1));
  FPAddSub add2_stage3(.clk(clk_NC), .rst(rst_NC), .a(inp4),	.b(inp5), .operation(1'b0),	.result(add2_out_stage3), .flags(flags_NC2));
  FPAddSub add3_stage3(.clk(clk_NC), .rst(rst_NC), .a(inp6),	.b(inp7), .operation(1'b0),	.result(add3_out_stage3), .flags(flags_NC3));

  FPAddSub add0_stage2(.clk(clk_NC), .rst(rst_NC), .a(add0_out_stage3_reg),	.b(add1_out_stage3_reg), .operation(1'b0),	.result(add0_out_stage2), .flags(flags_NC4));
  FPAddSub add1_stage2(.clk(clk_NC), .rst(rst_NC), .a(add2_out_stage3_reg),	.b(add3_out_stage3_reg), .operation(1'b0),	.result(add1_out_stage2), .flags(flags_NC5));

  FPAddSub add0_stage1(.clk(clk_NC), .rst(rst_NC), .a(add0_out_stage2_reg),	.b(add1_out_stage2_reg), .operation(1'b0),	.result(add0_out_stage1), .flags(flags_NC6));

  FPAddSub add0_stage0(.clk(clk_NC), .rst(rst_NC), .a(outp),	.b(add0_out_stage1_reg), .operation(1'b0),	.result(add0_out_stage0), .flags(flags_NC7));


//  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage3(.a(inp0),       .b(inp1),      .z(add0_out_stage3), .rnd(3'b000),    .status());
//  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add1_stage3(.a(inp2),       .b(inp3),      .z(add1_out_stage3), .rnd(3'b000),    .status());
//  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add2_stage3(.a(inp4),       .b(inp5),      .z(add2_out_stage3), .rnd(3'b000),    .status());
//  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add3_stage3(.a(inp6),       .b(inp7),      .z(add3_out_stage3), .rnd(3'b000),    .status());
//
//  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage2(.a(add0_out_stage3_reg),       .b(add1_out_stage3_reg),      .z(add0_out_stage2), .rnd(3'b000),    .status());
//  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add1_stage2(.a(add2_out_stage3_reg),       .b(add3_out_stage3_reg),      .z(add1_out_stage2), .rnd(3'b000),    .status());
//
//  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage1(.a(add0_out_stage2_reg),       .b(add1_out_stage2_reg),      .z(add0_out_stage1), .rnd(3'b000),    .status());
//
//  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage0(.a(outp),       .b(add0_out_stage1_reg),      .z(add0_out_stage0), .rnd(3'b000),    .status());

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
  b_inp,
  outp0,
  outp1,
  outp2,
  outp3,
  outp4,
  outp5,
  outp6,
  outp7
);

  input  [`DATAWIDTH-1 : 0] a_inp0;
  input  [`DATAWIDTH-1 : 0] a_inp1;
  input  [`DATAWIDTH-1 : 0] a_inp2;
  input  [`DATAWIDTH-1 : 0] a_inp3;
  input  [`DATAWIDTH-1 : 0] a_inp4;
  input  [`DATAWIDTH-1 : 0] a_inp5;
  input  [`DATAWIDTH-1 : 0] a_inp6;
  input  [`DATAWIDTH-1 : 0] a_inp7;
  input  [`DATAWIDTH-1 : 0] b_inp;
  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  output  [`DATAWIDTH-1 : 0] outp4;
  output  [`DATAWIDTH-1 : 0] outp5;
  output  [`DATAWIDTH-1 : 0] outp6;
  output  [`DATAWIDTH-1 : 0] outp7;

  wire clk_NC;
  wire rst_NC;
  wire [4:0] flags_NC0, flags_NC1, flags_NC2, flags_NC3;
  wire [4:0] flags_NC4, flags_NC5, flags_NC6, flags_NC7;

  // 0 add, 1 sub
  FPAddSub sub0(.clk(clk_NC), .rst(rst_NC), .a(a_inp0),	.b(b_inp), .operation(1'b1),	.result(outp0), .flags(flags_NC0));
  FPAddSub sub1(.clk(clk_NC), .rst(rst_NC), .a(a_inp1),	.b(b_inp), .operation(1'b1),	.result(outp1), .flags(flags_NC1));
  FPAddSub sub2(.clk(clk_NC), .rst(rst_NC), .a(a_inp2),	.b(b_inp), .operation(1'b1),	.result(outp2), .flags(flags_NC2));
  FPAddSub sub3(.clk(clk_NC), .rst(rst_NC), .a(a_inp3),	.b(b_inp), .operation(1'b1),	.result(outp3), .flags(flags_NC3));
  FPAddSub sub4(.clk(clk_NC), .rst(rst_NC), .a(a_inp4),	.b(b_inp), .operation(1'b1),	.result(outp4), .flags(flags_NC4));
  FPAddSub sub5(.clk(clk_NC), .rst(rst_NC), .a(a_inp5),	.b(b_inp), .operation(1'b1),	.result(outp5), .flags(flags_NC5));
  FPAddSub sub6(.clk(clk_NC), .rst(rst_NC), .a(a_inp6),	.b(b_inp), .operation(1'b1),	.result(outp6), .flags(flags_NC6));
  FPAddSub sub7(.clk(clk_NC), .rst(rst_NC), .a(a_inp7),	.b(b_inp), .operation(1'b1),	.result(outp7), .flags(flags_NC7));
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub0(.a(a_inp0), .b(b_inp), .z(outp0), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub1(.a(a_inp1), .b(b_inp), .z(outp1), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub2(.a(a_inp2), .b(b_inp), .z(outp2), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub3(.a(a_inp3), .b(b_inp), .z(outp3), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub4(.a(a_inp4), .b(b_inp), .z(outp4), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub5(.a(a_inp5), .b(b_inp), .z(outp5), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub6(.a(a_inp6), .b(b_inp), .z(outp6), .rnd(3'b000), .status());
//  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub7(.a(a_inp7), .b(b_inp), .z(outp7), .rnd(3'b000), .status());
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

  clk,
  reset,
  stage_run,
  stage_run2,
  
  outp0, 
  outp1, 
  outp2, 
  outp3, 
  outp4, 
  outp5, 
  outp6, 
  outp7
);

  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;
  input  [`DATAWIDTH-1 : 0] inp4;
  input  [`DATAWIDTH-1 : 0] inp5;
  input  [`DATAWIDTH-1 : 0] inp6;
  input  [`DATAWIDTH-1 : 0] inp7;

  input  clk;
  input  reset;
  input  stage_run;
  input  stage_run2;
  
  output  [`DATAWIDTH-1 : 0] outp0;
  output  [`DATAWIDTH-1 : 0] outp1;
  output  [`DATAWIDTH-1 : 0] outp2;
  output  [`DATAWIDTH-1 : 0] outp3;
  output  [`DATAWIDTH-1 : 0] outp4;
  output  [`DATAWIDTH-1 : 0] outp5;
  output  [`DATAWIDTH-1 : 0] outp6;
  output  [`DATAWIDTH-1 : 0] outp7;
  expunit exp0(.a(inp0), .z(outp0), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp1(.a(inp1), .z(outp1), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp2(.a(inp2), .z(outp2), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp3(.a(inp3), .z(outp3), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp4(.a(inp4), .z(outp4), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp5(.a(inp5), .z(outp5), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp6(.a(inp6), .z(outp6), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
  expunit exp7(.a(inp7), .z(outp7), .status(), .stage_run(stage_run), .stage_run2(stage_run2), .clk(clk), .reset(reset));
endmodule



///////////////////////////////////////////////////
//Definition of FP16 adder/subtractor (so we'll use CLBs here)
///////////////////////////////////////////////////
`define EXPONENT 5
`define MANTISSA 10
`define ACTUAL_MANTISSA 11
`define EXPONENT_LSB 10
`define EXPONENT_MSB 14
`define MANTISSA_LSB 0
`define MANTISSA_MSB 9
`define MANTISSA_MUL_SPLIT_LSB 3
`define MANTISSA_MUL_SPLIT_MSB 9
`define SIGN 1
`define SIGN_LOC 15
`define DWIDTH (`SIGN+`EXPONENT+`MANTISSA)
`define IEEE_COMPLIANCE 1


module FPAddSub(
		clk,
		rst,
		a,
		b,
		operation,			// 0 add, 1 sub
		result,
		flags
	);
	
	// Clock and reset
	input clk ;										// Clock signal
	input rst ;										// Reset (active high, resets pipeline registers)
	
	// Input ports
	input [`DWIDTH-1:0] a ;								// Input A, a 32-bit floating point number
	input [`DWIDTH-1:0] b ;								// Input B, a 32-bit floating point number
	input operation ;								// Operation select signal
	
	// Output ports
	output [`DWIDTH-1:0] result ;						// Result of the operation
	output [4:0] flags ;							// Flags indicating exceptions according to IEEE754
	
	assign flags = 5'b0;
	adder_fp u_add(.a(a), .b(b),.out(result));
	
endmodule


//============================================================================
// Comparator module
//============================================================================

//============================================================================
//
//This Verilog source file is part of the Berkeley HardFloat IEEE Floating-Point
//Arithmetic Package, Release 1, by John R. Hauser.
//
//Copyright 2019 The Regents of the University of California.  All rights
//reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions, and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions, and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the University nor the names of its contributors may
//    be used to endorse or promote products derived from this software without
//    specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS "AS IS", AND ANY
//EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ARE
//DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
//DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//=============================================================================


module comparator(
a,
b,
aeb,
aneb,
alb,
aleb,
agb,
ageb,
unordered
);
//Default for FP16
//parameter exp = 5;
//parameter man = 10;

input [15:0] a;
input [15:0] b;
output aeb;
output aneb;
output alb;
output aleb;
output agb;
output ageb;
output unordered;

wire [16:0] a_RecFN;
wire [16:0] b_RecFN;

//Convert to Recoded representation
fNToRecFN#(5,11) convert_a(.in(a), .out(a_RecFN));  
fNToRecFN#(5,11) convert_b(.in(b), .out(b_RecFN));  

wire [4:0] except_flags;
wire less_than;
wire equal;
wire greater_than;

wire signaling;
assign signaling = 1'b0;

//Actual conversion module
compareRecFN_Fp16 compare(
.a(a_RecFN),
.b(b_RecFN),
.signaling(signaling),
.lt(less_than),
.eq(equal),
.gt(greater_than),
.unordered(unordered),
.exceptionFlags(except_flags)
);


//Result flags
assign aeb = equal;
assign aneb = ~equal;
assign alb = less_than;
assign aleb = less_than | equal;
assign agb = greater_than;
assign ageb = greater_than | equal;

endmodule



module reverseFp16 (input [9:0] in, output [9:0] out);

   assign out[0] = in[9];
   assign out[1] = in[8];
   assign out[2] = in[7];
   assign out[3] = in[6];
   assign out[4] = in[5];
   assign out[5] = in[4];
   assign out[6] = in[3];
   assign out[7] = in[2];
   assign out[8] = in[1];
   assign out[9] = in[0];
   // genvar ix;
   // generate
   //     for (ix = 0; ix < width; ix = ix + 1) begin :Bit
   //         assign out[ix] = in[width - 1 - ix];
   //     end
   // endgenerate

endmodule

module fNToRecFN#(parameter expWidth = 3, parameter sigWidth = 3) (
        input [(expWidth + sigWidth - 1):0] in,
        output [(expWidth + sigWidth):0] out
    );

    //`include "HardFloat_localFuncs.vi"
    //localparam normDistWidth = clog2(sigWidth);
    localparam normDistWidth = 4; //Hardcoding for FP16

    wire sign;
    wire [(expWidth - 1):0] expIn;
    wire [(sigWidth - 2):0] fractIn;
    assign {sign, expIn, fractIn} = in;
    wire isZeroExpIn = (expIn == 0);
    wire isZeroFractIn = (fractIn == 0);
    
   
    wire [(normDistWidth - 1):0] normDist;
    //sigwidth = 11, normDistWidth=4
    countLeadingZerosfp16 #(sigWidth - 1, normDistWidth)  countLeadingZeros(.in(fractIn), .count(normDist)); 
    wire [(sigWidth - 2):0] subnormFract = (fractIn<<normDist)<<1;
    wire [expWidth:0] adjustedExp =
        (isZeroExpIn ? normDist ^ ((1<<(expWidth + 1)) - 1) : expIn)
            + ((1<<(expWidth - 1)) | (isZeroExpIn ? 2 : 1));
    wire isZero = isZeroExpIn && isZeroFractIn;
    wire isSpecial = (adjustedExp[expWidth:(expWidth - 1)] == 'b11);
    
   
    wire [expWidth:0] exp;
    assign exp[expWidth:(expWidth - 2)] =
        isSpecial ? {2'b11, !isZeroFractIn}
            : isZero ? 3'b000 : adjustedExp[expWidth:(expWidth - 2)];
    assign exp[(expWidth - 3):0] = adjustedExp;
    assign out = {sign, exp, isZeroExpIn ? subnormFract : fractIn};

endmodule


module compareRecFN_Fp16(
  a,
  b,
  signaling,
  lt,
  eq,
  gt,
  unordered,
  exceptionFlags
  );
  //parameter expWidth = 5;
  //parameter sigWidth = 11;
  
  input [(5 + 11):0] a;
  input [(5 + 11):0] b;
  input signaling;
  output lt;
  output eq;
  output gt;
  output unordered;
  output [4:0] exceptionFlags;
   

    wire isNaNA, isInfA, isZeroA, signA;
    wire [(5 + 1):0] sExpA;
    wire [11:0] sigA;
    recFNToRawFN#(5, 11)  recFNToRawFN_a(
      .in(a), 
      .isNaN(isNaNA), 
      .isInf(isInfA), 
      .isZero(isZeroA), 
      .sign(signA), 
      .sExp(sExpA), 
      .sig(sigA)
      );
    wire isSigNaNA;
    isSigNaNRecFN#(5, 11) isSigNaN_a(.in(a), .isSigNaN(isSigNaNA));
    wire isNaNB, isInfB, isZeroB, signB;
    wire [(5 + 1):0] sExpB;
    wire [11:0] sigB;
    recFNToRawFN#(5, 11) recFNToRawFN_b(
      .in(b), 
      .isNaN(isNaNB), 
      .isInf(isInfB), 
      .isZero(isZeroB), 
      .sign(signB), 
      .sExp(sExpB), 
      .sig(sigB)
      );
    wire isSigNaNB;
    isSigNaNRecFN#(5, 11) isSigNaN_b(.in(b), .isSigNaN(isSigNaNB));
   
    wire ordered = !isNaNA && !isNaNB;
    wire bothInfs  = isInfA  && isInfB;
    wire bothZeros = isZeroA && isZeroB;
    wire eqExps = (sExpA == sExpB);
    wire common_ltMags = (sExpA < sExpB) || (eqExps && (sigA < sigB));
    wire common_eqMags = eqExps && (sigA == sigB);
    wire ordered_lt =
        !bothZeros
            && ((signA && !signB)
                    || (!bothInfs
                            && ((signA && !common_ltMags && !common_eqMags)
                                    || (!signB && common_ltMags))));
    wire ordered_eq =
        bothZeros || ((signA == signB) && (bothInfs || common_eqMags));
    
    
    wire invalid = isSigNaNA || isSigNaNB || (signaling && !ordered);
    assign lt = ordered && ordered_lt;
    assign eq = ordered && ordered_eq;
    assign gt = ordered && !ordered_lt && !ordered_eq;
    assign unordered = !ordered;
    assign exceptionFlags = {invalid, 4'b0};

endmodule



module recFNToRawFN(
  in,
  isNaN,
  isInf,
  isZero,
  sign,
  sExp,
  sig
  );
  
  parameter expWidth = 3;
  parameter sigWidth = 3;
  
  input [(expWidth + sigWidth):0] in;
  output isNaN;
  output isInf;
  output isZero;
  output sign;
  output [(expWidth + 1):0] sExp;
  output [sigWidth:0] sig;

    
    wire [expWidth:0] exp;
    wire [(sigWidth - 2):0] fract;
    assign {sign, exp, fract} = in;
    wire isSpecial = (exp>>(expWidth - 1) == 'b11);
    
    
    assign isNaN = isSpecial &&  exp[expWidth - 2];
    assign isInf = isSpecial && !exp[expWidth - 2];
    assign isZero = (exp>>(expWidth - 2) == 'b000);
    assign sExp = exp;
    assign sig = {1'b0, !isZero, fract};

endmodule



module  isSigNaNRecFN(in, isSigNaN);

  parameter expWidth = 3;
  parameter sigWidth = 3;
  
  input [(expWidth + sigWidth):0] in;
  output isSigNaN;

    wire isNaN =
        (in[(expWidth + sigWidth - 1):(expWidth + sigWidth - 3)] == 'b111);
    assign isSigNaN = isNaN && !in[sigWidth - 2];

endmodule

module countLeadingZerosfp16 #(parameter inWidth = 10, parameter countWidth = 4) (
    input [(inWidth - 1):0] in, output reg [(countWidth - 1):0] count
    );

  wire [(inWidth - 1):0] reverseIn;
  reverseFp16 reverse_in(in, reverseIn);
  wire [inWidth:0] oneLeastReverseIn =
      {1'b1, reverseIn} & ({1'b0, ~reverseIn} + 1);
		
  always@(*)
    begin
      if (oneLeastReverseIn[10] == 1)
        begin
          count = 4'd10;
        end
      else if (oneLeastReverseIn[9] == 1)
        begin
          count = 4'd9;
        end
      else if (oneLeastReverseIn[8] == 1)
        begin
          count= 4'd8;
        end
      else if (oneLeastReverseIn[7] == 1)
        begin
          count = 4'd7;
        end
      else if (oneLeastReverseIn[6] == 1)
        begin
          count = 4'd6;
        end
      else if (oneLeastReverseIn[5] == 1)
        begin
          count = 4'd5;
        end
      else if (oneLeastReverseIn[4] == 1)
        begin
          count = 4'd4;
        end
      else if (oneLeastReverseIn[3] == 1)
        begin
          count = 4'd3;
        end
      else if (oneLeastReverseIn[2] == 1)
        begin
          count = 4'd2;
        end
      else if (oneLeastReverseIn[1] == 1)
        begin
          count = 4'd1;
        end
      else
        begin
          count = 4'd0;
        end
      end

endmodule


//////////////////////////////////////////////////////
// Log unit
//////////////////////////////////////////////////////

module logunit (a, z, status);

	
	input [15:0] a;
	output [15:0] z;
	output [4:0] status;

	wire [15: 0] fxout1;
	wire [15: 0] fxout2;


	LUT1 lut1 (.addr(a[14:10]),.log(fxout1)); 
	LUT2 lut2 (.addr(a[9:4]),.log(fxout2));  

  wire clk_NC;
  wire rst_NC;

	//DW_fp_addsub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add(.a(fxout1), .b(fxout2), .rnd(3'b0), .op(1'b0), .z(z), .status(status[7:0]));
  FPAddSub add (.clk(clk_NC), .rst(rst_NC), .a(fxout1),	.b(fxout2), .operation(1'b1),	.result(z), .flags());
endmodule

module LUT1(addr, log);
    input [4:0] addr;
    output reg [15:0] log;

    always @(addr) begin
        case (addr)
			5'b0 		: log = 16'b1111110000000000;
			5'b1 		: log = 16'b1100100011011010;
			5'b10 		: log = 16'b1100100010000001;
			5'b11 		: log = 16'b1100100000101001;
			5'b100 		: log = 16'b1100011110100000;
			5'b101 		: log = 16'b1100011011101110;
			5'b110 		: log = 16'b1100011000111101;
			5'b111 		: log = 16'b1100010110001100;
			5'b1000 		: log = 16'b1100010011011010;
			5'b1001 		: log = 16'b1100010000101001;
			5'b1010 		: log = 16'b1100001011101110;
			5'b1011 		: log = 16'b1100000110001100;
			5'b1100 		: log = 16'b1100000000101001;
			5'b1101 		: log = 16'b1011110110001100;
			5'b1110 		: log = 16'b1011100110001100;
			5'b1111 		: log = 16'b0000000000000000;
			5'b10000 		: log = 16'b0011100110001100;
			5'b10001 		: log = 16'b0011110110001100;
			5'b10010 		: log = 16'b0100000000101001;
			5'b10011 		: log = 16'b0100000110001100;
			5'b10100 		: log = 16'b0100001011101110;
			5'b10101 		: log = 16'b0100010000101001;
			5'b10110 		: log = 16'b0100010011011010;
			5'b10111 		: log = 16'b0100010110001100;
			5'b11000 		: log = 16'b0100011000111101;
			5'b11001 		: log = 16'b0100011011101110;
			5'b11010 		: log = 16'b0100011110100000;
			5'b11011 		: log = 16'b0100100000101001;
			5'b11100 		: log = 16'b0100100010000001;
			5'b11101 		: log = 16'b0100100011011010;
			5'b11110 		: log = 16'b0100100100110011;
			5'b11111 		: log = 16'b0111110000000000;
        endcase
    end
endmodule

module LUT2(addr, log);
    input [5:0] addr;
    output reg [15:0] log;

    always @(addr) begin
        case (addr)
			6'b0 		: log = 16'b0000000000000000;
			6'b1 		: log = 16'b0010001111110000;
			6'b10 		: log = 16'b0010011111100001;
			6'b11 		: log = 16'b0010100111011101;
			6'b100 		: log = 16'b0010101111000011;
			6'b101 		: log = 16'b0010110011010000;
			6'b110 		: log = 16'b0010110110111100;
			6'b111 		: log = 16'b0010111010100101;
			6'b1000 		: log = 16'b0010111110001010;
			6'b1001 		: log = 16'b0011000000110110;
			6'b1010 		: log = 16'b0011000010100101;
			6'b1011 		: log = 16'b0011000100010011;
			6'b1100 		: log = 16'b0011000110000000;
			6'b1101 		: log = 16'b0011000111101011;
			6'b1110 		: log = 16'b0011001001010101;
			6'b1111 		: log = 16'b0011001010111101;
			6'b10000 		: log = 16'b0011001100100100;
			6'b10001 		: log = 16'b0011001110001010;
			6'b10010 		: log = 16'b0011001111101110;
			6'b10011 		: log = 16'b0011010000101001;
			6'b10100 		: log = 16'b0011010001011010;
			6'b10101 		: log = 16'b0011010010001010;
			6'b10110 		: log = 16'b0011010010111010;
			6'b10111 		: log = 16'b0011010011101010;
			6'b11000 		: log = 16'b0011010100011000;
			6'b11001 		: log = 16'b0011010101000111;
			6'b11010 		: log = 16'b0011010101110100;
			6'b11011 		: log = 16'b0011010110100010;
			6'b11100 		: log = 16'b0011010111001110;
			6'b11101 		: log = 16'b0011010111111011;
			6'b11110 		: log = 16'b0011011000100111;
			6'b11111 		: log = 16'b0011011001010010;
			6'b100000 		: log = 16'b0011011001111101;
			6'b100001 		: log = 16'b0011011010100111;
			6'b100010 		: log = 16'b0011011011010001;
			6'b100011 		: log = 16'b0011011011111011;
			6'b100100 		: log = 16'b0011011100100100;
			6'b100101 		: log = 16'b0011011101001101;
			6'b100110 		: log = 16'b0011011101110101;
			6'b100111 		: log = 16'b0011011110011101;
			6'b101000 		: log = 16'b0011011111000101;
			6'b101001 		: log = 16'b0011011111101100;
			6'b101010 		: log = 16'b0011100000001001;
			6'b101011 		: log = 16'b0011100000011101;
			6'b101100 		: log = 16'b0011100000110000;
			6'b101101 		: log = 16'b0011100001000010;
			6'b101110 		: log = 16'b0011100001010101;
			6'b101111 		: log = 16'b0011100001101000;
			6'b110000 		: log = 16'b0011100001111010;
			6'b110001 		: log = 16'b0011100010001100;
			6'b110010 		: log = 16'b0011100010011110;
			6'b110011 		: log = 16'b0011100010110000;
			6'b110100 		: log = 16'b0011100011000010;
			6'b110101 		: log = 16'b0011100011010100;
			6'b110110 		: log = 16'b0011100011100101;
			6'b110111 		: log = 16'b0011100011110110;
			6'b111000 		: log = 16'b0011100100000111;
			6'b111001 		: log = 16'b0011100100011000;
			6'b111010 		: log = 16'b0011100100101001;
			6'b111011 		: log = 16'b0011100100111010;
			6'b111100 		: log = 16'b0011100101001011;
			6'b111101 		: log = 16'b0011100101011011;
			6'b111110 		: log = 16'b0011100101101011;
			6'b111111 		: log = 16'b0011100101111100;
        endcase
    end
endmodule


//////////////////////////////////////////////////////
// Exponential unit
//////////////////////////////////////////////////////

module expunit (a, z, status, stage_run, stage_run2, clk, reset);

  parameter int_width = 3; // fixed point integer length
  parameter frac_width = 3; // fixed point fraction length
  	
  input [15:0] a;
  input stage_run2;
  input stage_run;
  input clk;
  input reset;
  output [15:0] z;
  output [7:0] status;
  
  wire [int_width + frac_width - 1: 0] fxout;
  wire [31:0] LUTout;
  reg  [31:0] LUTout_reg;
  reg  [31:0] LUTout_reg2;
  wire [15:0] Mult_out;
  reg  [15:0] Mult_out_reg;
  reg  [15:0] a_reg;
  
  
  always @(posedge clk) begin
    if(reset) begin
      Mult_out_reg <= 0;
      LUTout_reg <= 0;
	  LUTout_reg2 <= 0;
	  a_reg <= 0;
    end
    else if(stage_run2) begin
      LUTout_reg2 <= LUTout;
	  a_reg <= a;
    end	
	else if(stage_run) begin
      Mult_out_reg <= Mult_out;
      LUTout_reg <= LUTout_reg2;
    end
  end

  wire clk_NC, rst_NC;
        
  fptofixed_para fpfx (.fp(a), .fx(fxout));
  LUT lut(.addr(fxout[int_width + frac_width - 1 : 0]), .exp(LUTout)); 
  //DW_fp_mult #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) fpmult (.a(a), .b(LUTout[31:16]), .rnd(3'b000), .z(Mult_out), .status());
  FPMult_16 fpmult (.clk(clk_NC), .rst(rst_NC), .a(a_reg), .b(LUTout_reg2[31:16]), .result(Mult_out), .flags());
  //DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) fpsub (.a(Mult_out_reg), .b(LUTout_reg[15:0]), .rnd(3'b000), .z(z), .status(status[7:0]));
  FPAddSub fpsub (.clk(clk_NC), .rst(rst_NC), .a(Mult_out_reg),	.b(LUTout_reg[15:0]), .operation(1'b0),	.result(z), .flags());
endmodule

module fptofixed_para (
	fp,
	fx
	);
	
	parameter int_width = 3; // fixed point integer length
	parameter frac_width = 3; // fixed point fraction length

	input [15:0] fp; // Half Precision fp
	output [int_width + frac_width - 1:0] fx;  
	
	wire [15:0] Mant; // mantissa of fp
	wire [4:0] Ea; // non biased exponent
	wire [4:0] Exp; // biased exponent
	reg [15:0] sftfx; // output of shifter block
	reg [15:0] temp;
	
	assign Mant = {6'b000001, fp[9:0]};
	assign Exp = fp[14:10];
	assign Ea = Exp - 15;

	assign fx = temp[9+int_width:10-frac_width];
	

always @(sftfx)
begin
// only negetive numbers as inputs after sorting and subtraction from max
	if (Ea > int_width - 1)
		begin
			temp <= 16'hFFFF; // if there is an overflow
			
		end
	else if ( fp[14:0] == 15'b0)
		begin 
			temp <= 16'b0;
			
		end	
	else // underflow automatically becomes zero
		begin
			temp <= sftfx;
		end
end	

//DW01_ash  #(`DATAWIDTH, 5) ash( .A(Mant[15:0]), .DATA_TC(1'b0), .SH(Ea[4:0]), .SH_TC(1'b1), .B(sftfx));
reg shift_direction;
reg [3:0] shift_magnitude;
always @(*) begin
  shift_direction = Ea[4];  //if this bit is 1, that means Ea was a negative number, which means right shift. if this bit is 0, that means left shift.
  shift_magnitude = (Ea[4] ? ((~Ea[3:0]) + 1) : Ea[3:0]);  //take 2's complement to find the magnitude if negative
  sftfx = (shift_direction ? (Mant[15:0] >> shift_magnitude) : (Mant[15:0] << shift_magnitude)); //perform the actual shift
  //Mant[15:0] is unsigned, so no need to handle sign bit explicitly. zero padding is good on both direction shifts for unsigned numbers.
end

endmodule

module LUT(addr, exp);
    input [5:0] addr;
    output reg [31:0] exp;

    always @(addr) begin
        case (addr)
			6'b0 		: exp = 32'b00111011110000010011110000000000;
			6'b1 		: exp = 32'b00111010110110000011101111101010;
			6'b10 		: exp = 32'b00111010000010100011101110111110;
			6'b11 		: exp = 32'b00111001010101000011101101111111;
			6'b100 		: exp = 32'b00111000101101000011101100110100;
			6'b101 		: exp = 32'b00111000001001110011101011100000;
			6'b110 		: exp = 32'b00110111010101000011101010000111;
			6'b111 		: exp = 32'b00110110011101110011101000101010;
			6'b1000 		: exp = 32'b00110101101101010011100111001100;
			6'b1001 		: exp = 32'b00110101000010010011100101101110;
			6'b1010 		: exp = 32'b00110100011100100011100100010010;
			6'b1011 		: exp = 32'b00110011110110000011100010111000;
			6'b1100 		: exp = 32'b00110010111011000011100001100001;
			6'b1101 		: exp = 32'b00110010000111000011100000001111;
			6'b1110 		: exp = 32'b00110001011001000011011101111111;
			6'b1111 		: exp = 32'b00110000110000100011011011101010;
			6'b10000 		: exp = 32'b00110000001100110011011001011101;
			6'b10001 		: exp = 32'b00101111011010010011010111011001;
			6'b10010 		: exp = 32'b00101110100010100011010101011101;
			6'b10011 		: exp = 32'b00101101110001010011010011101010;
			6'b10100 		: exp = 32'b00101101000110000011010001111111;
			6'b10101 		: exp = 32'b00101100011111110011010000011100;
			6'b10110 		: exp = 32'b00101011111011110011001110000000;
			6'b10111 		: exp = 32'b00101011000000000011001011010110;
			6'b11000 		: exp = 32'b00101010001011010011001000111010;
			6'b11001 		: exp = 32'b00101001011101000011000110101010;
			6'b11010 		: exp = 32'b00101000110100000011000100100110;
			6'b11011 		: exp = 32'b00101000001111110011000010101101;
			6'b11100 		: exp = 32'b00100111011111100011000000111111;
			6'b11101 		: exp = 32'b00100110100111010010111110110011;
			6'b11110 		: exp = 32'b00100101110101100010111011111010;
			6'b11111 		: exp = 32'b00100101001001110010111001010001;
			6'b100000 		: exp = 32'b00100100100011000010110110111000;
			6'b100001 		: exp = 32'b00100100000000110010110100101100;
			6'b100010 		: exp = 32'b00100011000101000010110010101101;
			6'b100011 		: exp = 32'b00100010001111110010110000111001;
			6'b100100 		: exp = 32'b00100001100001000010101110100000;
			6'b100101 		: exp = 32'b00100000110111100010101011100010;
			6'b100110 		: exp = 32'b00100000010010110010101000110101;
			6'b100111 		: exp = 32'b00011111100101000010100110011001;
			6'b101000 		: exp = 32'b00011110101100000010100100001011;
			6'b101001 		: exp = 32'b00011101111001110010100010001011;
			6'b101010 		: exp = 32'b00011101001101010010100000010111;
			6'b101011 		: exp = 32'b00011100100110010010011101011101;
			6'b101100 		: exp = 32'b00011100000011110010011010100000;
			6'b101101 		: exp = 32'b00011011001010010010010111110101;
			6'b101110 		: exp = 32'b00011010010100100010010101011011;
			6'b101111 		: exp = 32'b00011001100101000010010011010000;
			6'b110000 		: exp = 32'b00011000111011000010010001010011;
			6'b110001 		: exp = 32'b00011000010110000010001111000101;
			6'b110010 		: exp = 32'b00010111101010100010001011111010;
			6'b110011 		: exp = 32'b00010110110001000010001001000011;
			6'b110100 		: exp = 32'b00010101111110000010000110011111;
			6'b110101 		: exp = 32'b00010101010001010010000100001011;
			6'b110110 		: exp = 32'b00010100101001100010000010000110;
			6'b110111 		: exp = 32'b00010100000110100010000000001110;
			6'b111000 		: exp = 32'b00010011001111100001111101000101;
			6'b111001 		: exp = 32'b00010010011001000001111010000100;
			6'b111010 		: exp = 32'b00010001101001000001110111010111;
			6'b111011 		: exp = 32'b00010000111110100001110100111011;
			6'b111100 		: exp = 32'b00010000011001000001110010101111;
			6'b111101 		: exp = 32'b00001111110000010001110000110010;
			6'b111110 		: exp = 32'b00001110110101110001101110000010;
			6'b111111 		: exp = 32'b00001110000010100001101010111001;
        endcase
    end
endmodule


//////////////////////////////////////////////////////////////////////
// Floating point multiplier
//////////////////////////////////////////////////////////////////////


`define EXPONENT 5
`define MANTISSA 10
`define ACTUAL_MANTISSA 11
`define EXPONENT_LSB 10
`define EXPONENT_MSB 14
`define MANTISSA_LSB 0
`define MANTISSA_MSB 9
`define MANTISSA_MUL_SPLIT_LSB 3
`define MANTISSA_MUL_SPLIT_MSB 9
`define SIGN 1
`define SIGN_LOC 15
`define DWIDTH (`SIGN+`EXPONENT+`MANTISSA)
`define IEEE_COMPLIANCE 1
//////////////////////////////////////////////////////////////////////////////////
//
// Create Date:    08:40:21 09/19/2012 
// Module Name:    FPMult
// Project Name: 	 Floating Point Project
// Author:			 Fredrik Brosser
//
//////////////////////////////////////////////////////////////////////////////////

module FPMult_16(
		clk,
		rst,
		a,
		b,
		result,
		flags
    );
	
	// Input Ports
	input clk ;							// Clock
	input rst ;							// Reset signal
	input [`DWIDTH-1:0] a;					// Input A, a 32-bit floating point number
	input [`DWIDTH-1:0] b;					// Input B, a 32-bit floating point number
	
	// Output ports
	output [`DWIDTH-1:0] result ;					// Product, result of the operation, 32-bit FP number
	output [4:0] flags ;				// Flags indicating exceptions according to IEEE754
	assign flags = 5'b0;
	multiply_fp u_mult_fp(.a(a), .b(b), .out(result)); 
	
		
endmodule




