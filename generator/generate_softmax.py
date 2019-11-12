import os
import re
import argparse
import math

class generate_addertree():
	def __init__(self, num_inputs):
    self.num_inputs = num_inputs
    if (self.num_inputs==1):
      raise SystemError("num_inputs = 1 is not supported yet for the adder tree")
    if (self.num_inputs % 2 != 0):
      raise SystemError("num_inputs not a multiple of 2 is not supported yet for the adder tree")
    self.num_stages = math.log(num_inputs,2)
  
  def printit(self):
		print("module mode4_adderTreee(")
    for iter in self.num_inputs:
	    print("inp%d, " % iter)
    print("ex_inp")
    print("outp")

    for iter in self.num_inputs:
      print("input  [`DATAWIDTH-1 : 0] inp%d; " % iter)
    print("input  [`DATAWIDTH-1 : 0] ex_inp;")
    print("output [`DATAWIDTH-1 : 0] outp;")

		for iter in int(self.num_stages):
			print("wire   [`DATAWIDTH-1 : 0] add%d_out;" % iter)
	  print("wire   [`DATAWIDTH-1 : 0] add%d_out;" % int(self.num_stages))

    i = self.num_inputs/2
    while i<:
      print("DW_fp_add #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) add0(.a(inp%d),       .b(inp%d),      .z(add%d_out), .rnd(3'b000),    .status());" % stage, stage+1, stage)
    

class generate_maxtree():
	def __init__(self, num_inputs):
    self.num_inputs = num_inputs
    if (self.num_inputs==1):
      raise SystemError("num_inputs = 1 is not supported yet for the max tree")
    if (self.num_inputs % 4 != 0):
      raise SystemError("num_inputs not a multiple of 4 is not supported yet for the max tree")
    self.num_stages = math.log(num_inputs,2)
  
  def printit(self):
		print("module mode1_max(")
    for iter in self.num_inputs:
	    print("inp%d, " % iter)
    print("ex_inp")
    print("outp")

    for iter in self.num_inputs:
      print("input  [`DATAWIDTH-1 : 0] inp%d; " % iter)
    print("input  [`DATAWIDTH-1 : 0] ex_inp;")
    print("output [`DATAWIDTH-1 : 0] outp;")

		for iter in int(self.num_stages):
			print("wire   [`DATAWIDTH-1 : 0] cmp%d_out;" % iter)
	  print("wire   [`DATAWIDTH-1 : 0] cmp%d_out;" % int(self.num_stages))

   

class generate_softmax():
	def __init__(self):
		pass
	
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

