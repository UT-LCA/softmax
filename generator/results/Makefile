export VCS_HOME=/usr/local/packages/synopsys_2018/vcs-mx/O-2018.09-SP1

#Run commands like the following:
#make PARALLELISM=8 NUM_INP_VALS=128 NUM_BLANK_LOCATIONS = 2 all

#Possible values
#PARALLELISM = 2,4,8,16,...
#STORAGE = mem, reg
#PRECISION = float16, fixed32
#NUM_INP_VALS = 2,4,8,16,32

PARALLELISM ?= 4
STORAGE ?= mem
PRECISION ?= float16
ACCURACY ?= lut
NUM_INP_VALS ?= 8
NUM_BLANK_LOCATIONS ?= 2
SUFFIX ?= p${PARALLELISM}_s${STORAGE}_r${PRECISION}_a${ACCURACY}_v${NUM_INP_VALS}_b${NUM_BLANK_LOCATIONS}

all: gen compile run compare

#python3 is important here. Don't use python version 2.x
gen:
	python3 ../design_generator.py -p ${PARALLELISM} -s ${STORAGE} -r ${PRECISION} -a ${ACCURACY} -v ${NUM_INP_VALS} -b ${NUM_BLANK_LOCATIONS}  | tee softmax_${SUFFIX}.v
	python3 ../golden_val_generator.py -p ${PARALLELISM} -v ${NUM_INP_VALS} -b ${NUM_BLANK_LOCATIONS} | tee mem_${SUFFIX}.txt
	python3 ../tb_generator.py -p ${PARALLELISM} -s ${STORAGE} -r ${PRECISION} -v ${NUM_INP_VALS} -b ${NUM_BLANK_LOCATIONS} -u ${SUFFIX} | tee softmax_tb_${SUFFIX}.v

compile:
	${VCS_HOME}/bin/vcs \
	-sverilog \
	-full64 \
	-debug_access+all \
	+incdir+../../sim_ver3/ \
	softmax_${SUFFIX}.v \
  softmax_tb_${SUFFIX}.v \
	+incdir+/misc/linuxws/packages/synopsys_2018/syn/O-2018.06-SP5/dw/sim_ver/ \
	-timescale=1ns/1ps \

run:
	./simv +parallelism=${PARALLELISM} |& tee sim_${SUFFIX}.log

compare:
	python3 ../compare_results.py --expected mem_${SUFFIX}.txt --observed sim_${SUFFIX}.log -p ${PARALLELISM} -v ${NUM_INP_VALS} -r ${PRECISION} | tee comparison_${SUFFIX}.csv

waves:
	${VCS_HOME}/bin/dve -full64 -vpd vcdplus.vpd&

clean:
	\rm -rf csrc simv.daidir/ simv *.vpd ucli.key DVEfiles/ *.v *.txt *.log

