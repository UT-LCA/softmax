import os
import re
import argparse
import math

class generate_max_tree():
  def __init__(self, num_inputs, dtype="float16"):
    self.num_inputs = num_inputs
    self.dtype = dtype
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
    float_match = re.search(r'float', self.dtype)
    fixed_match = re.search(r'fixed', self.dtype)

    def stage_has_flops(stage):
      #we place flops after every 3 stages
      return stage%3==0

    def instantiate_comparator(name, a, b, z):
      if float_match is not None:
        print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) %s(.a(%s),       .b(%s),      .z1(%s), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (name, a, b, z))
      elif fixed_match is not None:
        print("wire %s_ge_gt;" %(z))
        print("assign %s = (%s_ge_gt==1'b1) ? %s : %s;" % (z, z, a, b))
        print("DW01_cmp2 #(`DATAWIDTH) %s(.A(%s),       .B(%s),   .LEQ(1'b0),   .TC(1'b1), .LT_LE(), .GE_GT(%s_ge_gt));" % (name, a, b, z))
      else:
        raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, float32, fixed16, fixed32" % (self.dtype))

    print("")
    print("module mode1_max_tree(")
    for iter in range(self.num_inputs):
      print("  inp%d, " % iter)
    print("")
    print("  outp,")
    print("")
    for iter in reversed(range(self.num_comparator_stages_in_max_tree)):
      if stage_has_flops(iter):
        print("  mode1_stage%d_run," % (iter))
    print("  clk,")
    print("  reset")
    print(");")

    print("  input clk;")
    print("  input reset;")
    for iter in range(self.num_comparator_stages_in_max_tree):
      if stage_has_flops(iter):
        print("  input mode1_stage%d_run;" % (iter))
    print("")
    for iter in range(self.num_inputs):
      print("  input  [`DATAWIDTH-1 : 0] inp%d; " % iter)
    print("")
    print("  output [`DATAWIDTH-1 : 0] outp;")
    print("  reg    [`DATAWIDTH-1 : 0] outp;")
    print("")

    for i in reversed(range(self.num_comparator_stages_in_max_tree)):
      stageN = i
      if i == 0:
        print("  wire   [`DATAWIDTH-1 : 0] cmp0_out_stage0;")
        continue
      num_cmps_in_stageN = int(1 << (i-1))
      for num_cmps in range(num_cmps_in_stageN):
        if stage_has_flops(stageN):
          print("  reg    [`DATAWIDTH-1 : 0] cmp%d_out_stage%d_reg;" % (num_cmps, stageN))
        print("  wire   [`DATAWIDTH-1 : 0] cmp%d_out_stage%d;" %(num_cmps, stageN))

    print("")


#-----------------internal control logic-----------------------#
    print("  always @(posedge clk) begin") 
    print("    if (reset) begin")
    print("      outp <= 0;")
    for i in reversed(range(self.num_comparator_stages_in_max_tree)):
      stageN = i;
      if i == 0:
        break
      elif(stage_has_flops(stageN)):
        num_cmps_in_stageN = int(1<<(i-1))
        for num_cmps in range(num_cmps_in_stageN):
          print("      cmp%d_out_stage%d_reg <= 0;" % (num_cmps, stageN))
    print("    end")
    print("")
    for i in reversed(range(self.num_comparator_stages_in_max_tree)):
      stageN = i;
      if i == 0:
        print("    if(~reset && mode1_stage0_run) begin")
        print("      outp <= cmp0_out_stage0;")  
        print("    end")
        print("")
      elif(stage_has_flops(stageN)):
        num_cmps_in_stageN = int(1<<(i-1))
        print("    if(~reset && mode1_stage%d_run) begin" % (stageN))
        for num_cmps in range(num_cmps_in_stageN):
          print("      cmp%d_out_stage%d_reg <= cmp%d_out_stage%d;" %(num_cmps, stageN, num_cmps, stageN))
        print("    end")
        print("")
    print("  end")
    print("")


