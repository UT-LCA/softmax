import numpy as np
import struct
a=struct.pack("H",int("0101011101010000",2))
np.frombuffer(a, dtype =np.float16)[0]
print(a)
