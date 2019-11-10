`include "defines.v"

//`include "DW_ram_rw_s_dff.v"

//RAM model
module ram (addr0, d0, we0, q0,  clk);

  parameter DWIDTH = 16;
  parameter AWIDTH = 10;
  parameter MEM_SIZE = 1024;
  
  input [AWIDTH-1:0] addr0;
  input [DWIDTH-1:0] d0;
  input we0;
  output [DWIDTH-1:0] q0;
  input clk;
  
  //reg [DWIDTH-1:0] q0;
  reg [DWIDTH-1:0] ram[MEM_SIZE-1:0];
  
  always @(posedge clk)  
  begin 
          if (we0) 
          begin 
              ram[addr0] <= d0; 
  	end
  end
  //assign #0.5 q0 = ram[addr0];
  assign q0 = ram[addr0];
endmodule

//Top level testbench module
module softmax_test;

  /* Make a reset that pulses once. */
  reg reset, clk, start;
  wire done;
  wire  [`DATAWIDTH*`NUM-1:0] inp;
  wire  [`DATAWIDTH*`NUM-1:0] sub0_inp;
  wire  [`DATAWIDTH*`NUM-1:0] sub1_inp;
  reg   [`ADDRSIZE-1      :0] end_addr;
  reg   [`ADDRSIZE-1      :0] start_addr;

  wire [`DATAWIDTH-1:0] outp0;
  wire [`DATAWIDTH-1:0] outp1;
  wire [`DATAWIDTH-1:0] outp2;
  wire [`DATAWIDTH-1:0] outp3;
  
  wire [`ADDRSIZE-1 :0] addr;
  wire [`ADDRSIZE-1 :0] sub0_inp_addr;
  wire [`ADDRSIZE-1 :0] sub1_inp_addr;

  //reg [`DATAWIDTH*`NUM-1:0] memory1 [`ADDRSIZE+1:0];
  //reg [`DATAWIDTH*`NUM-1:0] memory2 [`ADDRSIZE+1:0];
  //reg [`DATAWIDTH*`NUM-1:0] memory3 [`ADDRSIZE+1:0];
   
  /* top level module */
  softmax softmax(
    .inp(inp),
    .sub0_inp(sub0_inp),
    .sub1_inp(sub1_inp),
    .start_addr(start_addr),
    .end_addr(end_addr),
   
    .addr(addr),
    .sub0_inp_addr(sub0_inp_addr),
    .sub1_inp_addr(sub1_inp_addr),
    .outp0(outp0),
    .outp1(outp1),
    .outp2(outp2),
    .outp3(outp3),
   
    .clk(clk),
    .reset(reset),
    .done(done),
    .start(start)
  );

  /* on-chip memory */
  parameter data_width = `DATAWIDTH*`NUM; //each element of the memory stores these many bits
  parameter depth = (1<<`ADDRSIZE)+1; //number of elements that can be stored in the memory. 
  parameter rst_mode = 0; 
  ram#(data_width, `ADDRSIZE, depth) memory1 (
    .clk(clk),
    .we0(1'b0),   
    .addr0(addr),  
    .d0({`DATAWIDTH*`NUM{1'b0}}),
    .q0(inp) 
  );

  ram#(data_width, `ADDRSIZE, depth) memory2 (
    .clk(clk),
    .we0(1'b0),   
    .addr0(sub0_inp_addr),  
    .d0({`DATAWIDTH*`NUM{1'b0}}),
    .q0(sub0_inp) 
  );

  ram#(data_width, `ADDRSIZE, depth) memory3 (
    .clk(clk),
    .we0(1'b0),   
    .addr0(sub1_inp_addr),  
    .d0({`DATAWIDTH*`NUM{1'b0}}),
    .q0(sub1_inp) 
  );

  always #2 clk = !clk;
  //always #0.5 inp = memory1[addr];
  //always #0.5 sub0_inp = memory2[sub0_inp_addr];
  //always #0.5 sub1_inp = memory3[sub1_inp_addr];

  initial begin
     $readmemh("mem3.txt", memory1.ram);
     $readmemh("mem3.txt", memory2.ram);
     $readmemh("mem3.txt", memory3.ram);
     clk = 0;
     reset = 1;
     start = 0;
     #5 
        //inp[`DATAWIDTH-1:0]              = 16'h3800; // 0.5
        //inp[`DATAWIDTH*2-1:`DATAWIDTH]   = 16'h4040; // 2.125
	//inp[`DATAWIDTH*3-1:`DATAWIDTH*2] = 16'h4210; // 3.03125
        //inp[`DATAWIDTH*4-1:`DATAWIDTH*3] = 16'h993e; //-0.0025597

        //sub0_inp[`DATAWIDTH-1:0]              = 16'h3800; // 0.5
        //sub0_inp[`DATAWIDTH*2-1:`DATAWIDTH]   = 16'h4040; // 2.125
	//sub0_inp[`DATAWIDTH*3-1:`DATAWIDTH*2] = 16'h4210; // 3.03125
        //sub0_inp[`DATAWIDTH*4-1:`DATAWIDTH*3] = 16'h993e; //-0.0025597

        //sub1_inp[`DATAWIDTH-1:0]              = 32'h3800; // 0.5
        //sub1_inp[`DATAWIDTH*2-1:`DATAWIDTH]   = 32'h4040; // 2.125
	//sub1_inp[`DATAWIDTH*3-1:`DATAWIDTH*2] = 32'h4210; // 3.03125
        //sub1_inp[`DATAWIDTH*4-1:`DATAWIDTH*3] = 32'h993e; //-0.0025597
       
        start_addr = `ADDRSIZE'h3;
        end_addr = `ADDRSIZE'h7;
     #2 reset = 0;
     #2 start = 1;
     #4 start = 0;
     #1600 $finish;  
  end

  initial begin
     `ifndef VCS
     $dumpfile("softmax_test.vcd");
     $dumpvars(0,softmax_test);
     `else
     $vcdpluson;
     $vcdplusmemon;
     `endif
  end

endmodule // test
