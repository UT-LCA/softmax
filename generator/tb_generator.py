import os
import re
import argparse
import math

# ###############################################################
# Testbench generator class
# ###############################################################
from generate_other_blocks import *
class tb_generator:
  def __init__(self):
    self.parse_args()
    self.print_it()

  def parse_args(self):
    parser = argparse.ArgumentParser()
    parser.add_argument("-p",
                        "--num_inp_pins",
                        action='store',
                        default=4,
                        type=int,
                        help='Number of input pins on the softmax block')
    parser.add_argument("-s",
                        "--storage",
                        action='store',
                        default='mem',
                        type=str,
                        help='Value of the storage knob - mem or reg')
    parser.add_argument("-r",
                        "--precision",
                        action='store',
                        default='float16',
                        type=str,
                        help='Value of the precision knob - float16 or fixed32')
    parser.add_argument("-v",
                        "--num_inp_vals",
                        action='store',
                        default=8,
                        type=int,
                        help='Number of input values to be handled by the softmax block')
    parser.add_argument("-b",
                        "--num_blank_locations",
                        action='store',
                        default=2,
                        type=int,
                        help='Number of blank locations in the memory before actual data starts')
    parser.add_argument("-f",
                        "--template_file",
                        action='store',
                        default="../tb_template.v",
                        help='Path+Name of the top level template file')
    args = parser.parse_args()
    self.template_file = args.template_file
    self.num_inp_pins = args.num_inp_pins
    self.num_inp_vals = args.num_inp_vals
    self.precision = args.precision
    self.storage = args.storage
    self.num_blank_locations = args.num_blank_locations

  def print_it(self):
    template_file = open(self.template_file, 'r')
    for line in template_file:
      line = line.rstrip()

      #Any tag found?
      tag_found = re.search(r'<.*>', line)
      if tag_found is not None:\

        #generate defines parameters
        defines_tag = re.search(r'<defines>', line)
        if defines_tag is not None: 
          generate_defines(self.num_inp_pins, "float16")

        #subx_inp_wires
        subx_inp_wires_tag = re.search(r'<subx_inp_wires', line)
        if subx_inp_wires_tag is not None:
          if self.storage == "mem":
            print("  wire  [`DATAWIDTH*`NUM-1:0] sub0_inp;")
            print("  wire  [`DATAWIDTH*`NUM-1:0] sub1_inp;")
          elif self.storage == "reg":
            pass #nothing to print
          else:
            raise SystemExit("Incorrect value of 'Storage' knob passed (%s)" % (self.storage))

        #subx_inp_addr_wires
        subx_inp_addr_wires_tag = re.search(r'<subx_inp_addr_wires', line)
        if subx_inp_addr_wires_tag is not None:
          if self.storage == "mem":
            print("  wire  [`ADDRSIZE-1:0] sub0_inp_addr;")
            print("  wire  [`ADDRSIZE-1:0] sub1_inp_addr;")
          elif self.storage == "reg":
            pass #nothing to print
          else:
            raise SystemExit("Incorrect value of 'Storage' knob passed (%s)" % (self.storage))
        
        #output port wires
        outp_wires_tag = re.search(r'<outp_wires>', line)
        if outp_wires_tag is not None: 
          for i in range(self.num_inp_pins):
            print("  wire [`DATAWIDTH-1:0] outp%d;" % (i))

        #output port connections
        outp_connections_tag = re.search(r'<outp_connections>', line)
        if outp_connections_tag is not None: 
          for i in range(self.num_inp_pins):
            print("  .outp%d(outp%d)," % (i,i))

        #subx_inp_connections
        subx_inp_connections_tag = re.search(r'<subx_inp_connections', line)
        if subx_inp_connections_tag is not None:
          if self.storage == "mem":
            print("    .sub0_inp(sub0_inp),")
            print("    .sub1_inp(sub1_inp),")
          elif self.storage == "reg":
            pass #nothing to print
          else:
            raise SystemExit("Incorrect value of 'Storage' knob passed (%s)" % (self.storage))

        #subx_inp_addr_connections
        subx_inp_addr_connections_tag = re.search(r'<subx_inp_addr_connections', line)
        if subx_inp_addr_connections_tag is not None:
          if self.storage == "mem":
            print("    .sub0_inp_addr(sub0_inp_addr),")
            print("    .sub1_inp_addr(sub1_inp_addr),")
          elif self.storage == "reg":
            pass #nothing to print
          else:
            raise SystemExit("Incorrect value of 'Storage' knob passed (%s)" % (self.storage))

        #parallelism_if
        parallelism_if_tag = re.search(r'<parallelism_if>', line)
        if parallelism_if_tag is not None:
          print("    if(parallelism==%d) begin" % (self.num_inp_pins))

        #memory2_3_inst
        memory2_3_inst_tag = re.search(r'memory2_3_inst', line)
        if memory2_3_inst_tag is not None:
          if self.storage == "mem":
            print("  ram#(data_width, `ADDRSIZE, depth) memory2 (")
            print("    .clk(clk),")
            print("    .we0(1'b0),   ")
            print("    .addr0(sub0_inp_addr),  ")
            print("    .d0({`DATAWIDTH*`NUM{1'b0}}),")
            print("    .q0(sub0_inp) ")
            print("  );")
            print("  ")
            print("  ram#(data_width, `ADDRSIZE, depth) memory3 (")
            print("    .clk(clk),")
            print("    .we0(1'b0),   ")
            print("    .addr0(sub1_inp_addr),  ")
            print("    .d0({`DATAWIDTH*`NUM{1'b0}}),")
            print("    .q0(sub1_inp) ")
            print("  );")
          elif self.storage == "reg":
            pass #nothing to print
          else:
            raise SystemExit("Incorrect value of 'Storage' knob passed (%s)" % (self.storage))
        
        #memory2_3_load
        memory2_3_load_tag = re.search(r'memory2_3_load', line)
        if memory2_3_load_tag is not None:
          if self.storage == "mem":
            print('        $readmemh("mem.txt", memory2.ram);')
            print('        $readmemh("mem.txt", memory3.ram);')
          elif self.storage == "reg":
            pass #nothing to print
          else:
            raise SystemExit("Incorrect value of 'Storage' knob passed (%s)" % (self.storage))

        #start_addr_assign
        start_addr_assign_tag = re.search(r'start_addr_assign', line)
        if start_addr_assign_tag is not None:
          print("        start_addr = `ADDRSIZE'd%d;" % (self.num_blank_locations))

        #end_addr_assign
        end_addr_assign_tag = re.search(r'end_addr_assign', line)
        if end_addr_assign_tag is not None:
          print("        end_addr = `ADDRSIZE'd%d;" % (self.num_blank_locations + int(self.num_inp_vals/self.num_inp_pins)))

        #delay_to_finish
        delay_to_finish_tag = re.search(r'delay_to_finish', line)
        if delay_to_finish_tag is not None:
          print("    #%d;" % (100*self.num_inp_vals))

        #output_check
        output_check_tag = re.search(r'output_check', line)
        if output_check_tag is not None:
          for i in range(self.num_inp_pins):
            print("  initial begin");
            print("    int iter = 0;")
            print("    @(negedge reset);")
            print("    forever begin")
            print("      @(outp%d);" % (i))
            loc_of_output = self.num_blank_locations + int(self.num_inp_vals/self.num_inp_pins) - i + self.num_inp_pins
            bitcount = re.search(r'(\d+)', self.precision)
            if bitcount is not None:
              msb = int(bitcount.group(1)) - 1
            else:
              raise SystemExit("Unable to find number of bits from the precision string.")
            #print("      if (outp%d[%d:2] !== memory1.ram[%d+iter][%d:2]) begin" % (i, msb, loc_of_output, msb))
            print("      if (($signed(outp%d - memory1.ram[%d+iter]) >= 4)  || ($signed(outp%d - memory1.ram[%d+iter]) <= -4))begin" % (i, loc_of_output, i, loc_of_output))
            #print("        $error(\"Mismatch in outp%d at location %d (expected=%%0d, actual=%%0d)\", memory1.ram[%d+iter], outp%d);" % (i, loc_of_output, loc_of_output, i))
            print("        $error(\"Mismatch in outp%d at location %d (expected=%%0h, actual=%%0h)\", memory1.ram[%d+iter], outp%d);" % (i, loc_of_output, loc_of_output, i))
            print("      end")
            print("      else begin")
            print("        $info(\"Match in outp%d at location %d (expected=%%0h, actual=%%0h)\", memory1.ram[%d+iter], outp%d);" % (i, loc_of_output, loc_of_output, i))
            print("      end")
            print("      iter = iter+%d;" % (self.num_inp_pins))
            print("    end")
            print("  end")
        
      else:      
        print(line)

# ###############################################################
# main()
# ###############################################################
if __name__ == "__main__":
  tb_generator()
