`include "defines.v"

module mode1_max(
  inp0,
  inp1,
    
  outp,
 
  mode1_run,
  clk,
  reset); 
  //we pipeline the max tree in every three stages  
  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;

  input  clk;
  input  reset;
  input  mode1_run;

  output [`DATAWIDTH-1 : 0] outp;
  reg    [`DATAWIDTH-1 : 0] outp;
  
  wire   stage0_run;
  assign stage0_run = mode1_run;
  
  wire   [`DATAWIDTH-1 : 0] stage1_outp0;

  wire   [`DATAWIDTH-1 : 0] stage0_outp0;


  //stage 1: one comparator
  DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage1_cmp0(.a(inp0),   .b(inp1), .z1(stage1_outp0), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
   

  //stage 0: one comparator to buffer the results
  DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage0_cmp0(.a(stage1_outp0), .b(outp),   .z1(stage0_outp0),     .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
  
  always @(posedge clk) begin
    if(reset) begin
      outp <= 0;
    end else if(stage0_run)begin
      outp <= stage0_outp0;
    end
  end

endmodule

