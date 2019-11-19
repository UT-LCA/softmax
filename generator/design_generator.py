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
                        "--parallelism",
                        action='store',
                        default=8,
                        type=int,
                        help='Value of parallelism knob - a power-of-2 - 1,2,4,8,...')
    parser.add_argument("-s",
                        "--storage",
                        action='store',
                        default='mem',
                        type=str,
                        help='Value of the storage knob - mem or fifo')
    parser.add_argument("-r",
                        "--precision",
                        action='store',
                        default='float16',
                        type=str,
                        help='Value of the precision knob - float16 or fixed32')
    parser.add_argument("-a",
                        "--accuracy",
                        action='store',
                        default='lut',
                        type=str,
                        help='Value of the accuracy knob - lut or dw')
    parser.add_argument("-f",
                        "--template_file",
                        action='store',
                        default="../design_template.v",
                        help='Path+Name of the top level template file')
    args = parser.parse_args()
    self.parallelism = args.parallelism
    self.storage = args.storage
    self.precision = args.precision
    self.accuracy = args.accuracy
    self.template_file = args.template_file

  def print_it(self):
    generate_defines(self.parallelism, self.precision)
    generate_includes(self.accuracy)
    generate_max_tree(self.parallelism)
    generate_sub("mode2_sub", self.parallelism)
    generate_exp("mode3_exp", self.parallelism, self.accuracy)
    generate_addertree(self.parallelism)
    generate_ln("mode5_ln", self.parallelism, self.accuracy)
    generate_sub("mode6_sub", self.parallelism)
    generate_exp("mode7_exp", self.parallelism, self.accuracy)
    generate_softmax(self.template_file, self.parallelism)

# ###############################################################
# main()
# ###############################################################
if __name__ == "__main__":
  design_generator()
