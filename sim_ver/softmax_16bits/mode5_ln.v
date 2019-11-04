`define DATAWIDTH 16

module mode5_ln(
  inp,
  outp); 
  
  input  [`DATAWIDTH-1 : 0] inp;
  
  output [`DATAWIDTH-1 : 0] outp;
  
  DW_fp_ln ln(.a(inp), .z(outp));

endmodule

