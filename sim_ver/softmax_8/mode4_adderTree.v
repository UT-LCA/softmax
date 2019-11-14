`include "defines.v"

module mode4_adderTree(
  inp0,
  inp1,
  inp2,
  inp3,
  inp4,
  inp5,
  inp6,
  inp7,
 
  mode4_stage3_run,
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
  input  [`DATAWIDTH-1 : 0] inp4;
  input  [`DATAWIDTH-1 : 0] inp5;
  input  [`DATAWIDTH-1 : 0] inp6;
  input  [`DATAWIDTH-1 : 0] inp7;

  input  mode4_stage3_run;
  input  mode4_stage2_run;
  input  mode4_stage1_run;
  input  mode4_stage0_run;
  input  clk;
  input  reset;
  
  output [`DATAWIDTH-1 : 0] outp;
  reg    [`DATAWIDTH-1 : 0] outp;

  wire   [`DATAWIDTH-1 : 0] stage3_outp0;
  wire   [`DATAWIDTH-1 : 0] stage3_outp1;
  wire   [`DATAWIDTH-1 : 0] stage3_outp2;
  wire   [`DATAWIDTH-1 : 0] stage3_outp3;
  reg    [`DATAWIDTH-1 : 0] stage3_outp0_reg;
  reg    [`DATAWIDTH-1 : 0] stage3_outp1_reg;
  reg    [`DATAWIDTH-1 : 0] stage3_outp2_reg;
  reg    [`DATAWIDTH-1 : 0] stage3_outp3_reg;

  wire   [`DATAWIDTH-1 : 0] stage2_outp0;
  wire   [`DATAWIDTH-1 : 0] stage2_outp1;
  reg    [`DATAWIDTH-1 : 0] stage2_outp0_reg;
  reg    [`DATAWIDTH-1 : 0] stage2_outp1_reg;

  wire   [`DATAWIDTH-1 : 0] stage1_outp0;
  reg    [`DATAWIDTH-1 : 0] stage1_outp0_reg;

  wire   [`DATAWIDTH-1 : 0] stage0_outp0;
  always @(posedge clk) begin
    if(reset) begin
      stage3_outp0_reg <= 0; 
      stage3_outp1_reg <= 0; 
      stage3_outp2_reg <= 0; 
      stage3_outp3_reg <= 0;
 
      stage2_outp0_reg <= 0; 
      stage2_outp1_reg <= 0; 

      stage1_outp0_reg <= 0;
      outp <= 0; 
    end else if(mode4_stage3_run) begin
      stage3_outp0_reg <= stage3_outp0; 
      stage3_outp1_reg <= stage3_outp1; 
      stage3_outp2_reg <= stage3_outp2; 
      stage3_outp3_reg <= stage3_outp3;
    end

    if(~reset && mode4_stage2_run) begin
      stage2_outp0_reg <= stage2_outp0; 
      stage2_outp1_reg <= stage2_outp1; 
    end

    if(~reset && mode4_stage1_run) begin
      stage1_outp0_reg <= stage1_outp0; 
    end
    
    if(~reset && mode4_stage0_run) begin
      outp <= stage0_outp0; 
    end
  end

 /////////----------stage 3: four adders--------------/////////////
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage3_adder3(.a(inp0),       .b(inp1),      .z(stage3_outp0), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage3_adder2(.a(inp2),       .b(inp3),      .z(stage3_outp1), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage3_adder1(.a(inp4),       .b(inp5),      .z(stage3_outp2), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage3_adder0(.a(inp6),       .b(inp7),      .z(stage3_outp3), .rnd(3'b000),    .status());

 /////////----------stage 2: two adders--------------/////////////
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage2_adder1(.a(stage3_outp0_reg),       .b(stage3_outp1_reg),      .z(stage2_outp0), .rnd(3'b000),    .status());
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage2_adder0(.a(stage3_outp2_reg),       .b(stage3_outp3_reg),      .z(stage2_outp1), .rnd(3'b000),    .status());

  ////////-----------stage 1: one adder---------------////////////
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage1_adder0(.a(stage2_outp0_reg),   .b(stage2_outp1_reg),  .z(stage1_outp0), .rnd(3'b000),    .status());

  ////////-----------stage 0: one adder to accumulate results-----//////
  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage0_adder0(.a(stage1_outp0_reg), .b(outp), .z(stage0_outp0),     .rnd(3'b000),    .status());

endmodule

