export VCS_HOME=/usr/local/packages/synopsys_2018/vcs-mx/O-2018.09-SP1

comp_run: compile run

all: compile run waves

compile:
	${VCS_HOME}/bin/vcs \
	-sverilog \
	-full64 \
	-debug_access+all \
	../lib/16bits/*.v \
	defines.v \
	mode1_max.v \
	mode2_sub.v \
	mode3_exp.v \
	mode4_adderTree.v \
	mode5_ln.v \
	mode6_sub.v \
	mode7_exp.v \
	softmax.v \
	softmax_tb.v \
	+incdir+/misc/linuxws/packages/synopsys_2018/syn/O-2018.06-SP5/dw/sim_ver/ \
	-timescale=1ns/1ps \

run:
	./simv

waves:
	${VCS_HOME}/bin/dve -full64 -vpd vcdplus.vpd&

clean:
	\rm -rf csrc simv.daidir/ simv *.vpd ucli.key DVEfiles/

