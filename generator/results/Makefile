export VCS_HOME=/usr/local/packages/synopsys_2018/vcs-mx/O-2018.09-SP1

default: gen compile

gen:
	python ../generator.py | tee softmax.v
compile:
	${VCS_HOME}/bin/vcs \
	-sverilog \
	-full64 \
	-debug_access+all \
	../../sim_ver/lib/16bits/*.v \
	softmax.v \
	+incdir+/misc/linuxws/packages/synopsys_2018/syn/O-2018.06-SP5/dw/sim_ver/ \
	-timescale=1ns/1ps \

run_4:
	./simv +4_input_vals

run_8:
	./simv +8_input_vals
  
run_16:
	./simv +16_input_vals

waves:
	${VCS_HOME}/bin/dve -full64 -vpd vcdplus.vpd&

clean:
	\rm -rf csrc simv.daidir/ simv *.vpd ucli.key DVEfiles/

