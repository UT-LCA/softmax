`include "defines.v"

module mode1_max(
  inp0,
  inp1,
  inp2,
  inp3,
  inp4,
  inp5,
  inp6,
  inp7,
    
  outp,
 
  mode1_run,
  clk,
  reset); 
  //we pipeline the max tree in every three stages  
  input  [`DATAWIDTH-1 : 0] inp0;
  input  [`DATAWIDTH-1 : 0] inp1;
  input  [`DATAWIDTH-1 : 0] inp2;
  input  [`DATAWIDTH-1 : 0] inp3;
  input  [`DATAWIDTH-1 : 0] inp4;
  input  [`DATAWIDTH-1 : 0] inp5;
  input  [`DATAWIDTH-1 : 0] inp6;
  input  [`DATAWIDTH-1 : 0] inp7;

  input  clk;
  input  reset;
  input  mode1_run;

  output [`DATAWIDTH-1 : 0] outp;
  reg    [`DATAWIDTH-1 : 0] outp;
  
  wire   stage3_run;
  reg    stage0_run;
  assign stage3_run = mode1_run;

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
  
  wire   [`DATAWIDTH-1 : 0] stage1_outp0;

  wire   [`DATAWIDTH-1 : 0] stage0_outp0;


  //control logic inside the module
  always @(posedge clk) begin
    if(reset) begin
      stage0_run <= 0;
    end else if(stage3_run) begin
      stage0_run <= 1;
    end else begin
      stage0_run <= 0;
    end
  end

  //stage 3: four comparatos
  DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage3_cmp0(.a(inp0),       .b(inp1),     .z1(stage3_outp0), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
  DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage3_cmp1(.a(inp2),       .b(inp3),     .z1(stage3_outp1), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
  DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage3_cmp2(.a(inp4),       .b(inp5),     .z1(stage3_outp2), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
  DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage3_cmp3(.a(inp6),       .b(inp7),     .z1(stage3_outp3), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
  
  always @(posedge clk)begin
    if(reset) begin
      stage3_outp0_reg <= 0;
      stage3_outp1_reg <= 0;
      stage3_outp2_reg <= 0;
      stage3_outp3_reg <= 0;
    end else if(stage3_run)begin
      stage3_outp0_reg <= stage3_outp0;
      stage3_outp1_reg <= stage3_outp1;
      stage3_outp2_reg <= stage3_outp2;
      stage3_outp3_reg <= stage3_outp3;
    end
  end

  //stage 2: two comparators
  DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage2_cmp0(.a(stage3_outp0_reg),       .b(stage3_outp1_reg),     .z1(stage2_outp0), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
  DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage2_cmp1(.a(stage3_outp2_reg),       .b(stage3_outp3_reg),     .z1(stage2_outp1), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());


  //stage 1: one comparator
  DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage1_cmp0(.a(stage2_outp0),   .b(stage2_outp1), .z1(stage1_outp0), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());

  //stage 0: one comparator to buffer the results
  DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) stage0_cmp0(.a(stage1_outp0), .b(outp),   .z1(stage0_outp0),     .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());
  
  always @(posedge clk) begin
    if(reset) begin
      outp <= 0;
    end else if(stage0_run)begin
      outp <= stage0_outp0;
    end
  end
endmodule

