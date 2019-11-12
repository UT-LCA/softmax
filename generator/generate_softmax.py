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
      tag_found = re.search(r'<.*>', line)
      if tag_found is not None:
        outp_ports_tag = re.search(r'<outp_ports>', line)
        if outp_ports_tag is not None: 
          for i in range(self.num_inp_pins):
            print("  outp%d," % (i))

        outp_declaration_tag = re.search(r'<outp_declaration>', line)
        if outp_declaration_tag is not None: 
          for i in range(self.num_inp_pins):
            print("  output [`DATAWIDTH-1:0] outp%d;" % (i))

      else:      
        print(line)


    
generate_softmax()