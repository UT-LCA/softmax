import os
import re
import argparse
import math

class generate_sub():
    def __init__(self, name="mode2_sub", num_inputs=4):
        self.num_inputs = num_inputs
        self.name = name
        self.print_it()

    def print_it(self):
        print("module %s()" % (self.name))
        for iter in range(self.num_inputs):
            print("  a_inp%d," % iter)
        print("  b_inp,")
        for iter in range(self.num_inputs):
            if iter==self.num_inputs-1:
                print("  outp%d" % iter)
            else:
                print("  outp%d," % iter)
        print(");")
        print("")
        for iter in range(self.num_inputs):
            print("  input  [`DATAWIDTH-1 : 0] a_inp%d;" % iter)
        print("  input  [`DATAWIDTH-1 : 0] b_inp;")
        for iter in range(self.num_inputs):
            print("  output  [`DATAWIDTH-1 : 0] outp%d;" % iter)
        for iter in range(self.num_inputs):
            print("  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub%d(.a(a_inp%d), .b(b_inp), .z(outp%d), .rnd(3'b000), .status());" % (iter, iter, iter))
        print("endmodule")

class generate_exp():
    def __init__(self, name="mode3_exp", num_inputs=4):
        self.num_inputs = num_inputs
        self.name = name
        self.print_it()

    def print_it(self):
        print("module %s()" % (self.name))
        for iter in range(self.num_inputs):
            print("  inp%d, " % iter)
        for iter in range(self.num_inputs):
            if iter==self.num_inputs-1:
                print("  outp%d" % iter)
            else:
                print("  outp%d, " % iter)
        print(");")
        print("")
        for iter in range(self.num_inputs):
            print("  input  [`DATAWIDTH-1 : 0] inp%d;" % iter)
        for iter in range(self.num_inputs):
            print("  output  [`DATAWIDTH-1 : 0] outp%d;" % iter)
        for iter in range(self.num_inputs):
            print("  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE,0) exp%d(.a(inp%d), .z(outp%d), .status());" % (iter, iter, iter))
        print("endmodule")

class generate_ln():
    def __init__(self, name="mode5_ln", num_inputs=4):
        self.num_inputs = num_inputs
        self.name = name
        self.print_it()
    
    def print_it(self):
        print("module %s()" % (self.name))
        print("inp,")
        print("outp,")
        print(");")
        print("  input  [`DATAWIDTH-1 : 0] inp;")  
        print("output [`DATAWIDTH-1 : 0] outp;")
        print("DW_fp_ln #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0, 0) ln(.a(inp), .z(outp), .status());")
        print("endmodule")


generate_sub("mode2_sub", 4)
generate_exp("mode3_exp", 4)
generate_ln("mode5_ln", 4)
generate_sub("mode6_sub", 4)
generate_exp("mode7_exp", 4)


    
