`include "defines.v"

module mode3_exp(
  inp0,
  inp1,
  inp2,
  inp3,
   
  outp0,
  outp1,
  outp2,
  outp3); 
  
  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;

  output [`DATAWIDTH-1 : 0] outp0;
  output [`DATAWIDTH-1 : 0] outp1;
  output [`DATAWIDTH-1 : 0] outp2;
  output [`DATAWIDTH-1 : 0] outp3;
  
  //The fourth parameter is "arch" for selecting an implementation
  //0 means area optimized, 1 means speed optimized
  //But it doesn't matter because we'll not use DW IP for EXP
  expunit exp0(.a(inp0), .z(outp0), .status());
  expunit exp1(.a(inp1), .z(outp1), .status());
  expunit exp2(.a(inp2), .z(outp2), .status());
  expunit exp3(.a(inp3), .z(outp3), .status());

endmodule

