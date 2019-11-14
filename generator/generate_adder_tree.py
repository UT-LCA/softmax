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
    self.num_stages = int(math.log(num_inputs,2))
    self.printit()
  
  def printit(self):
    print("module mode4_adder_tree(")
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

    num_adders_in_stage0 = int(self.num_inputs/2)
    input_num = 0
    output_num = 0
    for num_adder in range(num_adders_in_stage0):
      print("wire   [`DATAWIDTH-1 : 0] add%d_out_stage0;" % input_num)
      print("reg    [`DATAWIDTH-1 : 0] add%d_out_stage0_reg;" % (input_num))
      print("always @(posedge clk) begin")
      print("  if (reset) begin")
      print("    add%d_out_stage0_reg <= 0;" % (input_num))
      print("  end else begin")
      print("    add%d_out_stage0_reg <= add%d_out_stage0;" % (input_num, input_num))
      print("  end")
      print("end")
      print("DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0(.a(inp%d),       .b(inp%d),      .z(add%d_out_stage0), .rnd(3'b000),    .status());" % (input_num, input_num+1, output_num))
      print("")
      input_num = input_num + 2
      output_num = output_num + 1

    for stage in range(self.num_stages-1):
      num_adders_in_current_stage = (1<<(self.num_stages-stage-2))
      num_adder_cur_stage = 0
      num_adder_next_stage = 0
      for num_adder in range(num_adders_in_current_stage):
          print("wire   [`DATAWIDTH-1 : 0] add%d_out_stage%d;" % (num_adder_next_stage, stage+1))
          print("reg    [`DATAWIDTH-1 : 0] add%d_out_stage%d_reg;" % (num_adder_next_stage, stage+1))
          print("always @(posedge clk) begin")
          print("  if (reset) begin")
          print("    add%d_out_stage%d_reg <= 0;" % (num_adder_next_stage, stage+1))
          print("  end else begin")
          print("    add%d_out_stage%d_reg <= add%d_out_stage%d;" % (num_adder_next_stage, stage+1, num_adder_next_stage, stage+1))
          print("  end")
          print("end")
          print("DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0(.a(add%d_out_stage%d_reg),       .b(add%d_out_stage%d_reg),      .z(add%d_out_stage%d), .rnd(3'b000),    .status());" % (num_adder_cur_stage, stage, num_adder_cur_stage+1, stage, num_adder_next_stage, stage+1))
          print("")
          num_adder_next_stage = num_adder_next_stage + 1
          num_adder_cur_stage = num_adder_cur_stage + 2
      
    print("DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0(.a(add0_out_stage%d),       .b(ex_inp),      .z(outp), .rnd(3'b000),    .status());" % (self.num_stages-1))
    print("")
    print("endmodule")
    
generate_addertree(4)

