analyze -format verilog {/home/projects/ljohn/aarora1/softmax/softmax/generator/results/accuracy_exp/softmax_p8_smem_rfloat16_adw_v512_b2_-0.1_0.1.v} 
elaborate softmax -architecture verilog -library DEFAULT
link
create_clock -name "CLK_0" -period 4 -waveform { 0 2 }  { clk  }
set_operating_conditions -library gscl45nm typical
remove_wire_load_model
compile -exact_map
uplevel #0 { report_timing -path full -delay max -nworst 1 -max_paths 1 -significant_digits 2 -sort_by group }
uplevel #0 { report_area }
uplevel #0 { report_power -analysis_effort low }
uplevel #0 { report_design -nosplit }
