import os
import re
import argparse
import math

class generate_max_tree():
  def __init__(self, num_inputs):
    self.num_inputs = num_inputs
    #find if the num_inputs is a power of 2
    if ((self.num_inputs-1) & self.num_inputs) != 0:
      raise SystemError("max tree only supports number of inputs = power of 2")
    self.total_number_of_inps_for_max_tree = self.num_inputs #+ 1 #1 is for exp_inp
    self.num_comparator_stages_in_max_tree = int(math.log(self.num_inp_pins,2)) + 1 #this is not flop stages, just the stages of comparators. we don't place flops after each comparator stage. we place flops after 3 comparator stages.
    self.num_flop_stages_in_max_tree = math.ceil(self.num_comparator_stages_in_adder_tree/3)
    self.printit()
  
  def printit(self):

    def stage_has_flops(stage):
				#we place flops after every 3 stages
        return stage%3==0

    print("")
    print("module mode1_max_tree(")
    for iter in range(self.num_inputs):
      print("  inp%d, " % iter)
    print("  ex_inp,")
    print("  outp,")
    print("  clk,")
    print("  reset")
    print(");")

    print("input clk;")
    print("input reset;")
    for iter in range(self.num_inputs):
      print("input  [`DATAWIDTH-1 : 0] inp%d; " % iter)
    print("input  [`DATAWIDTH-1 : 0] ex_inp;")
    print("output [`DATAWIDTH-1 : 0] outp;")
    print("")


    num_comparators_in_stage0 = int(self.num_inputs/2)
    input_num = 0
    output_num = 0
    for num_comparator in range(num_comparators_in_stage0):
      print("wire   [`DATAWIDTH-1 : 0] cmp%d_out_stage0;" % output_num)
      print("reg    [`DATAWIDTH-1 : 0] cmp%d_out_stage0_reg;" % (output_num))
      print("always @(posedge clk) begin")
      print("  if (reset) begin")
      print("    cmp%d_out_stage0_reg <= 0;" % (output_num))
      print("  end else begin")
      print("    cmp%d_out_stage0_reg <= cmp%d_out_stage0;" % (output_num, output_num))
      print("  end")
      print("end")
      print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp%d_stage0(.a(inp%d),       .b(inp%d),      .z1(cmp%d_out_stage0), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (output_num, input_num, input_num+1, output_num))
      print("")
      input_num = input_num + 2
      output_num = output_num + 1

    for stage in range(self.num_comparator_stages_in_max_tree-1):
      num_comparators_in_current_stage = (1<<(self.num_comparator_stages_in_max_tree-stage-2))
      num_comparator_cur_stage = 0
      num_comparator_next_stage = 0
      for num_comparator in range(num_comparators_in_current_stage):
          print("wire   [`DATAWIDTH-1 : 0] cmp%d_out_stage%d;" % (num_comparator_next_stage, stage+1))
					if stage_has_flops(stage):
              print("reg    [`DATAWIDTH-1 : 0] cmp%d_out_stage%d_reg;" % (num_comparator_next_stage, stage+1))
              print("always @(posedge clk) begin")
              print("  if (reset) begin")
              print("    cmp%d_out_stage%d_reg <= 0;" % (num_comparator_next_stage, stage+1))
              print("  end else begin")
              print("    cmp%d_out_stage%d_reg <= cmp%d_out_stage%d;" % (num_comparator_next_stage, stage+1, num_comparator_next_stage, stage+1))
              print("  end")
              print("end")
          
          if stage_has_flops(stage-1):
              print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp%d_stage%d(.a(cmp%d_out_stage%d_reg),       .b(cmp%d_out_stage%d_reg),      .z1(cmp%d_out_stage%d), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (num_comparator_next_stage, stage+1, num_comparator_cur_stage, stage, num_comparator_cur_stage+1, stage, num_comparator_next_stage, stage+1))
  				else:
              print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp%d_stage%d(.a(cmp%d_out_stage%d),       .b(cmp%d_out_stage%d),      .z1(cmp%d_out_stage%d), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (num_comparator_next_stage, stage+1, num_comparator_cur_stage, stage, num_comparator_cur_stage+1, stage, num_comparator_next_stage, stage+1))
 
          print("")
          num_comparator_next_stage = num_comparator_next_stage + 1
          num_comparator_cur_stage = num_comparator_cur_stage + 2
      
    print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp_extra(.a(cmp0_out_stage%d_reg),       .b(ex_inp),      .z1(outp), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (self.num_stages-1))
    print("endmodule")
    print("")
    



