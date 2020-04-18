#use this for LUT-MANT generation for float16 with first 6 bits used to address LUT
import numpy as np
import math

a = np.float64(1)
print("module LUT2(addr, log);")
print("    input [5:0] addr;")
print("    output reg [15:0] log;")
print("")
print("    always @(addr) begin")
print("        case (addr)")

for i in range (64):
	temp = np.log(a)
	num = bin(np.float16(temp).view('H'))[2:].zfill(16)
	print("			6'b{0:b}".format(i).zfill(5)),
	print("		: log = 16'b{0};".format(num))
	a += np.exp2(-6)

print("        endcase")
print("    end")
print("endmodule")
