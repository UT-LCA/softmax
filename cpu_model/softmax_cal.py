import numpy as np

#Input array of type float16 populated with random values
print("--------input value in decimal is:------------")
input = np.random.rand(4,1).astype('float16')
print(input)

print("----------input value in hex is:--------------")
for x in range(input.shape[0]):
  H = hex(input[x][0].view('H'))[2:].zfill(4)
  print(H)

print("----------MAX value is:-----------------------")
MAX = np.max(input)
print(MAX)
print(hex(MAX.view('H'))[2:].zfill(4))

#Calculate e^x
print("----------exp value in decimal is:------------")
exp_array = np.exp(input)
print(exp_array)

#Calculate sum(e^x)
sum = np.sum(exp_array)
print(sum)

#Find probabilities: e^x/sum(e^x)
probabilities = exp_array / sum
print("--------output value in decimal is:-----------")
print(probabilities)
print("----------output value in hex is:-------------")
for x in range(probabilities.shape[0]):
  H = hex(probabilities[x][0].view('H'))[2:].zfill(4)
  print(H)
