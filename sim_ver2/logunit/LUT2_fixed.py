#LUT-MANT for fixed32 (used first 12 bits of mantissa to address)
import numpy as np
import math

a = np.float64(1)
print("module LUT2(addr, log);")
print("    input [11:0] addr;")
print("    output reg [31:0] log;")
print("")
print("    always @(addr) begin")
print("        case (addr)")

for i in range (4096):
	temp = np.log(a)
	temp4 = temp*65536
	temp4 = temp4.astype("int32")
        num = bin(temp4)[2:].zfill(32)
	print("			12'b{0:b}".format(i)),
	print("		: log = 32'b{0};".format(num))
	a += np.exp2(-12)

print("        endcase")
print("    end")
print("endmodule")
