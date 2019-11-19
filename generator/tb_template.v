<defines>
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
  
  reg [DWIDTH-1:0] ram[MEM_SIZE-1:0];
  
  always @(posedge clk)  
  begin 
          if (we0) 
          begin 
              ram[addr0] <= d0; 
  	end
  end
  assign q0 = ram[addr0];
endmodule

//Top level testbench module
module softmax_test;

  reg reset, clk, start, init;
  wire done;
  wire  [`DATAWIDTH*`NUM-1:0] inp;
  wire  [`DATAWIDTH*`NUM-1:0] sub0_inp;
  wire  [`DATAWIDTH*`NUM-1:0] sub1_inp;
  reg   [`ADDRSIZE-1      :0] end_addr;
  reg   [`ADDRSIZE-1      :0] start_addr;

  <outp_wires>
  
  wire [`ADDRSIZE-1 :0] addr;
  wire [`ADDRSIZE-1 :0] sub0_inp_addr;
  wire [`ADDRSIZE-1 :0] sub1_inp_addr;

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

    <outp_connections>
   
    .clk(clk),
    .reset(reset),
    .init(init),
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

  initial begin
     integer parallelism = 4;
     if ($test$plusargs("parallelism")) begin
         $value$plusargs("parallelism=%d", parallelism);
     end
     else begin
        $error("Parallelism not provided on command line.");
        $finish;
     end
     <parallelism_if>
         $readmemh("mem.txt", memory1.ram);
         $readmemh("mem.txt", memory2.ram);
         $readmemh("mem.txt", memory3.ram);
         <start_addr_assign>
         <end_addr_assign>
     end
     else begin
        $error("Unsupported value of parallelism (%d)", parallelism);
        $finish;
     end
     clk = 0;
     reset = 1;
     init = 1;
     start = 0;
     #7 reset = 0;
        init  = 0;
     #2 start = 1;
     #4 start = 0;
     <delay_to_finish> 
     $finish;  
  end

  //check output values
  //golden values are located in the memory itself.
  <output_check>

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