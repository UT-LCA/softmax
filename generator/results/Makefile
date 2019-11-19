export VCS_HOME=/usr/local/packages/synopsys_2018/vcs-mx/O-2018.09-SP1

#Run commands like the following:
#make PARALLELISM=8 NUM_INP_VALS=128 NUM_BLANK_LOCATIONS = 2 all

PARALLELISM ?= 4
STORAGE ?= "mem"
PRECISION ?= "float16"
ACCURACY ?= "lut"
NUM_INP_VALS ?= 8
NUM_BLANK_LOCATIONS ?= 2

all: gen compile run 

#python3 is important here. Don't use python version 2.x
gen:
	python3 ../design_generator.py -p ${PARALLELISM} -s ${STORAGE} -r ${PRECISION} -a ${ACCURACY}  | tee softmax.v
	python3 ../golden_val_generator.py -p ${PARALLELISM} -v ${NUM_INP_VALS} -b ${NUM_BLANK_LOCATIONS} | tee mem.txt
	python3 ../tb_generator.py -p ${PARALLELISM} -v ${NUM_INP_VALS} -b ${NUM_BLANK_LOCATIONS} -r ${PRECISION} | tee softmax_tb.v

compile:
	${VCS_HOME}/bin/vcs \
	-sverilog \
	-full64 \
	-debug_access+all \
	+incdir+../../sim_ver/lib/16bits/ \
	+incdir+../../sim_ver2/expunit/ \
	+incdir+../../sim_ver2/logunit/logunit8 \
	softmax.v \
  softmax_tb.v \
	+incdir+/misc/linuxws/packages/synopsys_2018/syn/O-2018.06-SP5/dw/sim_ver/ \
	-timescale=1ns/1ps \

run:
	./simv +parallelism=${PARALLELISM}

waves:
	${VCS_HOME}/bin/dve -full64 -vpd vcdplus.vpd&

clean:
	\rm -rf csrc simv.daidir/ simv *.vpd ucli.key DVEfiles/ *.v

