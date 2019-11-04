`define DATAWIDTH 16

module mode4_adderTree(
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

  wire   [`DATAWIDTH-1 : 0] add0_out;
  wire   [`DATAWIDTH-1 : 0] add1_out;
  wire   [`DATAWIDTH-1 : 0] add2_out;

  DW_fp_add add0(.a(inp0), .b(inp1), .z(add0_out), .rnd(3'b000));
  DW_fp_add add1(.a(inp2), .b(inp3), .z(add1_out), .rnd(3'b000));
  DW_fp_add add2(.a(add0_out), .b(add1_out), .z(add2_out), .rnd(3'b000));
   
  DW_fp_add ex_add(.a(add2_out), .b(ex_inp), .z(outp), .rnd(3'b000));

endmodule

