import numpy as np
import argparse

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

args = parser.parse_args()
num_inp_pins = args.num_inp_pins
num_inp_vals = args.num_inp_vals
num_blank_locations = args.num_blank_locations

for i in range(num_blank_locations):
  for i in range(num_inp_pins):
    print("0000", end="")
  print("")

#Input array of type float16 populated with random values
#print("--------input value in decimal is:------------")
input = np.random.rand(num_inp_vals,1).astype('float16')
#print(input)

#print("----------input value in hex is:--------------")
iter = 1
for x in range(input.shape[0]):
  H = hex(input[x][0].view('H'))[2:].zfill(4)
  if (iter%num_inp_pins)==0:
    print(H)
  else:
    print(H, end="")
  iter=iter+1

for i in range(num_inp_pins):
  print("ffff", end="")

print("")

#print("----------MAX value is:-----------------------")
MAX = np.max(input)
#print(MAX)
#print(hex(MAX.view('H'))[2:].zfill(4))

#Calculate e^x
#print("----------exp value in decimal is:------------")
exp_array = np.exp(input)
#print(exp_array)

#Calculate sum(e^x)
sum = np.sum(exp_array)
#print(sum)

#Find probabilities: e^x/sum(e^x)
probabilities = exp_array / sum
#print("--------output value in decimal is:-----------")
#print(probabilities)
#print("----------output value in hex is:-------------")
#iter = 1
for x in range(probabilities.shape[0]):
  H = hex(probabilities[x][0].view('H'))[2:].zfill(4)
  #if (iter%num_inp_pins)==0:
  #  print(H)
  #else:
  #  print(H, end="")
  #iter=iter+1
  for i in range(num_inp_pins-1):
    print("0000", end="")
  print(H)
