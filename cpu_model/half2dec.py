import numpy as np
import struct
a=struct.pack("H",int("393a",16))
np.frombuffer(a, dtype =np.float16)[0]

hex(np.float16(2.125).view('H'))[2:].zfill(4)

