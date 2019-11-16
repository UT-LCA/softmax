import os
import re
import argparse
import math

class generate_addertree():
  def __init__(self, num_inputs):
    self.num_inputs = num_inputs
    #find if the num_inputs is a power of 2
    if ((self.num_inputs-1) & self.num_inputs) != 0:
      raise SystemError("adder tree only supports number of inputs = power of 2")
    #Example num_inputs = 16, actual inputs = 17
    self.total_number_of_inps_for_adder_tree = self.num_inputs + 1 #1 is for exp_inp
    #For num_inputs = 16, num_add_stages_in_adder_tree = 5 (5,4,3,2,1)
    self.num_add_stages_in_adder_tree = int(math.log(self.num_inputs,2)) + 1 
    #For num_inputs = 16, num_flop_stages_in_add_tree = 5 (includes the input stage. so really in this module, there should be only 4 set of flops generated)
    self.num_flop_stages_in_adder_tree = self.num_add_stages_in_adder_tree
    self.printit()
  
  def printit(self):
    print("")
    print("module mode4_adder_tree(")
    for iter in range(self.num_inputs):
      print("  inp%d, " % iter)
    print("  ex_inp,")
    print("  outp,")
    for iter in range(1,self.num_add_stages_in_adder_tree):
        print("  mode4_stage%d_run," % (iter+1))
    print("  clk,")
    print("  reset")
    print(");")
    
    print("input clk;")
    print("input reset;")
    for iter in range(self.num_inputs):
      print("input  [`DATAWIDTH-1 : 0] inp%d; " % iter)
    print("input  [`DATAWIDTH-1 : 0] ex_inp;")
    print("output [`DATAWIDTH-1 : 0] outp;")
    for iter in range(1,self.num_add_stages_in_adder_tree):
        print("output mode4_stage%d_run," % (iter+1))
    print("")
    
    #Left most stage
    #For num_inputs=16, this is stage 5 and num_adders_in_stageN = 8
    stageN = self.num_add_stages_in_adder_tree
    num_adders_in_stageN = int(self.num_inputs/2)
    input_num = 0
    output_num = 0
    for num_adder in range(num_adders_in_stageN):
      #For num_inputs=16, num_comparator will range from 0 to 7
      print("wire   [`DATAWIDTH-1 : 0] add%d_out_stage%d;" % (output_num, stageN))
      print("reg    [`DATAWIDTH-1 : 0] add%d_out_stage%d_reg;" % (output_num, stageN))
      print("always @(posedge clk) begin")
      print("  if (reset) begin")
      print("    add%d_out_stage%d_reg <= 0;" % (output_num, stageN))
      print("  end else if (mode4_stage%d_run) begin" % (stageN))
      print("    add%d_out_stage%d_reg <= add%d_out_stage%d;" % (output_num, stageN, output_num, stageN))
      print("  end")
      print("end")
      print("DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add%d_stage%d(.a(inp%d),       .b(inp%d),      .z(add%d_out_stage%d), .rnd(3'b000),    .status());" % (output_num, stageN, input_num, input_num+1, output_num, stageN))
      print("")
      input_num = input_num + 2
      output_num = output_num + 1

    for stage in reversed(range(2,self.num_add_stages_in_adder_tree)):
      #For num_inputs = 16, 'stage' will vary from 4,3,2
      num_adders_in_current_stage = int((1<<(stage-1))/2)
      num_adder_cur_stage = 0
      num_adder_next_stage = 0
      for num_adder in range(num_adders_in_current_stage):
          print("wire   [`DATAWIDTH-1 : 0] add%d_out_stage%d;" % (num_adder_next_stage, stage))
          print("reg    [`DATAWIDTH-1 : 0] add%d_out_stage%d_reg;" % (num_adder_next_stage, stage))
          print("always @(posedge clk) begin")
          print("  if (reset) begin")
          print("    add%d_out_stage%d_reg <= 0;" % (num_adder_next_stage, stage))
          print("  end else if (mode4_stage%d_run) begin" % (stage))
          print("    add%d_out_stage%d_reg <= add%d_out_stage%d;" % (num_adder_next_stage, stage, num_adder_next_stage, stage))
          print("  end")
          print("end")
          print("DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add%d_stage%d(.a(add%d_out_stage%d_reg),       .b(add%d_out_stage%d_reg),      .z(add%d_out_stage%d), .rnd(3'b000),    .status());" % (num_adder_next_stage, stage, num_adder_cur_stage, stage+1, num_adder_cur_stage+1, stage+1, num_adder_next_stage, stage))
          print("")
          num_adder_next_stage = num_adder_next_stage + 1
          num_adder_cur_stage = num_adder_cur_stage + 2
      
    print("DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add_stage1(.a(add0_out_stage2_reg),       .b(ex_inp),      .z(outp), .rnd(3'b000),    .status());")
    print("endmodule")
    print("")
    
