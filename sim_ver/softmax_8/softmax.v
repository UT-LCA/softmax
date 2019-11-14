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
  outp2,
  outp3,
  outp4,  
  outp5,
  outp6,
  outp7,
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
  output [`DATAWIDTH-1:0] outp2;
  output [`DATAWIDTH-1:0] outp3;
  output [`DATAWIDTH-1:0] outp4;
  output [`DATAWIDTH-1:0] outp5;
  output [`DATAWIDTH-1:0] outp6;
  output [`DATAWIDTH-1:0] outp7;
  output mode1_done;
  output done;
  ////-----control logic for the modes-----//////
  reg [`DATAWIDTH*`NUM-1:0] inp_reg;
  reg [`ADDRSIZE-1:0] addr;
  reg [`DATAWIDTH*`NUM-1:0] sub0_inp_reg;
  reg [`DATAWIDTH*`NUM-1:0] sub1_inp_reg;
  reg [`ADDRSIZE-1:0] sub0_inp_addr;
  reg [`ADDRSIZE-1:0] sub1_inp_addr;


  reg mode1_start;
  reg mode1_run;
  reg mode1_done;
  reg mode2_start;
  reg mode2_run;
  reg mode3_run;
 
  reg mode4_stage3_run; 
  reg mode4_stage2_run;
  reg mode4_stage1_run;
  reg mode4_stage0_run;
  reg mode4_stage1_run_a;
  reg mode4_stage2_run_a;

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

    //logic when to finish mode1 and trigger mode2 to latch the mode2 address
    if(~reset && mode1_start && addr < end_addr) begin
      addr <= addr + 1;
      inp_reg <= inp;
      mode1_run <= 1;
    end else if(addr == end_addr)begin
      mode2_start <= 1;
      sub0_inp_addr <= start_addr;
      addr <= 0;
      mode1_done <= 1;
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
    if(mode2_run == 1)begin
      mode3_run <= 1;
    end else begin
      mode3_run <= 0;
    end
    
    //logic when to trigger mode4 last stage adderTree, since the final results of adderTree
    //is always ready 1 cycle after mode3 finishes, so there is no need on extra
    //logic to control the adderTree outputs
    if(mode3_run == 1)begin
      mode4_stage3_run <= 1;
    end else begin
      mode4_stage3_run <= 0;
    end

    if(mode4_stage3_run == 1) begin
      mode4_stage2_run <= 1;
    end else begin
      mode4_stage2_run <= 0;
    end

    if(mode4_stage2_run == 1) begin
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

    //detects the falling edge of mode2, trigger presub to latch data address
    if(mode4_stage2_run_a & ~mode4_stage2_run)begin
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
                      .inp2(inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
                      .inp3(inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
                      .inp4(inp_reg[`DATAWIDTH*5-1:`DATAWIDTH*4]),
                      .inp5(inp_reg[`DATAWIDTH*6-1:`DATAWIDTH*5]),
                      .inp6(inp_reg[`DATAWIDTH*7-1:`DATAWIDTH*6]),
                      .inp7(inp_reg[`DATAWIDTH*8-1:`DATAWIDTH*7]),
		      
                      .mode1_run(mode1_run),
                      .outp(max_outp),
                      .clk(clk),
                      .reset(reset)); 

  
  ////------mode2 subtraction---------///////
  wire [`DATAWIDTH-1:0] mode2_outp_sub0;
  wire [`DATAWIDTH-1:0] mode2_outp_sub1;
  wire [`DATAWIDTH-1:0] mode2_outp_sub2;
  wire [`DATAWIDTH-1:0] mode2_outp_sub3;
  wire [`DATAWIDTH-1:0] mode2_outp_sub4;
  wire [`DATAWIDTH-1:0] mode2_outp_sub5;
  wire [`DATAWIDTH-1:0] mode2_outp_sub6;
  wire [`DATAWIDTH-1:0] mode2_outp_sub7;

  mode2_sub mode2_sub(.a_inp0(sub0_inp_reg[`DATAWIDTH-1:0]),
                      .a_inp1(sub0_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH]),
                      .a_inp2(sub0_inp_reg[`DATAWIDTH*3-1:`DATAWIDTH*2]),
                      .a_inp3(sub0_inp_reg[`DATAWIDTH*4-1:`DATAWIDTH*3]),
                      .a_inp4(sub0_inp_reg[`DATAWIDTH*5-1:`DATAWIDTH*4]),
                      .a_inp5(sub0_inp_reg[`DATAWIDTH*6-1:`DATAWIDTH*5]),
                      .a_inp6(sub0_inp_reg[`DATAWIDTH*7-1:`DATAWIDTH*6]),
                      .a_inp7(sub0_inp_reg[`DATAWIDTH*8-1:`DATAWIDTH*7]),
                      .b_inp(max_outp),
                      .outp0(mode2_outp_sub0),
                      .outp1(mode2_outp_sub1),
                      .outp2(mode2_outp_sub2),
                      .outp3(mode2_outp_sub3),
                      .outp4(mode2_outp_sub4),
                      .outp5(mode2_outp_sub5),
                      .outp6(mode2_outp_sub6),
                      .outp7(mode2_outp_sub7));
 
  reg [`DATAWIDTH-1:0] mode2_outp_sub0_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub1_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub2_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub3_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub4_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub5_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub6_reg;
  reg [`DATAWIDTH-1:0] mode2_outp_sub7_reg;
  
  always @(posedge clk)
  begin
    if(reset)begin
      mode2_outp_sub0_reg <= 0;
      mode2_outp_sub1_reg <= 0;
      mode2_outp_sub2_reg <= 0;
      mode2_outp_sub3_reg <= 0;
      mode2_outp_sub4_reg <= 0;
      mode2_outp_sub5_reg <= 0;
      mode2_outp_sub6_reg <= 0;
      mode2_outp_sub7_reg <= 0;
    end else if(mode2_run) begin
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
  
  mode3_exp mode3_exp(.inp0(mode2_outp_sub0_reg),
                      .inp1(mode2_outp_sub1_reg),
                      .inp2(mode2_outp_sub2_reg),
                      .inp3(mode2_outp_sub3_reg),
                      .inp4(mode2_outp_sub4_reg),
                      .inp5(mode2_outp_sub5_reg),
                      .inp6(mode2_outp_sub6_reg),
                      .inp7(mode2_outp_sub7_reg),
                      .outp0(mode3_outp_exp0),
                      .outp1(mode3_outp_exp1),
                      .outp2(mode3_outp_exp2),
                      .outp3(mode3_outp_exp3),
                      .outp4(mode3_outp_exp4),
                      .outp5(mode3_outp_exp5),
                      .outp6(mode3_outp_exp6),
                      .outp7(mode3_outp_exp7));
  
  reg [`DATAWIDTH-1:0] mode3_outp_exp0_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp1_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp2_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp3_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp4_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp5_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp6_reg;
  reg [`DATAWIDTH-1:0] mode3_outp_exp7_reg;
  
  always @(posedge clk) begin
    if(reset) begin
	  mode3_outp_exp0_reg <= 0;
	  mode3_outp_exp1_reg <= 0;
	  mode3_outp_exp2_reg <= 0;
	  mode3_outp_exp3_reg <= 0;
	  mode3_outp_exp4_reg <= 0;
	  mode3_outp_exp5_reg <= 0;
	  mode3_outp_exp6_reg <= 0;
	  mode3_outp_exp7_reg <= 0;
	end else if(mode3_run)begin
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
  wire [`DATAWIDTH-1:0] mode4_outp;
  mode4_adderTree adderTree(.inp0(mode3_outp_exp0_reg),
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
  wire [`DATAWIDTH-1:0] mode6_outp_presub2;
  wire [`DATAWIDTH-1:0] mode6_outp_presub3;
  wire [`DATAWIDTH-1:0] mode6_outp_presub4;
  wire [`DATAWIDTH-1:0] mode6_outp_presub5;
  wire [`DATAWIDTH-1:0] mode6_outp_presub6;
  wire [`DATAWIDTH-1:0] mode6_outp_presub7;

  reg  [`DATAWIDTH-1:0] mode6_outp_presub0_reg;
  reg  [`DATAWIDTH-1:0] mode6_outp_presub1_reg;
  reg  [`DATAWIDTH-1:0] mode6_outp_presub2_reg;
  reg  [`DATAWIDTH-1:0] mode6_outp_presub3_reg;
  reg  [`DATAWIDTH-1:0] mode6_outp_presub4_reg;
  reg  [`DATAWIDTH-1:0] mode6_outp_presub5_reg;
  reg  [`DATAWIDTH-1:0] mode6_outp_presub6_reg;
  reg  [`DATAWIDTH-1:0] mode6_outp_presub7_reg;
 
  mode6_sub pre_sub(.a_inp0(sub1_inp_reg[`DATAWIDTH-1:0]),
                    .a_inp1(sub1_inp_reg[`DATAWIDTH*2-1:`DATAWIDTH]),
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
                    .outp7(mode6_outp_presub7));

  always @(posedge clk)
  begin
    if(reset) begin
      mode6_outp_presub0_reg <= 0;
      mode6_outp_presub1_reg <= 0;
      mode6_outp_presub2_reg <= 0;
      mode6_outp_presub3_reg <= 0;
      mode6_outp_presub4_reg <= 0;
      mode6_outp_presub5_reg <= 0;
      mode6_outp_presub6_reg <= 0;
      mode6_outp_presub7_reg <= 0;
    end else if(presub_run) begin
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


  //////------mode6 sub log---------/////// 
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

  
  mode6_sub mode6_sub(.a_inp0(mode6_outp_presub0_reg),
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
                      .outp7(mode6_outp_logsub7));

  always @(posedge clk)
  begin
    if(reset) begin
      mode6_outp_logsub0_reg <= 0;
      mode6_outp_logsub1_reg <= 0;
      mode6_outp_logsub2_reg <= 0;
      mode6_outp_logsub3_reg <= 0;
      mode6_outp_logsub4_reg <= 0;
      mode6_outp_logsub5_reg <= 0;
      mode6_outp_logsub6_reg <= 0;
      mode6_outp_logsub7_reg <= 0;
    end else if(mode6_run) begin
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

  mode7_exp mode7_exp(.inp0(mode6_outp_logsub0_reg),
                      .inp1(mode6_outp_logsub1_reg),
                      .inp2(mode6_outp_logsub2_reg),
                      .inp3(mode6_outp_logsub3_reg),
                      .inp4(mode6_outp_logsub4_reg),
                      .inp5(mode6_outp_logsub5_reg),
                      .inp6(mode6_outp_logsub6_reg),
                      .inp7(mode6_outp_logsub7_reg),
                      .outp0(outp0_temp),
                      .outp1(outp1_temp),
                      .outp2(outp2_temp),
                      .outp3(outp3_temp),
                      .outp4(outp4_temp),
                      .outp5(outp5_temp),
                      .outp6(outp6_temp),
                      .outp7(outp7_temp));

  always @(posedge clk)
  begin
    if(reset) begin
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


