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
                        "--parallelism",
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
    parser.add_argument("-a",
                        "--accuracy",
                        action='store',
                        default='lut',
                        type=str,
                        help='Value of the accuracy knob - lut or dw')
    parser.add_argument("-s",
                        "--storage",
                        action='store',
                        default='mem',
                        type=str,
                        help='Value of the storage knob - mem or reg')
    parser.add_argument("-b",
                        "--num_blank_locations",
                        action='store',
                        default=2,
                        type=int,
                        help='Number of blank memory locations')
    parser.add_argument("-sr",
                        "--start_range",
                        action='store',
                        help='Starting value for the range you want inputs in')
    parser.add_argument("-er",
                        "--end_range",
                        action='store',
                        help='Ending value for the range you want inputs in')
    args = parser.parse_args()
    self.expected = args.expected
    self.observed = args.observed
    self.parallelism = args.parallelism
    self.num_inp_vals = args.num_inp_vals
    self.precision = args.precision
    self.start_range = args.start_range
    self.end_range = args.end_range
    self.accuracy = args.accuracy
    self.storage = args.storage
    self.num_blank_locations = args.num_blank_locations
    
    #find number of bits
    bitcount = re.search(r'(\d+)', self.precision)
    if bitcount is not None:
      self.num_nibbles = int(int(bitcount.group(1))/4)
    else:
      raise SystemExit("Unable to find number of bits from the precision string.")

  def do_comp(self):
    input_values    = []
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
    line_count = 0
    for line in mem_txt_file:
      line_count = line_count + 1
      if line_count <= self.num_blank_locations:
        continue
      
      #if the all f line is found, all lines after that have the expected output
      if all_f_line_found == 1:
        line = line.rstrip()
        #extract the last part which contains the bytes. the front part just contains 0s
        expected_values.append(line[-1*self.num_nibbles:])

      #look for the line with all fs
      all_f_line = re.search('f'*self.parallelism*self.num_nibbles, line)
      if all_f_line is not None:
        all_f_line_found = 1

      #if the all f line is not found, all lines have the input
      if all_f_line_found == 0:
        line = line.rstrip()
        len_ = len(line)
        for i in range(self.parallelism):
          input_values.append(line[i*self.num_nibbles: i*self.num_nibbles+self.num_nibbles])

    assert(len(input_values) == len(observed_values)), ("input_values = %d, observed_values = %d" % (len(input_values), len(observed_values)))
    assert(len(input_values) == len(expected_values)), ("input_values = %d, expected_values = %d" % (len(input_values), len(expected_values)))

    #now, let's do the actual comparison
    print("start_range, end_range, start_end, input_value, parallelism, accuracy, precision, storage, num_inp_vals, observed, obs_dec, expected, exp_dec, obs_dec-exp_dec, abs_err")
    for observed, expected, inp_val in  zip(observed_values, expected_values, input_values):
        #convert string representing the number into magnitude
        #observed = struct.unpack('<h', bytes.fromhex(observed))[0]
        #expected = struct.unpack('<h', bytes.fromhex(expected))[0]
        obs_tmp = struct.pack("H",int(observed,16))
        obs_dec = np.frombuffer(obs_tmp, dtype=np.float16)[0]

        exp_tmp = struct.pack("H",int(expected,16))
        exp_dec = np.frombuffer(exp_tmp, dtype=np.float16)[0]
        
        print(float(self.start_range), ",", float(self.end_range), ",", float(self.start_range), " to ", float(self.end_range), ",", end="", sep="")
        print("0x", inp_val, ",", self.parallelism, ",", self.accuracy, ",", self.precision, ",", self.storage, ",", self.num_inp_vals, ",", end="", sep="")
        print("0x" + observed, ",", obs_dec, ",", "0x" + expected, ",", exp_dec, ",", obs_dec-exp_dec, ",", abs(obs_dec-exp_dec), sep="")

# ###############################################################
# main()
# ###############################################################
if __name__ == "__main__":
  compare_results()
