`include "defines.v"

module mode4_adderTree(
  inp0,
  inp1,
  inp2,
  inp3,
  
  mode4_stage2_run,
  mode4_stage1_run,
  mode4_stage0_run,
  clk,
  reset,
  outp); 
  
  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;
  
  input  mode4_stage2_run;
  input  mode4_stage1_run;
  input  mode4_stage0_run;
  input  clk;
  input  reset;

  output [`DATAWIDTH-1 : 0] outp;
  reg    [`DATAWIDTH-1 : 0] outp;

  wire   [`DATAWIDTH-1 : 0] stage2_outp0;
  wire   [`DATAWIDTH-1 : 0] stage2_outp1;
  wire   [`DATAWIDTH-1 : 0] stage1_outp0;
  wire   [`DATAWIDTH-1 : 0] stage0_outp0;

  reg    [`DATAWIDTH-1 : 0] stage2_outp0_reg;
  reg    [`DATAWIDTH-1 : 0] stage2_outp1_reg;
  reg    [`DATAWIDTH-1 : 0] stage1_outp0_reg;

   
  /////////----------stage 2: two adders--------------/////////////
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage2_adder0(.a(inp0),       .b(inp1),      .z(stage2_outp0), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage2_adder1(.a(inp2),       .b(inp3),      .z(stage2_outp1), .rnd(3'b000),    .status());
  
  always @(posedge clk) begin
    if(reset)begin
      stage2_outp0_reg <= 0;
      stage2_outp1_reg <= 0;
      stage1_outp0_reg <= 0;
      outp <= 0;
    end else if(mode4_stage2_run) begin
      stage2_outp0_reg <= stage2_outp0;
      stage2_outp1_reg <= stage2_outp1;
    end
 
    if(~reset && mode4_stage1_run)begin
      stage1_outp0_reg <= stage1_outp0;
    end

    if(~reset && mode4_stage0_run)begin
      outp <= stage0_outp0;
    end
  end

  ////////-----------stage 1: one adder---------------////////////
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage1_adder0(.a(stage2_outp0_reg),   .b(stage2_outp1_reg),  .z(stage1_outp0), .rnd(3'b000),    .status());
  
  ////////-----------stage 0: one adder to accumulate results-----//////
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage0_adder0(.a(stage1_outp0_reg), .b(outp), .z(stage0_outp0),     .rnd(3'b000),    .status());

endmodule

