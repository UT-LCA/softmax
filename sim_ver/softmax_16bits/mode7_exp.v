`define DATAWIDTH 16

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
  
  DW_fp_exp exp0(.a(inp0), .z(outp0));
  DW_fp_exp exp1(.a(inp1), .z(outp1));
  DW_fp_exp exp2(.a(inp2), .z(outp2));
  DW_fp_exp exp3(.a(inp3), .z(outp3));

endmodule

