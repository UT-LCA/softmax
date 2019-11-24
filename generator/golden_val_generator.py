import numpy as np
import argparse
import re

parser = argparse.ArgumentParser()
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
parser.add_argument("-b",
                    "--num_blank_locations",
                    action='store',
                    default=2,
                    type=int,
                    help='Number of blank memory locations')
parser.add_argument("-r",
                    "--precision",
                    action='store',
                    default='float16',
                    type=str,
                    help='Value of the precision knob - float16 or fixed32')
parser.add_argument("-sr",
                    "--start_range",
                    action='store',
                    help='Starting value for the range you want inputs in')
parser.add_argument("-er",
                    "--end_range",
                    action='store',
                    help='Ending value for the range you want inputs in')

args = parser.parse_args()
num_inp_pins = args.num_inp_pins
num_inp_vals = args.num_inp_vals
num_blank_locations = args.num_blank_locations
start_range = args.start_range
end_range = args.end_range
precision = args.precision

#find number of bits
bitcount = re.search(r'(\d+)', precision)
if bitcount is not None:
  num_nibbles = int(int(bitcount.group(1))/4)
else:
  raise SystemExit("Unable to find number of bits from the precision string.")


for i in range(num_blank_locations):
  print('0'*num_inp_pins*num_nibbles)

float_match = re.search(r'float', precision)
fixed_match = re.search(r'fixed', precision)
if float_match is not None:
  if precision == "float32":
    astype = 'float32'
  elif precision == "float16":
    astype = 'float16'
  else:
    raise SystemExit("Incorrect float value passed for dtype. Given = %s. Supported = float16, float32" % (precision))
  input = np.random.uniform(float(start_range), float(end_range), size=(num_inp_vals,1)).astype(astype)
elif fixed_match is not None:
  if precision == "fixed32":
    astype = 'int32'
  elif precision == "fixed16":
    astype = 'uint16'
  else:
    raise SystemExit("Incorrect fixed value passed for dtype. Given = %s. Supported = fixed16, fixed32" % (precision))
  input = np.random.randint(int(start_range), int(end_range), size=(num_inp_vals,1), dtype=astype)
else:
  raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, float32, fixed16, fixed32" % (precision))
    

#Input array of type float16 populated with random values
#print("--------input value in decimal is:------------")
#input = np.random.rand(num_inp_vals,1).astype(astype)
#print(input)

#print("----------input value in hex is:--------------")
iter = 1
for x in range(input.shape[0]):
  if precision == "float16":
    H = hex(input[x][0].view('H'))[2:].zfill(4)
  elif precision == "fixed32":
    H = hex(input[x][0])[2:].zfill(8)
  else:
    raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, fixed32" % (precision))
  if (iter%num_inp_pins)==0:
    print(H)
  else:
    print(H, end="")
  iter=iter+1

#for i in range(num_inp_pins):
#  print("ffff", end="")
print('f'*(num_inp_pins)*(num_nibbles), end="")

print("")

if precision == "fixed32":
  input = input / (2**16)
  input = input.astype('float32')

#print("----------MAX value is:-----------------------")
MAX = np.max(input)
#print(MAX)
#print(hex(MAX.view('H'))[2:].zfill(4))

#Calculate e^x
#print("----------exp value in decimal is:------------")
#convert to float32 before feeding to exp unit
exp_array = np.exp(input)
#print(exp_array)

#Calculate sum(e^x)
sum_ = np.sum(exp_array)
#print(sum)

#Find prob: e^x/sum(e^x)
prob = exp_array / sum_
if precision == "fixed32":
    prob = prob * (2**16)
    prob = prob.astype('int32')

#print("--------output value in decimal is:-----------")
#print(prob)
#print("----------output value in hex is:-------------")
#iter = 1
for x in range(prob.shape[0]):
  if precision == "float16":
    H = hex(prob[x][0].view('H'))[2:].zfill(4)
  elif precision == "fixed32":
    H = hex(prob[x][0])[2:].zfill(8)
  else:
    raise SystemExit("Incorrect value passed for dtype. Given = %s. Supported = float16, fixed32" % (precision))
  #if (iter%num_inp_pins)==0:
  #  print(H)
  #else:
  #  print(H, end="")
  #iter=iter+1
  print('0'*(num_inp_pins-1)*(num_nibbles), end="")
  print(H)
