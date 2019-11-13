`include "defines.v"

module mode4_adderTree_stage2(
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
  outp3); 
  
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

  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0(.a(inp0),       .b(inp1),      .z(outp0), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add1(.a(inp2),       .b(inp3),      .z(outp1), .rnd(3'b000),    .status());
            

  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0(.a(inp4),       .b(inp5),      .z(outp2), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0(.a(inp0),       .b(inp1),      .z(outp0), .rnd(3'b000),    .status());
endmodule

