import os
import re
import argparse
import math
import struct
import numpy as np

# ###############################################################
# Class that compares the results generated from the hardware 
# with the results from the software
# ###############################################################
class compare_results:
  def __init__(self):
    self.parse_args()
    self.do_comp()

  def parse_args(self):
    parser = argparse.ArgumentParser()
    parser.add_argument("-e",
                        "--expected",
                        action='store',
                        default="mem.txt",
                        type=str,
                        help='Memory file containing the expected results')
    parser.add_argument("-o",
                        "--observed",
                        action='store',
                        default='sim.log',
                        type=str,
                        help='Simulation log file containing the observed results')
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
    parser.add_argument("-r",
                        "--precision",
                        action='store',
                        default='float16',
                        type=str,
                        help='Value of the precision knob - float16 or fixed32')
    args = parser.parse_args()
    self.expected = args.expected
    self.observed = args.observed
    self.num_inp_pins = args.num_inp_pins
    self.num_inp_vals = args.num_inp_vals
    self.precision = args.precision
    
    #find number of bits
    bitcount = re.search(r'(\d+)', self.precision)
    if bitcount is not None:
      self.num_nibbles = int(int(bitcount.group(1))/4)
    else:
      raise SystemExit("Unable to find number of bits from the precision string.")

  def do_comp(self):
    observed_values = []
    expected_values = []

    sim_log_file = open(self.observed, 'r')
    for line in sim_log_file:
      #find lines with the output printed in them
      outp = re.search(r'outp.*= (.*)', line)
      if outp is not None:
        observed_values.append(outp.group(1))
    sim_log_file.close()

    mem_txt_file = open(self.expected, 'r')
    all_f_line_found = 0
    for line in mem_txt_file:
      
      #if the all f line is found, all lines after that have the expected output
      if all_f_line_found == 1:
        line = line.rstrip()
        #extract the last part which contains the bytes. the front part just contains 0s
        expected_values.append(line[-1*self.num_nibbles:])

      #look for the line with all fs
      all_f_line = re.search('f'*self.num_inp_pins*self.num_nibbles, line)
      if all_f_line is not None:
        all_f_line_found = 1

    #now, let's do the actual comparison
    print("observed, obs_dec, expected, exp_dec, obs_dec-exp_dec")
    for observed, expected in  zip(observed_values, expected_values):
        #convert string representing the number into magnitude
        #observed = struct.unpack('<h', bytes.fromhex(observed))[0]
        #expected = struct.unpack('<h', bytes.fromhex(expected))[0]
        obs_tmp = struct.pack("H",int(observed,16))
        obs_dec = np.frombuffer(obs_tmp, dtype =np.float16)[0]

        exp_tmp = struct.pack("H",int(expected,16))
        exp_dec = np.frombuffer(exp_tmp, dtype =np.float16)[0]
        
        print("0x" + observed, ",", obs_dec, ",", "0x" + expected, ",", exp_dec, ",", obs_dec-exp_dec)

# ###############################################################
# main()
# ###############################################################
if __name__ == "__main__":
  compare_results()
