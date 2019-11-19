import numpy as np

#Input array of type float16 populated with random values
input = np.random.rand(8,1).astype('float16')
print(input)
#Input array in hex in float16 type
for i in range (8):
	x = hex(np.float16(input[i]).view('H'))[2:].zfill(4)
	print(x)

#Calculate e^x
exp_array = np.exp(input)
print(exp_array)

#Calculate sum(e^x)
sum = np.sum(exp_array)
print(sum)

#Find probabilities: e^x/sum(e^x)
probabilities = exp_array / sum
print(probabilities)
