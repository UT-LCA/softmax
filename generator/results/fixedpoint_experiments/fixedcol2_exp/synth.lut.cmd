analyze -format verilog {/misc/scratch/ppatel2/softmax/generator/results/fixed2_exp/softmax_p1_smem_rfixed32_alut_v512_b2_0_10.v /misc/scratch/ppatel2/softmax/generator/results/fixed2_exp/logunit_fixed.v /misc/scratch/ppatel2/softmax/generator/results/fixed2_exp/exponentialunit_fixed.v}
elaborate softmax -architecture verilog -library DEFAULT
link
create_clock -name "CLK_0" -period 4 -waveform { 0 2  }  { clk  }
set_operating_conditions -library gscl45nm typical
remove_wire_load_model
compile -exact_map
uplevel #0 { report_timing -path full -delay max -nworst 1 -max_paths 1 -significant_digits 2 -sort_by group } >> timing2.txt
uplevel #0 { report_area } >> area2.txt
uplevel #0 { report_power -analysis_effort low } >> power2.txt
uplevel #0 { report_design -nosplit } >> design2.txt
exit
