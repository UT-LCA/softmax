`include "defines.v"

module mode4_adderTree_stage2(
  inp0,
  inp1,
  inp2,
  inp3,
  
  outp0,
  outp1); 
  
  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;

  output [`DATAWIDTH-1 : 0] outp0;
  output [`DATAWIDTH-1 : 0] outp1;


  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0(.a(inp0),       .b(inp1),      .z(outp0), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add1(.a(inp2),       .b(inp3),      .z(outp1), .rnd(3'b000),    .status());
            

endmodule

