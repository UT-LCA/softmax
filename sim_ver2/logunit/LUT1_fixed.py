#LUT-EXP for fixed32
import numpy as np
import math

a = np.float64(15)
temp2 = np.float64(2)
print("module LUT1(addr, log);")
print("    input [4:0] addr;")
print("    output reg [31:0] log;")
print("")
print("    always @(addr) begin")
print("        case (addr)")

for i in range (32):
	temp = np.log(temp2)
	temp3 = temp*a
	#print temp3
	temp4 = temp3*65536
	temp4 = temp4.astype("int32")
        num = bin(temp4)[2:].zfill(32)
	print("			5'b{0:b}".format(i).zfill(5)),
	print("		: log = 32'b{0};".format(num))
	a -= 1

print("        endcase")
print("    end")
print("endmodule")
