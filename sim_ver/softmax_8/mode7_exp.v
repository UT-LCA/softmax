`include "defines.v"

module mode7_exp(
  inp0,
  inp1,
  inp2,
  inp3,
  inp4,
  inp5,
  inp6,
  inp7,
   
  outp0,
  outp1,
  outp2,
  outp3, 
  outp4,
  outp5,
  outp6,
  outp7); 
  
  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;
  input  [`DATAWIDTH-1 : 0] inp4;
  input  [`DATAWIDTH-1 : 0] inp5;
  input  [`DATAWIDTH-1 : 0] inp6;
  input  [`DATAWIDTH-1 : 0] inp7;

  output [`DATAWIDTH-1 : 0] outp0;
  output [`DATAWIDTH-1 : 0] outp1;
  output [`DATAWIDTH-1 : 0] outp2;
  output [`DATAWIDTH-1 : 0] outp3;
  output [`DATAWIDTH-1 : 0] outp4;
  output [`DATAWIDTH-1 : 0] outp5;
  output [`DATAWIDTH-1 : 0] outp6;
  output [`DATAWIDTH-1 : 0] outp7;
  
  //The fourth parameter is "arch" for selecting an implementation
  //0 means area optimized, 1 means speed optimized
  //But it doesn't matter because we'll not use DW IP for EXP
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp0(.a(inp0), .z(outp0),  .status());
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp1(.a(inp1), .z(outp1),  .status());
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp2(.a(inp2), .z(outp2),  .status());
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp3(.a(inp3), .z(outp3),  .status());
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp4(.a(inp4), .z(outp4),  .status());
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp5(.a(inp5), .z(outp5),  .status());
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp6(.a(inp6), .z(outp6),  .status());
  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0) exp7(.a(inp7), .z(outp7),  .status());

endmodule

