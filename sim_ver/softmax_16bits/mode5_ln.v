`include "defines.v"

module mode5_ln(
  inp,
  outp); 
  
  input  [`DATAWIDTH-1 : 0] inp;
  
  output [`DATAWIDTH-1 : 0] outp;
  
  //The fifth parameter is "arch" for selecting an implementation
  //0 means area optimized, 1 means speed optimized
  //But it doesn't matter because we'll not use DW IP for LN.
  //
  //The fourth parameter is "extra_prec" for internal extra precision.
  //Setting is to 0. It doesn't matter because we'll not use DW IP for LN.
  DW_fp_ln #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0, 0) ln(.a(inp), .z(outp));

endmodule