#-----------------instantiation and connect blocks------------------#
    for stage in reversed(range(self.num_comparator_stages_in_max_tree)):
      if stage == 0:
        if(self.num_comparator_stages_in_max_tree > 1):
          instantiate_comparator(name="cmp0_stage0", a="outp", b="cmp0_out_stage1", z="cmp0_out_stage0")
          #print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage0(.a(outp),       .b(cmp0_out_stage1),      .z1(cmp0_out_stage0), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" )
        else:
          instantiate_comparator(name="cmp0_stage0", a="outp", b="inp0", z="cmp0_out_stage0")
          #print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp0_stage0(.a(outp),       .b(inp0),                 .z1(cmp0_out_stage0), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" )
        print("")
        continue
      
      num_cmps_in_current_stage = int(1 << (stage-1))
      num_cmps_cur_stage = 0
      num_cmps_last_stage = 0

      #for the left most stage
      if stage == self.num_comparator_stages_in_max_tree - 1:
        inp_num = 0
        for num_cmps in range(num_cmps_in_current_stage):
          instantiate_comparator(name=("cmp%d_stage%d" % (num_cmps_cur_stage, stage)), a=("inp%d" % inp_num), b=("inp%d" % (inp_num+1)), z=("cmp%d_out_stage%d" % (num_cmps_cur_stage, stage)) )
          #print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp%d_stage%d(.a(inp%d),       .b(inp%d),      .z1(cmp%d_out_stage%d), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (num_cmps_cur_stage, stage, inp_num, inp_num+1, num_cmps_cur_stage, stage))
          inp_num = inp_num + 2
          num_cmps_cur_stage = num_cmps_cur_stage + 1
        print("")
        continue

            
      for num_cmps in range(num_cmps_in_current_stage):
        if stage_has_flops(stage + 1):
          instantiate_comparator(name=("cmp%d_stage%d" % (num_cmps_cur_stage, stage)), a=("cmp%d_out_stage%d_reg" % (num_cmps_last_stage, stage+1)), b=("cmp%d_out_stage%d_reg" % (num_cmps_last_stage+1, stage+1)), z=("cmp%d_out_stage%d" % (num_cmps_cur_stage, stage)) )
          #print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp%d_stage%d(.a(cmp%d_out_stage%d_reg),       .b(cmp%d_out_stage%d_reg),      .z1(cmp%d_out_stage%d), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (num_cmps_cur_stage, stage, num_cmps_last_stage, stage+1, num_cmps_last_stage+1, stage+1, num_cmps_cur_stage, stage))
          num_cmps_cur_stage = num_cmps_cur_stage + 1
          num_cmps_last_stage = num_cmps_last_stage + 2
          continue

        instantiate_comparator(name=("cmp%d_stage%d" % (num_cmps_cur_stage, stage)), a=("cmp%d_out_stage%d" % (num_cmps_last_stage, stage+1)), b=("cmp%d_out_stage%d" % (num_cmps_last_stage+1, stage+1)), z=("cmp%d_out_stage%d" % (num_cmps_cur_stage, stage)) )
        #print("DW_fp_cmp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) cmp%d_stage%d(.a(cmp%d_out_stage%d),       .b(cmp%d_out_stage%d),      .z1(cmp%d_out_stage%d), .zctr(1'b0), .aeqb(), .altb(), .agtb(), .unordered(), .z0(), .status0(), .status1());" % (num_cmps_cur_stage, stage, num_cmps_last_stage, stage+1, num_cmps_last_stage+1, stage+1, num_cmps_cur_stage, stage))
        num_cmps_cur_stage = num_cmps_cur_stage + 1
        num_cmps_last_stage = num_cmps_last_stage + 2
      print("")
    print("endmodule")
    print("")
    

# ###############################################################
# main()
# ###############################################################
if __name__ == "__main__":
  generate_max_tree(32, 'fixed16')
