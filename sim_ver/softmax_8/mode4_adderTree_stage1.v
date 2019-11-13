`include "defines.v"

module mode4_adderTree_stage1(
  inp0,
  inp1,
  
  outp0); 
  
  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;

  output [`DATAWIDTH-1 : 0] outp0;

  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0(.a(inp0), .b(inp1), .z(outp0), .rnd(3'b000), .status());
            

endmodule

