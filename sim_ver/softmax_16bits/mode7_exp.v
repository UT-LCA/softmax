`include "defines.v"

module mode7_exp(
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
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp0(.a(inp0), .z(outp0));
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp1(.a(inp1), .z(outp1));
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp2(.a(inp2), .z(outp2));
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp3(.a(inp3), .z(outp3));

endmodule

