import numpy as np

#Input array of type float16 populated with random values
input = np.random.rand(8,1).astype('float16')
print(input)
print(input[1][0])

#HEX = hex(input[0][0].view('H'))[2:].zfill(4)
#print(HEX)
for x in range input[0]:
  H = hex(np.float(input[1][x]).view('H')[2:].zfill(4))
  print(H)

#Calculate e^x
exp_array = np.exp(input)
print(exp_array)

#Calculate sum(e^x)
sum = np.sum(exp_array)
print(sum)

#Find probabilities: e^x/sum(e^x)
probabilities = exp_array / sum
print(probabilities)
