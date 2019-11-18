import os
import re
import argparse
import math

from generate_other_blocks import *
from generate_adder_tree import *
from generate_max_tree import *
from generate_softmax import *

# ###############################################################
# Top-level design generator class. Calls methods from other generators.
# ###############################################################
class design_generator:
  def __init__(self):
    self.parse_args()
    self.print_it()

  def parse_args(self):
    parser = argparse.ArgumentParser()
    parser.add_argument("-p",
                        "--num_inp_pins",
                        action='store',
                        default=8,
                        type=int,
                        help='Number of input pins on the softmax block')
    parser.add_argument("-v",
                        "--num_inp_vals",
                        action='store',
                        default=4,
                        type=int,
                        help='Number of input values to be handled by the softmax block')
    parser.add_argument("-f",
                        "--template_file",
                        action='store',
                        default="../design_template.v",
                        help='Path+Name of the top level template file')
    args = parser.parse_args()
    self.template_file = args.template_file
    self.num_inp_pins = args.num_inp_pins
    self.num_inp_vals = args.num_inp_vals

  def print_it(self):
    generate_defines(self.num_inp_pins, "fp16", 16)
    generate_max_tree(self.num_inp_pins)
    generate_sub("mode2_sub", self.num_inp_pins)
    generate_exp("mode3_exp", self.num_inp_pins)
    generate_addertree(self.num_inp_pins)
    generate_ln("mode5_ln", self.num_inp_pins)
    generate_sub("mode6_sub", self.num_inp_pins)
    generate_exp("mode7_exp", self.num_inp_pins)
    generate_softmax(self.template_file, self.num_inp_pins)

# ###############################################################
# main()
# ###############################################################
if __name__ == "__main__":
  design_generator()
