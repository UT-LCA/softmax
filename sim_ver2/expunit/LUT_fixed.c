//use this to generate LUT for fixed point exp unit
#include <stdio.h>
#include <math.h>
#include <stdint.h>

void int2bin(unsigned n) 
{ 
  	
	if (n > 1) 
	        int2bin(n/2); 
  
    printf("%d", n % 2); 
} 

void preint2bin(unsigned n)
{
	if (n < 2) 
	{
		printf("%d%d%d%d%d%d", 0,0,0,0,0,0);
	}
	else if (n>=2 && n < 4)
	{
		printf("%d%d%d%d%d", 0,0,0,0,0);
	}
	else if (n>=4 && n < 8)
	{
		printf("%d%d%d%d", 0,0,0,0);
	}
	else if (n>=8 && n < 16)
	{
		printf("%d%d%d", 0,0,0);
	}
	else if (n>=16 && n < 32)
	{
		printf("%d%d", 0,0);
	}
	else if (n>=32 && n < 64)
	{
		printf("%d", 0);
	}
	
}

void printBinary(int n, int i) 
{ 

	// Prints the binary representation 
	// of a number n up to i-bits. 
	int k; 
	for (k = i - 1; k >= 0; k--) { 

		if ((n >> k) & 1) 
			printf("1"); 
		else
			printf("0"); 
	} 
} 
	
int main(void)
{	
	double lutval1;
	double lutval2;
	double a = 0;
	double temp; 
	double temp2;
	int32_t x;
	int32_t y;
printf("module LUT(addr, exp);\n");
printf("    input [6:0] addr;\n");
printf("    output reg [63:0] exp;\n");
printf("\n");
printf("    always @(addr) begin\n");
printf("        case (addr)\n");
for(int i = 0; i<128;i=i+1)
{
	temp = exp(a);
	
	temp2 = exp(a-0.0625);
	lutval1 = (temp - temp2)/0.0625;
	lutval2 = temp - (lutval1*a);
	//printf("%lf\n%lf\n",lutval1,lutval2);
	lutval1 = lutval1*65536;
	lutval2 = lutval2*65536;
	x = lutval1;
	y = lutval2;

	printf("	     7'b");
	preint2bin(i);	
	int2bin(i); 	
	//printf("            : exp <= %g\n",lutval2);
	printf("            : exp =  64'b");
	printBinary(x,32);
	//printf("	");
	printBinary(y,32);
	printf(";\n");
	a-=0.0625;
}

printf("        endcase\n");
printf("    end\n");
printf("endmodule\n");

	return 0;
}


