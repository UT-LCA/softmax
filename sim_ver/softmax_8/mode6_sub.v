`include "defines.v"

module mode6_sub(
  a_inp0,
  a_inp1,
  a_inp2,
  a_inp3,
  a_inp4,
  a_inp5,
  a_inp6,
  a_inp7,
  
  b_inp,
  
  outp0,
  outp1,
  outp2,
  outp3, 
  outp4,
  outp5,
  outp6,
  outp7); 
  
  input  [`DATAWIDTH-1 : 0] a_inp0;
  input  [`DATAWIDTH-1 : 0] a_inp1;
  input  [`DATAWIDTH-1 : 0] a_inp2;
  input  [`DATAWIDTH-1 : 0] a_inp3;
  input  [`DATAWIDTH-1 : 0] a_inp4;
  input  [`DATAWIDTH-1 : 0] a_inp5;
  input  [`DATAWIDTH-1 : 0] a_inp6;
  input  [`DATAWIDTH-1 : 0] a_inp7;
  
  input  [`DATAWIDTH-1 : 0] b_inp;

  output [`DATAWIDTH-1 : 0] outp0;
  output [`DATAWIDTH-1 : 0] outp1;
  output [`DATAWIDTH-1 : 0] outp2;
  output [`DATAWIDTH-1 : 0] outp3;
  output [`DATAWIDTH-1 : 0] outp4;
  output [`DATAWIDTH-1 : 0] outp5;
  output [`DATAWIDTH-1 : 0] outp6;
  output [`DATAWIDTH-1 : 0] outp7;
  
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub0(.a(a_inp0), .b(b_inp), .z(outp0), .rnd(3'b000),  .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub1(.a(a_inp1), .b(b_inp), .z(outp1), .rnd(3'b000),  .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub2(.a(a_inp2), .b(b_inp), .z(outp2), .rnd(3'b000),  .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub3(.a(a_inp3), .b(b_inp), .z(outp3), .rnd(3'b000),  .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub4(.a(a_inp4), .b(b_inp), .z(outp4), .rnd(3'b000),  .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub5(.a(a_inp5), .b(b_inp), .z(outp5), .rnd(3'b000),  .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub6(.a(a_inp6), .b(b_inp), .z(outp6), .rnd(3'b000),  .status());
  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub7(.a(a_inp7), .b(b_inp), .z(outp7), .rnd(3'b000),  .status());

endmodule

