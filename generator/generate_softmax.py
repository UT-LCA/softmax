import os
import re
import argparse
import math

class generate_softmax():
  def __init__(self, template_file, num_inp_pins):
    self.num_inp_pins = num_inp_pins
    self.template_file = template_file
    self.num_add_stages_in_adder_tree = int(math.log(self.num_inp_pins,2)) + 1
    self.num_flop_stages_in_adder_tree = self.num_add_stages_in_adder_tree
    self.num_comparator_stages_in_max_tree = int(math.log(self.num_inp_pins,2)) + 1
    self.num_flop_stages_in_max_tree = math.ceil(self.num_comparator_stages_in_max_tree/3)
    self.print_it()

  def print_it(self):
    def max_tree_stage_has_flops(stage):
      #we place flops after every 3 stages
      return stage%3==0

    template_file = open(self.template_file, 'r')
    for line in template_file:
      line = line.rstrip()

      #Any tag found?
      tag_found = re.search(r'<.*>', line)
      if tag_found is not None:
        #output ports
        outp_ports_tag = re.search(r'<outp_ports>', line)
        if outp_ports_tag is not None: 
          for i in range(self.num_inp_pins):
            print("  outp%d," % (i))

        #output declarations
        outp_declaration_tag = re.search(r'<outp_declaration>', line)
        if outp_declaration_tag is not None: 
          for i in range(self.num_inp_pins):
            print("  output [`DATAWIDTH-1:0] outp%d;" % (i))

        #mode1_stage_run_regs
        mode1_stage_run_regs_tag = re.search(r'<mode1_stage_run_regs>', line)
        if mode1_stage_run_regs_tag is not None:
          last_stage_num = ((self.num_comparator_stages_in_max_tree - 1)//3)*3
          for i in range(self.num_comparator_stages_in_max_tree):
            if max_tree_stage_has_flops(i):
              if(i == last_stage_num):
                print("  wire mode1_stage%d_run;" % (i))
                print("  assign mode1_stage%d_run = mode1_run;"% (i))
              else:
                print("  reg mode1_stage%d_run;" % (i))

        #mode4_stage_run_regs
        mode4_stage_run_regs_tag = re.search(r'<mode4_stage_run_regs>', line)
        if mode4_stage_run_regs_tag is not None:
          if(self.num_flop_stages_in_adder_tree > 1):
            print("  reg mode4_stage1_run_a;")
            print("  reg mode4_stage2_run_a;")
          elif(self.num_flop_stages_in_adder_tree > 0):
            print("  reg mode4_stage1_run_a;")
            print("  reg mode3_run_a;")
          for i in range(self.num_flop_stages_in_adder_tree):
            print("  reg mode4_stage%d_run;" % (i))

        #mode4_stage_run_regs_assign
        mode4_stage_run_regs_assign_tag = re.search(r'<mode4_stage_run_regs_assign>', line)
        if mode4_stage_run_regs_assign_tag is not None:
          if(self.num_flop_stages_in_adder_tree > 1):
            print("    mode4_stage1_run_a <= mode4_stage1_run;")
            print("    mode4_stage2_run_a <= mode4_stage2_run;")
          elif(self.num_flop_stages_in_adder_tree > 0):
            print("    mode4_stage1_run_a <= mode4_stage1_run;")
            print("    mode3_run_a <= mode3_run;")
            

        #mode1_run_reset
        mode1_run_reset_tag = re.search(r'mode1_run_reset', line)
        if mode1_run_reset_tag is not None:
          last_stage_num = ((self.num_comparator_stages_in_max_tree - 1)//3)*3
          for i in range(self.num_comparator_stages_in_max_tree):
            if max_tree_stage_has_flops(i):
              if(i != last_stage_num):
                print("      mode1_stage%d_run <= 0;" % (i))

        #mode4_run_reset
        mode4_run_reset_tag = re.search(r'mode4_run_reset', line)
        if mode4_run_reset_tag is not None:
          for i in range(self.num_flop_stages_in_adder_tree):
            print("      mode4_stage%d_run <= 0;" % (i))

        #mode1_finish_mode2_trigger
        mode1_finish_mode2_trigger_tag = re.search(r'<mode1_finish_mode2_trigger>', line)
        if mode1_finish_mode2_trigger_tag is not None:
          if self.num_inp_pins > 4:
            print("    if(~reset && mode1_start && addr < end_addr) begin")
            print("      addr <= addr + 1;")
            print("      inp_reg <= inp;")
            print("      mode1_run <= 1;")
            print("    end else if(addr == end_addr)begin")
            print("      mode2_start <= 1;")
            print("      sub0_inp_addr <= start_addr;")
            print("      addr <= 0;")
            print("      mode1_run <= 0;")
            print("      mode1_start <= 0;")
            print("    end else begin")
            print("      mode1_run <= 0;")
            print("    end")
          else:
            print("    if(~reset && mode1_start && addr < end_addr) begin")
            print("      addr <= addr + 1;")
            print("      inp_reg <= inp;")
            print("      mode1_run <= 1;")
            print("      if(addr == end_addr - 1) begin")
            print("        mode2_start <= 1;")
            print("        sub0_inp_addr <= start_addr;")
            print("      end")
            print("    end else if(addr == end_addr)begin")
            print("      addr <= 0;")
            print("      mode1_run <= 0;")
            print("      mode1_start <= 0;")
            print("    end else begin")
            print("      mode1_run <= 0;")
            print("    end")

        #mode1_stagex_run
        mode1_stagex_run_tag = re.search(r'<mode1_stagex_run>', line)
        if mode1_stagex_run_tag is not None and self.num_comparator_stages_in_max_tree > 3:
          last_stage_num = ((self.num_comparator_stages_in_max_tree - 1)//3)*3
          for i in reversed(range(self.num_comparator_stages_in_max_tree)):
            if max_tree_stage_has_flops(i) and i != last_stage_num:
              print("    if (mode1_stage%d_run == 1) begin" % (i + 3))
              print("      mode1_stage%d_run <= 1;"% (i))
              print("    end else begin")
              print("      mode1_stage%d_run <= 0;" % (i))
              print("    end") 

        #mode4_stagex_run
        mode4_stagex_run_tag = re.search(r'<mode4_stagex_run>', line)
        print("")
        if mode4_stagex_run_tag is not None:
          print("    if (mode3_run == 1) begin")
          print("      mode4_stage%d_run <= 1;" % (self.num_flop_stages_in_adder_tree-1))
          print("    end else begin")
          print("      mode4_stage%d_run <= 0;" % (self.num_flop_stages_in_adder_tree-1))
          print("    end")
          for i in reversed(range(self.num_flop_stages_in_adder_tree-1)):
            print("    if (mode4_stage%d_run == 1) begin" % (i+1))
            print("      mode4_stage%d_run <= 1;" % (i))
            print("    end else begin")
            print("      mode4_stage%d_run <= 0;" % (i))
            print("    end\n") 


        #presub_trigger
        presub_trigger_tag = re.search(r'<presub_trigger>', line)
        if presub_trigger_tag is not None:
          if self.num_inp_pins <= 2:
            print("    if (mode3_run_a & ~mode3_run) begin")
          else:         
            print("    if(mode4_stage2_run_a & ~mode4_stage2_run) begin")

        #mode1 max
        mode1_max_tag = re.search(r'<mode1_max>', line)
        if mode1_max_tag is not None:
          for i in range(self.num_inp_pins):
            print("      .inp%d(inp_reg[`DATAWIDTH*%d-1:`DATAWIDTH*%d])," % (i, i+1, i))
          for iter in range(self.num_comparator_stages_in_max_tree):
            if max_tree_stage_has_flops(iter):
              print("      .mode1_stage%d_run(mode1_stage%d_run)," % (iter, iter))

        #mode2 sub
        mode2_sub_tag = re.search(r'<mode2_sub>', line)
        if mode2_sub_tag is not None:
          for i in range(self.num_inp_pins):
            print("  wire [`DATAWIDTH-1:0] mode2_outp_sub%d;" % (i))
          print("  mode2_sub mode2_sub(")
          for i in range(self.num_inp_pins):
            print("      .a_inp%d(sub0_inp_reg[`DATAWIDTH*%d-1:`DATAWIDTH*%d])," % (i, i+1, i))
          for i in range(self.num_inp_pins):
            print("      .outp%d(mode2_outp_sub%d)," %(i,i))
          print("      .b_inp(max_outp));")
          print("")
          for i in range(self.num_inp_pins):
            print("  reg [`DATAWIDTH-1:0] mode2_outp_sub%d_reg;" % (i))
          print("  always @(posedge clk) begin")
          print("    if (reset) begin")
          for i in range(self.num_inp_pins):
            print("      mode2_outp_sub%d_reg <= 0;" % (i))
          print("    end else if (mode2_run) begin")
          for i in range(self.num_inp_pins):
            print("      mode2_outp_sub%d_reg <= mode2_outp_sub%d;" % (i,i))
          print("    end")
          print("  end")

        #mode3 exp
        mode3_exp_tag = re.search(r'<mode3_exp>', line)
        if mode3_exp_tag is not None:
          for i in range(self.num_inp_pins):
            print("  wire [`DATAWIDTH-1:0] mode3_outp_exp%d;" % (i))
          print("  mode3_exp mode3_exp(")
          for i in range(self.num_inp_pins):
            print("      .inp%d(mode2_outp_sub%d_reg)," % (i,i))
          for i in range(self.num_inp_pins):
            if i==self.num_inp_pins-1:
              print("      .outp%d(mode3_outp_exp%d)" %(i,i))
            else:
              print("      .outp%d(mode3_outp_exp%d)," %(i,i))
          print("  );")
          print("")
          for i in range(self.num_inp_pins):
            print("  reg [`DATAWIDTH-1:0] mode3_outp_exp%d_reg;" % (i))
          print("  always @(posedge clk) begin")
          print("    if (reset) begin")
          for i in range(self.num_inp_pins):
            print("      mode3_outp_exp%d_reg <= 0;" % (i))
          print("    end else if (mode3_run) begin")
          for i in range(self.num_inp_pins):
            print("      mode3_outp_exp%d_reg <= mode3_outp_exp%d;" % (i,i))
          print("    end")
          print("  end")

        #mode4 adder tree
        mode4_adder_tree_tag = re.search(r'<mode4_adder_tree>', line)
        if mode4_adder_tree_tag is not None:
          for i in range(self.num_inp_pins):
            print("    .inp%d(mode3_outp_exp%d_reg)," % (i,i))            
          for iter in reversed(range(self.num_add_stages_in_adder_tree)):
            print("    .mode4_stage%d_run(mode4_stage%d_run)," % (iter, iter))

        #mode6 pre-sub
        mode6_pre_sub_tag = re.search(r'<mode6_presub>', line)
        if mode6_pre_sub_tag is not None:
          for i in range(self.num_inp_pins):
            print("  wire [`DATAWIDTH-1:0] mode6_outp_presub%d;" % (i))
          for i in range(self.num_inp_pins):
            print("  reg [`DATAWIDTH-1:0] mode6_outp_presub%d_reg;" % (i))
          print("")
          print("  mode6_sub pre_sub(")
          for i in range(self.num_inp_pins):
            print("      .a_inp%d(sub1_inp_reg[`DATAWIDTH*%d-1:`DATAWIDTH*%d])," % (i, i+1, i))
          print("      .b_inp(max_outp),")
          for i in range(self.num_inp_pins):
            if i==self.num_inp_pins-1:
              print("      .outp%d(mode6_outp_presub%d)" % (i,i))
            else: 
              print("      .outp%d(mode6_outp_presub%d)," % (i,i))
          print("  );")
          print("  always @(posedge clk) begin")
          print("    if (reset) begin")
          for i in range(self.num_inp_pins):
            print("      mode6_outp_presub%d_reg <= 0;" % (i))
          print("    end else if (presub_run) begin")
          for i in range(self.num_inp_pins):
            print("      mode6_outp_presub%d_reg <= mode6_outp_presub%d;" % (i,i))
          print("    end")
          print("  end")

        #mode6 log-sub
        mode6_log_sub_tag = re.search(r'<mode6_logsub>', line)
        if mode6_log_sub_tag is not None:
          for i in range(self.num_inp_pins):
            print("  wire [`DATAWIDTH-1:0] mode6_outp_logsub%d;" % (i))
          for i in range(self.num_inp_pins):
            print("  reg [`DATAWIDTH-1:0] mode6_outp_logsub%d_reg;" % (i))
          print("")
          print("  mode6_sub log_sub(")
          for i in range(self.num_inp_pins):
            print("      .a_inp%d(mode6_outp_presub%d_reg)," % (i, i))
          print("      .b_inp(mode5_outp_log_reg),")
          for i in range(self.num_inp_pins):
            if i==self.num_inp_pins-1:
              print("      .outp%d(mode6_outp_logsub%d)" % (i,i))
            else:
              print("      .outp%d(mode6_outp_logsub%d)," % (i,i))
          print("  );")
          print("  always @(posedge clk) begin")
          print("    if (reset) begin")
          for i in range(self.num_inp_pins):
            print("      mode6_outp_logsub%d_reg <= 0;" % (i))
          print("    end else if (mode6_run) begin")
          for i in range(self.num_inp_pins):
            print("      mode6_outp_logsub%d_reg <= mode6_outp_logsub%d;" % (i,i))
          print("    end")
          print("  end")

        #mode7 exp
        mode7_exp_tag = re.search(r'<mode7_exp>', line)
        if mode7_exp_tag is not None:
          for i in range(self.num_inp_pins):
            print("  wire [`DATAWIDTH-1:0] outp%d_temp;" % (i))
          for i in range(self.num_inp_pins):
            print("  reg [`DATAWIDTH-1:0] outp%d;" % (i))
          print("")
          print("  mode7_exp mode7_exp(")
          for i in range(self.num_inp_pins):
            print("      .inp%d(mode6_outp_logsub%d_reg)," % (i, i))
          for i in range(self.num_inp_pins):
            if i==self.num_inp_pins-1:
              print("      .outp%d(outp%d_temp)" % (i,i))
            else:
              print("      .outp%d(outp%d_temp)," % (i,i))
          print("  );")
          print("  always @(posedge clk) begin")
          print("    if (reset) begin")
          for i in range(self.num_inp_pins):
            print("      outp%d <= 0;" % (i))
          print("    end else if (mode7_run) begin")
          for i in range(self.num_inp_pins):
            print("      outp%d <= outp%d_temp;" % (i,i))
          print("    end")
          print("  end")
      else:      
        print(line)
