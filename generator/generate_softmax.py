import os
import re
import argparse
import math

class generate_softmax():
  def __init__(self):
    self.parse_args()
    self.print_it()
  
  def parse_args(self):
    parser = argparse.ArgumentParser()
    parser.add_argument("-p",
                        "--num_inp_pins",
                        action='store',
                        default=4,
                        help='Number of input pins on the softmax block')
    parser.add_argument("-v",
                        "--num_inp_vals",
                        action='store',
                        default=4,
                        help='Number of input values to be handled by the softmax block')
    parser.add_argument("-f",
                        "--template_file",
                        action='store',
                        default="/mnt/c/Users/amana/DOCUME~1/WSL/softmax/softmax/generator/top_level_template.v",
                        help='Path+Name of the top level template file')
    args = parser.parse_args()
    self.template_file = args.template_file
    self.num_inp_pins = args.num_inp_pins
    self.num_inp_vals = args.num_inp_vals

  def print_it(self):
    template_file = open(self.template_file, 'r')
    for line in template_file:
      line = line.rstrip()

      #Any tag found?
      tag_found = re.search(r'<.*>', line)
      if tag_found is not None:
        #output ports
        outp_ports_tag = re.search(r'<outp_ports>', line)
        if outp_ports_tag is not None: 
          for i in range(self.num_inp_pins):
            print("  outp%d," % (i))

        #output declarations
        outp_declaration_tag = re.search(r'<outp_declaration>', line)
        if outp_declaration_tag is not None: 
          for i in range(self.num_inp_pins):
            print("  output [`DATAWIDTH-1:0] outp%d;" % (i))

        #mode1 max
        mode1_max_tag = re.search(r'<mode1_max>', line)
        if mode1_max_tag is not None:
          for i in range(self.num_inp_pins):
            print("      .inp%d(inp_reg[`DATAWIDTH*%d-1:`DATAWIDTH*%d])," % (i, i+1, i))

        #mode2 sub
        mode2_sub_tag = re.search(r'<mode2_sub>', line)
        if mode2_sub_tag is not None:
          for i in range(self.num_inp_pins):
            print("wire [`DATAWIDTH-1:0] mode2_outp_sub%d;" % (i))
          print("mode2_sub mode2_sub(")
          for i in range(self.num_inp_pins):
            print("      .a_inp%d(sub0_inp_reg[`DATAWIDTH*%d-1:`DATAWIDTH*%d])," % (i, i+1, i))
          for i in range(self.num_inp_pins):
            print("      .outp%d(mode2_outp_sub%d)," %(i,i))
          print("      .b_inp(max_outp_reg));")
          print("")
          for i in range(self.num_inp_pins):
            print("reg [`DATAWIDTH-1:0] mode2_outp_sub%d_reg;" % (i))
          print("always @(posedge clk) begin")
          print("  if (reset) begin")
          for i in range(self.num_inp_pins):
            print("    mode2_outp_sub%d_reg <= 0;" % (i))
          print("  end else if (mode2_run) begin")
          for i in range(self.num_inp_pins):
            print("    mode2_outp_sub%d_reg <= mode2_outp_sub%d;" % (i,i))
          print("  end")
          print("end")

        #mode3 exp
        mode3_exp_tag = re.search(r'<mode3_exp>', line)
        if mode3_exp_tag is not None:
          for i in range(self.num_inp_pins):
            print("wire [`DATAWIDTH-1:0] mode3_outp_exp%d;" % (i))
          print("mode3_exp mode3_exp(")
          for i in range(self.num_inp_pins):
            print("      .inp%d(mode2_outp_sub%d_reg)," % (i,i))
          for i in range(self.num_inp_pins):
            print("      .outp%d(mode3_outp_exp%d)," %(i,i))
          print("      .dummy());")
          print("")
          for i in range(self.num_inp_pins):
            print("reg [`DATAWIDTH-1:0] mode3_outp_exp%d_reg;" % (i))
          print("always @(posedge clk) begin")
          print("  if (reset) begin")
          for i in range(self.num_inp_pins):
            print("    mode3_outp_exp%d_reg <= 0;" % (i))
          print("  end else if (mode3_run) begin")
          for i in range(self.num_inp_pins):
            print("    mode3_outp_exp%d_reg <= mode3_outp_exp%d;" % (i,i))
          print("  end")
          print("end")

        #mode4 adder tree
        mode4_adder_tree_tag = re.search(r'<mode4_adder_tree>', line)
        if mode4_adder_tree_tag is not None:
          for i in range(self.num_inp_pins):
            print("  .inp%d(mode3_outp_exp%d_reg)" % (i,i))            

        #mode6 pre-sub
        mode6_pre_sub_tag = re.search(r'<mode6_presub>', line)
        if mode6_pre_sub_tag is not None:
          for i in range(self.num_inp_pins):
            print("wire [`DATAWIDTH-1:0] mode6_outp_presub%d;" % (i))
          for i in range(self.num_inp_pins):
            print("wire [`DATAWIDTH-1:0] mode6_outp_presub%d_reg;" % (i))
          print("")
          print("mode6_sub pre_sub(")
          for i in range(self.num_inp_pins):
            print("      .a_inp%d(sub1_inp_reg[`DATAWIDTH*%d-1:`DATAWIDTH*%d])," % (i, i+1, i))
          print("      .b_inp(max_outp_reg),")
          for i in range(self.num_inp_pins):
            print("      .outp%d(mode6_outp_presub%d)," % (i,i))
          print(");")
          print("always @(posedge clk) begin")
          print("  if (reset) begin")
          for i in range(self.num_inp_pins):
            print("    mode6_outp_presub%d_reg <= 0;" % (i))
          print("  end else if (presub_run) begin")
          for i in range(self.num_inp_pins):
            print("    mode6_outp_presub%d_reg <= mode6_outp_presub%d;" % (i,i))
          print("  end")
          print("end")

        #mode6 log-sub
        mode6_log_sub_tag = re.search(r'<mode6_logsub>', line)
        if mode6_log_sub_tag is not None:
          for i in range(self.num_inp_pins):
            print("wire [`DATAWIDTH-1:0] mode6_outp_logsub%d;" % (i))
          for i in range(self.num_inp_pins):
            print("wire [`DATAWIDTH-1:0] mode6_outp_logsub%d_reg;" % (i))
          print("")
          print("mode6_sub log_sub(")
          for i in range(self.num_inp_pins):
            print("      .a_inp%d(mode6_outp_presub%d_reg)," % (i, i))
          print("      .b_inp(mode5_outp_log_reg),")
          for i in range(self.num_inp_pins):
            print("      .outp%d(mode6_outp_logsub%d)," % (i,i))
          print(");")
          print("always @(posedge clk) begin")
          print("  if (reset) begin")
          for i in range(self.num_inp_pins):
            print("    mode6_outp_logsub%d_reg <= 0;" % (i))
          print("  end else if (mode6_run) begin")
          for i in range(self.num_inp_pins):
            print("    mode6_outp_logsub%d_reg <= mode6_outp_logsub%d;" % (i,i))
          print("  end")
          print("end")

        #mode7 exp
        mode7_exp_tag = re.search(r'<mode7_exp>', line)
        if mode7_exp_tag is not None:
          for i in range(self.num_inp_pins):
            print("wire [`DATAWIDTH-1:0] outp%d_temp;" % (i))
          for i in range(self.num_inp_pins):
            print("wire [`DATAWIDTH-1:0] outp%d;" % (i))
          print("")
          print("mode7_exp mode7_exp(")
          for i in range(self.num_inp_pins):
            print("      .inp%d(mode6_outp_logsub%d_reg)," % (i, i))
          for i in range(self.num_inp_pins):
            print("      .outp%d(outp%d_temp)," % (i,i))
          print(");")
          print("always @(posedge clk) begin")
          print("  if (reset) begin")
          for i in range(self.num_inp_pins):
            print("    outp%d <= 0;" % (i))
          print("  end else if (mode7_run) begin")
          for i in range(self.num_inp_pins):
            print("    outp%d <= outp%d_temp;" % (i,i))
          print("  end")
          print("end")
      else:      
        print(line)


    
generate_softmax()
