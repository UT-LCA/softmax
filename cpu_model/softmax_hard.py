import numpy as np
import argparse

parser = argparse.ArgumentParser();
parser.add_argument('sets', type = int,
		    help = 'the number of sequence into softmax')
parser.add_argument('pins', type = int,
                    help = 'The number of pins in softmax')

args = parser.parse_args()
n = args.pins
sets = args.sets
#Input array of type float16 populated with random values
print("--------input value in decimal is:------------")
input = np.random.rand(n*sets,1).astype('float16')
print(input)

print("----------input value in hex is:--------------")
for x in range(input.shape[0]):
  H = hex(input[x][0].view('H'))[2:].zfill(4)
  if(x%n == 0):
     print("")
  print(H, end= "")

print("")
print("----------MAX value is:-----------------------")
MAX = np.max(input)
print(MAX)
print(hex(MAX.view('H'))[2:].zfill(4))

#Calculate e^x
print("-----normalized value after subtraction is:---")
input = np.subtract(input, MAX)
for x in range(input.shape[0]):
  H = hex(input[x][0].view('H'))[2:].zfill(4)
  print(H)
#print(input)
#exp_array = np.exp(input)
#print(exp_array)
print("---------exponential value results:-----------")
exp = np.exp(input)
for x in range(exp.shape[0]):
  H = hex(exp[x][0].view('H'))[2:].zfill(4)
  print(H)

print("------------summing results are:--------------")
sum = np.sum(exp)
print(hex(sum.view('H'))[2:].zfill(4))

print("------------log results are:------------------")
log = np.log(sum)
print(hex(log.view('H'))[2:].zfill(4))

print("------second stage results are::--------------")
sub2 = np.subtract(input, log)
for x in range(sub2.shape[0]):
  H = hex(sub2[x][0].view('H'))[2:].zfill(4)
  print(H)

print("------final results are::--------------")
exp2 = np.exp(sub2)
for x in range(exp2.shape[0]):
  H = hex(exp2[x][0].view('H'))[2:].zfill(4)
  print(H)

