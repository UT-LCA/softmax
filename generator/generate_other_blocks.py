import os
import re
import argparse
import math

class generate_sub():
    def __init__(self, name="mode2_sub", num_inputs=4, dtype="float16"):
        self.num_inputs = num_inputs
        self.name = name
        self.dtype = dtype
        self.print_it()

    def print_it(self):
        print("")
        print("module %s(" % (self.name))
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
            float_match = re.search(r'float', self.dtype)
            fixed_match = re.search(r'fixed', self.dtype)
            if float_match is not None:
                print("  DW_fp_sub #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE) sub%d(.a(a_inp%d), .b(b_inp), .z(outp%d), .rnd(3'b000), .status());" % (iter, iter, iter))
            elif fixed_match is not None:
                print("  DW_fp_sub #(`DATAWIDTH) sub%d(.A(a_inp%d), .B(b_inp), .CI(1'b0), .DIFF(outp%d), .CO());" % (iter, iter, iter))
            else:
                raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, float32, fixed16, fixed32" % (self.dtype))
        print("endmodule")
        print("")

class generate_exp():
    def __init__(self, name="mode3_exp", num_inputs=4, implementation="dw", dtype="float16"):
        self.num_inputs = num_inputs
        self.implementation = implementation
        self.name = name
        self.dtype = dtype
        self.print_it()

    def print_it(self):
        print("")
        print("module %s(" % (self.name))
        for iter in range(self.num_inputs):
            print("  inp%d, " % iter)
        if self.implementation == "lut":
            print("")
            print("  clk,")
            print("  reset,")
            print("  stage_run,")
            print("")
        for iter in range(self.num_inputs):
            if iter==self.num_inputs-1:
                print("  outp%d" % iter)
            else:
                print("  outp%d, " % iter)
        print(");")
        print("")
        for iter in range(self.num_inputs):
            print("  input  [`DATAWIDTH-1 : 0] inp%d;" % iter)
        if self.implementation == "lut":
            print("")
            print("  input  clk;")
            print("  input  reset;")
            print("  input  stage_run;")
            print("")
        for iter in range(self.num_inputs):
            print("  output  [`DATAWIDTH-1 : 0] outp%d;" % iter)
        for iter in range(self.num_inputs):
            float_match = re.search(r'float', self.dtype)
            fixed_match = re.search(r'fixed', self.dtype)
            if float_match is not None:
                if self.implementation == "dw":
                    print("  DW_fp_exp #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE,0) exp%d(.a(inp%d), .z(outp%d), .status());" % (iter, iter, iter))
                elif self.implementation == "lut":
                    print("  expunit exp%d(.a(inp%d), .z(outp%d), .status(), .stage_run(stage_run), .clk(clk), .reset(reset));" % (iter, iter, iter))
                else:
                    raise SystemExit("Incorrect value passed for implementation to the EXP block. Given = %s. Supported = lut, dw" % (self.implementation))
            elif fixed_match is not None:
                FIXME
            else:
                raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, float32,  fixed16, fixed32" % (self.dtype))
        print("endmodule")
        print("")

class generate_ln():
    def __init__(self, name="mode5_ln", num_inputs=4, implementation="dw", dtype="float16"):
        self.num_inputs = num_inputs
        self.implementation = implementation
        self.name = name
        self.print_it()
    
    def print_it(self):
        print("")
        print("module %s(" % (self.name))
        print("inp,")
        print("outp")
        print(");")
        print("  input  [`DATAWIDTH-1 : 0] inp;")  
        print("  output [`DATAWIDTH-1 : 0] outp;")
        if self.implementation == "dw":
            print("  DW_fp_ln #(`MANTISSA, `EXPONENT, `IEEE_COMPLIANCE, 0, 0) ln(.a(inp), .z(outp), .status());")
        elif self.implementation == "lut":
            print("  logunit ln(.a(inp), .z(outp), .status());")
        else:
            raise SystemExit("Incorrect value passed for implementation to the LOG block. Given = %s. Supported = lut, dw" % (self.implementation))

        print("endmodule")
        print("")


class generate_defines():
    def __init__(self, num_inputs=4, dtype="float16", num_inp_vals=128, num_blank_locations=2):
        self.num_inputs = num_inputs
        self.dtype = dtype
        self.addr_width = math.ceil(math.log((num_inp_vals/num_inputs) + num_blank_locations + 1,2))
        self.addr_width_for_tb = math.ceil(math.log((num_inp_vals/num_inputs) + num_blank_locations + 1 + num_inp_vals,2))
        self.print_it()

    def print_it(self):
        print("")
        print("`ifndef DEFINES_DONE")
        print("`define DEFINES_DONE")
        float_match = re.search(r'float', self.dtype)
        fixed_match = re.search(r'fixed', self.dtype)
        if float_match is not None:
            if self.dtype == "float16":
                exponent_bits = 5
                mantissa_bits = 10
                sign_bits = 1
            #elif self.dtype == "bfloat16":
            #    exponent_bits = 8
            #    mantissa_bits = 7
            #    sign_bits = 1
            elif self.dtype == "float32":
                exponent_bits = 8
                mantissa_bits = 23
                sign_bits = 1
            else:
                raise SystemExit("Incorrect float value passed for dtype. Given = %s. Supported = float16, float32" % (self.dtype))
            print("`define EXPONENT %d" % (exponent_bits))
            print("`define MANTISSA %d" % (mantissa_bits))
            print("`define SIGN %d" % (sign_bits))
            print("`define DATAWIDTH (`SIGN+`EXPONENT+`MANTISSA)")
            print("`define IEEE_COMPLIANCE 1")
        elif fixed_match is not None:
            if self.dtype == "fixed32":
                print("`define DATAWIDTH 32")
            elif self.dtype == "fixed16":
                print("`define DATAWIDTH 16")
            else:
                raise SystemExit("Incorrect fixed value passed for dtype. Given = %s. Supported = fixed16, fixed32" % (self.dtype))
        else:
            raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, float32, fixed16, fixed32" % (self.dtype))
        print("`define NUM %d" % (self.num_inputs))
        print("`define ADDRSIZE %d" % (self.addr_width))
        print("`define ADDRSIZE_FOR_TB %d" % (self.addr_width_for_tb))
        print("`endif")
        print("")

class generate_includes():
    def __init__(self, accuracy="dw", dtype="float16"):
        self.accuracy = accuracy
        self.dtype = dtype
        self.print_it()
    
    def print_it(self):
        print("")
        float_match = re.search(r'float', self.dtype)
        fixed_match = re.search(r'fixed', self.dtype)
        if float_match is not None:
            print('`include "DW_fp_cmp.v"')
            print('`include "DW_fp_addsub.v"')
            print('`include "DW_fp_add.v"')
            print('`include "DW_fp_sub.v"')
            if self.accuracy=="dw":
                print('`include "DW_ln.v"')
                print('`include "DW_exp2.v"')
                print('`include "DW_fp_exp.v"')
                print('`include "DW_fp_ln.v"')
            elif self.accuracy=="lut":
                print('`include "DW_fp_mult.v"')
                print('`include "DW01_ash.v"')
                print('`include "exponentialunit.v"')
                print('`include "logunit.v"')
        elif fixed_match is not None:
            FIXME   
        else:
            raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, float32, fixed16, fixed32" % (self.dtype))
        print("")
    
