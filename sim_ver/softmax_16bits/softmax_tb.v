`define DATAWIDTH 16
`define NUM 4
`define ADDRSIZE 8

module softmax_test;

  /* Make a reset that pulses once. */
  reg reset, clk, start_max;
  reg  [`DATAWIDTH*`NUM-1:0] inp;
  reg  [`DATAWIDTH*`NUM-1:0] sub0_inp;
  reg  [`DATAWIDTH*`NUM-1:0] sub1_inp;
  reg  [`ADDRSIZE-1      :0] addr_limit;

  wire [`DATAWIDTH-1:0] outp0;
  wire [`DATAWIDTH-1:0] outp1;
  wire [`DATAWIDTH-1:0] outp2;
  wire [`DATAWIDTH-1:0] outp3;
  
  wire [`ADDRSIZE-1 :0] addr;
  wire [`ADDRSIZE-1 :0] sub0_inp_addr;
  wire [`ADDRSIZE-1 :0] sub1_inp_addr;

  reg [`DATAWIDTH*`NUM-1:0] memory1 [`ADDRSIZE+1:0];
  reg [`DATAWIDTH*`NUM-1:0] memory2 [`ADDRSIZE+1:0];
  reg [`DATAWIDTH*`NUM-1:0] memory3 [`ADDRSIZE+1:0];
   
  softmax softmax(
    .inp(inp),
    .sub0_inp(sub0_inp),
    .sub1_inp(sub1_inp),
    .addr_limit(addr_limit),
   
    .addr(addr),
    .sub0_inp_addr(sub0_inp_addr),
    .sub1_inp_addr(sub1_inp_addr),
    .outp0(outp0),
    .outp1(outp1),
    .outp2(outp2),
    .outp3(outp3),
   
    .clk(clk),
    .reset(reset),
    .start_max(start_max)
);

  always #2 clk = !clk;
  always #0.5 inp = memory1[addr];
  always #0.5 sub0_inp = memory2[sub0_inp_addr];
  always #0.5 sub1_inp = memory3[sub1_inp_addr];
  initial begin
     $dumpfile("softmax_test.vcd");
     $dumpvars(0,softmax_test);
     $readmemh("mem1.txt", memory1);
     $readmemh("mem1.txt", memory2);
     $readmemh("mem1.txt", memory3);
     clk = 0;
     reset = 1;
     start_max = 0;
     #3 
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
       
        addr_limit = 8'h2;
     #2 reset = 0;
        start_max = 1;

     #4 start_max = 0;
     #1600 $finish;  
  end


endmodule // test
