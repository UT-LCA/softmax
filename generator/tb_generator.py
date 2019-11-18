import os
import re
import argparse
import math

# ###############################################################
# Testbench generator class
# ###############################################################
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
    self.num_blank_locations = args.num_blank_locations

  def print_it(self):
    template_file = open(self.template_file, 'r')
    for line in template_file:
      line = line.rstrip()

      #Any tag found?
      tag_found = re.search(r'<.*>', line)
      if tag_found is not None:

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

        #parallelism_if
        parallelism_if_tag = re.search(r'<parallelism_if>', line)
        if parallelism_if_tag is not None:
          print("    if(parallelism==%d) begin" % (self.num_inp_pins))
        
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
            loc_of_output = self.num_blank_locations + int(self.num_inp_vals/self.num_inp_pins) + i + 1
            print("      if (outp%d !== memory1.ram[%d+iter]) begin" % (i, loc_of_output))
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
