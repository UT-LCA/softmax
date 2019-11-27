import os
import re
import argparse
import math

class generate_addertree():
  def __init__(self, num_inputs, dtype="float16"):
    self.num_inputs = num_inputs
    self.dtype = dtype
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
    float_match = re.search(r'float', self.dtype)
    fixed_match = re.search(r'fixed', self.dtype)
    print("")
    print("module mode4_adder_tree(")
    for iter in range(self.num_inputs):
      print("  inp%d, " % iter)
    for iter in range(self.num_add_stages_in_adder_tree):
        print("  mode4_stage%d_run," % (iter))
    print("")
    print("  clk,")
    print("  reset,")
    print("  outp")
    print(");")
    print("")

    print("  input clk;")
    print("  input reset;")
    for iter in range(self.num_inputs):
      print("  input  [`DATAWIDTH-1 : 0] inp%d; " % iter)
    print("  output [`DATAWIDTH-1 : 0] outp;")
    for iter in range(self.num_add_stages_in_adder_tree):
        print("  input mode4_stage%d_run;" % (iter))
    print("")
   
    for i in reversed(range(self.num_add_stages_in_adder_tree)):
      stageN = i;
      if i == 0:
        print("  wire   [`DATAWIDTH-1 : 0] add0_out_stage0;")
        break
      else:
        num_adders_in_stageN = int(1<<(i-1))
      for num_adder in range(num_adders_in_stageN):
        print("  wire   [`DATAWIDTH-1 : 0] add%d_out_stage%d;" % (num_adder, stageN))
        print("  reg    [`DATAWIDTH-1 : 0] add%d_out_stage%d_reg;" % (num_adder, stageN))
      print("")
    print("  reg    [`DATAWIDTH-1 : 0] outp;")
    print("")


#-----------------internal control logic------------------# 
    print("  always @(posedge clk) begin") 
    print("    if (reset) begin")
    print("      outp <= 0;")
    for i in reversed(range(self.num_add_stages_in_adder_tree)):
      stageN = i;
      if i == 0:
        break
      else:
        num_adders_in_stageN = int(1<<(i-1))
      for num_adder in range(num_adders_in_stageN):
        print("      add%d_out_stage%d_reg <= 0;" % (num_adder, stageN))
    print("    end")
    print("")
    for i in reversed(range(self.num_add_stages_in_adder_tree)):
      stageN = i;
      if i == 0:
        print("    if(~reset && mode4_stage%d_run) begin" % (stageN))
        print("      outp <= add0_out_stage0;")  
        print("    end")
        print("")
      else:
        num_adders_in_stageN = int(1<<(i-1))
        print("    if(~reset && mode4_stage%d_run) begin" % (stageN))
        for num_adder in range(num_adders_in_stageN):
          print("      add%d_out_stage%d_reg <= add%d_out_stage%d;" %(num_adder, stageN, num_adder, stageN))
        print("    end")
        print("")
    print("  end")
 
#-----------------Instantiate and connect blocks------------------# 
    for stage in reversed(range(self.num_add_stages_in_adder_tree)):
      if stage == 0:
        if(self.num_add_stages_in_adder_tree > 1):
          if float_match is not None:
            print("  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage0(.a(outp),       .b(add0_out_stage1_reg),      .z(add0_out_stage0), .rnd(3'b000),    .status());")
          elif fixed_match is not None:
            print("  DW01_add #(`DATAWIDTH) add0_stage0(.A(outp),       .B(add0_out_stage1_reg),     .CI(1'b0),  .SUM(add0_out_stage0), .CO());")
          else:
            raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, float32, fixed16, fixed32" % (self.dtype))
        else:
          if float_match is not None:
            print("  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0_stage0(.a(outp),       .b(inp0),      .z(add0_out_stage0), .rnd(3'b000),    .status());")
          elif fixed_match is not None:
            print("  DW01_add #(`DATAWIDTH) add0_stage0(.A(outp),       .B(inp0),     .CI(1'b0),  .SUM(add0_out_stage0), .CO());")
          else:
            raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, float32, fixed16, fixed32" % (self.dtype))
        print("")
        continue
     
      num_adders_in_current_stage = int(1<<(stage-1))
      num_adder_cur_stage = 0
      num_adder_last_stage = 0

      #for the left most stage
      if stage == self.num_add_stages_in_adder_tree - 1:
        inp_num = 0
        for num_adder in range(num_adders_in_current_stage):
          if float_match is not None:
            print("  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add%d_stage%d(.a(inp%d),       .b(inp%d),      .z(add%d_out_stage%d), .rnd(3'b000),    .status());" % (num_adder_cur_stage, stage, inp_num, inp_num+1, num_adder_cur_stage, stage))
          elif fixed_match is not None:
            print("  DW01_add #(`DATAWIDTH) add%d_stage%d(.A(inp%d),       .B(inp%d),    .CI(1'b0),  .SUM(add%d_out_stage%d), .CO());" % (num_adder_cur_stage, stage, inp_num, inp_num+1, num_adder_cur_stage, stage))
          else:
            raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, float32, fixed16, fixed32" % (self.dtype))
          inp_num = inp_num + 2
          num_adder_cur_stage = num_adder_cur_stage + 1
        print("")
        continue

      for num_adder in range(num_adders_in_current_stage):
        if float_match is not None:
          print("  DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add%d_stage%d(.a(add%d_out_stage%d_reg),       .b(add%d_out_stage%d_reg),      .z(add%d_out_stage%d), .rnd(3'b000),    .status());" % (num_adder_cur_stage, stage, num_adder_last_stage, stage+1, num_adder_last_stage+1, stage+1, num_adder_cur_stage, stage))
        elif fixed_match is not None:
          print("  DW01_add #(`DATAWIDTH) add%d_stage%d(.A(add%d_out_stage%d_reg),       .B(add%d_out_stage%d_reg),     .CI(1'b0), .SUM(add%d_out_stage%d), .CO());" % (num_adder_cur_stage, stage, num_adder_last_stage, stage+1, num_adder_last_stage+1, stage+1, num_adder_cur_stage, stage))
        else:
          raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, float32, fixed16, fixed32" % (self.dtype))
        num_adder_cur_stage = num_adder_cur_stage + 1
        num_adder_last_stage = num_adder_last_stage + 2
      print("")  
    print("endmodule")
    print("")
    
