`include "defines.v"

module mode7_exp(
  inp0,
  inp1,
   
  outp0,
  outp1);
  
  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;

  output [`DATAWIDTH-1 : 0] outp0;
  output [`DATAWIDTH-1 : 0] outp1;
  
  //The fourth parameter is "arch" for selecting an implementation
  //0 means area optimized, 1 means speed optimized
  //But it doesn't matter because we'll not use DW IP for EXP
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp0(.a(inp0), .z(outp0),  .status());
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp1(.a(inp1), .z(outp1),  .status());

endmodule

