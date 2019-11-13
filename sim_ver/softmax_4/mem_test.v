module test;
reg[15:0] memory[0:7];
reg[4:0] n;
initial
	begin
	  $readmemh("mem1.txt",memory); 
	  for(n=0;n<=7;n=n+1)
	    $display("%h",memory[n]);
	end
endmodule
