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
    #Example num_inputs = 16, actual inputs = 17
    self.total_number_of_inps_for_max_tree = self.num_inputs + 1 #1 is for exp_inp
    #For num_inputs = 16, num_comparator_stages_in_max_tree = 5 (5,4,3,2,1)
    self.num_comparator_stages_in_max_tree = int(math.log(self.num_inputs,2)) + 1 #this is not flop stages, just the stages of comparators. we don't place flops after each comparator stage. we place flops after 3 comparator stages.
    #For num_inputs = 16, num_flop_stages_in_max_tree = 2 (includes the input stage. so really in this module, there should be only 1 set of flops generated)
    self.num_flop_stages_in_max_tree = math.ceil(self.num_comparator_stages_in_max_tree/3)
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
    for iter in range(1,self.num_comparator_stages_in_max_tree):
      if stage_has_flops(iter):
        print("  mode1_stage%d_run," % (iter+1))
    print("  clk,")
    print("  reset")
    print(");")

    print("input clk;")
    print("input reset;")
    for iter in range(self.num_inputs):
      print("input  [`DATAWIDTH-1 : 0] inp%d; " % iter)
    print("input  [`DATAWIDTH-1 : 0] ex_inp;")
    print("output [`DATAWIDTH-1 : 0] outp;")
    for iter in range(1,self.num_comparator_stages_in_max_tree):
      if stage_has_flops(iter):
        print("input mode1_stage%d_run;" % (iter+1))
    print("")

    #Left most stage
    #For num_inputs=16, this is stage 5 and num_comparators_in_stageN = 8
    stageN = self.num_comparator_stages_in_max_tree
    num_comparators_in_stageN = int(self.num_inputs/2)
    input_num = 0
    output_num = 0
    for num_comparator in range(num_comparators_in_stageN):
      #For num_inputs=16, num_comparator will range from 0 to 7
      print("wire   [`DATAWIDTH-1 : 0] cmp%d_out_stage%d;" % (output_num, stageN))
      if stage_has_flops(stageN-1):
        print("reg    [`DATAWIDTH-1 : 0] cmp%d_out_stage%d_reg;" % (output_num, stageN))
        print("always @(posedge clk) begin")
        print("  if (reset) begin")
        print("    cmp%d_out_stage%d_reg <= 0;" % (output_num, stageN))
        print("  end else if (mode1_stage%d_run) begin" % (stageN))
        print("    cmp%d_out_stage%d_reg <= cmp%d_out_stage%d;" % (output_num, stageN, output_num, stageN))
        print("  end")
        print("end")
        print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp%d_stage%d(.a(inp%d),       .b(inp%d),      .z1(cmp%d_out_stage%d), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (output_num, stageN, input_num, input_num+1, output_num, stageN))
      else:
        print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp%d_stage%d(.a(inp%d),       .b(inp%d),      .z1(cmp%d_out_stage%d), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (output_num, stageN, input_num, input_num+1, output_num, stageN))
      print("")
      input_num = input_num + 2
      output_num = output_num + 1

    #Middle stages
    for stage in reversed(range(2,self.num_comparator_stages_in_max_tree)):
      #For num_inputs = 16, 'stage' will vary from 4,3,2
      num_comparators_in_current_stage = int((1<<(stage-1))/2)
      num_comparator_cur_stage = 0
      num_comparator_next_stage = 0
      for num_comparator in range(num_comparators_in_current_stage):
          print("wire   [`DATAWIDTH-1 : 0] cmp%d_out_stage%d;" % (num_comparator_next_stage, stage))
          if stage_has_flops(stage-1):
              print("reg    [`DATAWIDTH-1 : 0] cmp%d_out_stage%d_reg;" % (num_comparator_next_stage, stage))
              print("always @(posedge clk) begin")
              print("  if (reset) begin")
              print("    cmp%d_out_stage%d_reg <= 0;" % (num_comparator_next_stage, stage))
              print("  end else if (mode1_stage%d_run) begin" % (stage))
              print("    cmp%d_out_stage%d_reg <= cmp%d_out_stage%d;" % (num_comparator_next_stage, stage, num_comparator_next_stage, stage))
              print("  end")
              print("end")
          
          if stage_has_flops(stage):
              print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp%d_stage%d(.a(cmp%d_out_stage%d_reg),       .b(cmp%d_out_stage%d_reg),      .z1(cmp%d_out_stage%d), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (num_comparator_next_stage, stage, num_comparator_cur_stage, stage+1, num_comparator_cur_stage+1, stage+1, num_comparator_next_stage, stage))
          else:
              print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp%d_stage%d(.a(cmp%d_out_stage%d),       .b(cmp%d_out_stage%d),      .z1(cmp%d_out_stage%d), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (num_comparator_next_stage, stage, num_comparator_cur_stage, stage+1, num_comparator_cur_stage+1, stage+1, num_comparator_next_stage, stage))
 
          print("")
          num_comparator_next_stage = num_comparator_next_stage + 1
          num_comparator_cur_stage = num_comparator_cur_stage + 2
      
    #Last stage (Stage number = 1)
    print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp_stage1(.a(cmp0_out_stage2),       .b(ex_inp),      .z1(outp), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());")
    print("endmodule")
    print("")
    




