`define DATAWIDTH 16

module mode1_max(
  inp0,
  inp1,
  inp2,
  inp3,
  
  ex_inp,
  
  outp); 
  
  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;

  input  [`DATAWIDTH-1 : 0] ex_inp;

  output [`DATAWIDTH-1 : 0] outp;

  wire   [`DATAWIDTH-1 : 0] cmp0_out;
  wire   [`DATAWIDTH-1 : 0] cmp1_out;
  wire   [`DATAWIDTH-1 : 0] cmp2_out;

  DW_fp_cmp cmp0(.a(inp0), .b(inp1), .z1(cmp0_out), .zctr(1'b0));
  DW_fp_cmp cmp1(.a(inp2), .b(inp3), .z1(cmp1_out), .zctr(1'b0));
  DW_fp_cmp cmp2(.a(cmp0_out), .b(cmp1_out), .z1(cmp2_out), .zctr(1'b0));
   
  DW_fp_cmp ex_cmp(.a(cmp2_out), .b(ex_inp), .z1(outp), .zctr(1'b0));

endmodule

