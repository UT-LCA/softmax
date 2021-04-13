# The following are the changes made in softmax units to make it synthesis friendly and achieve a timing closure of less than 10 ns

# Common changes

Designware units - DW_fp_cmp.v, DW_fp_addsub.v, DW_fp_add.v, DW_fp_sub.v, DW_fp_mult.v, DW01_ash.v - were replaced with our own custom implementations in both top-level module softmax and lower-level modules of exponentialunit.v and logunit.v.

The huge always block containing the control logic in the top-level module was split into multiple always blocks based on their individual modes

# Float16 design
Added 3 pipeline stages in mode1

Added 1 pipeline stage in mode3

Added 3 pipeline stages in mode4

Added 1 pipeline stage in mode7

# Fixed16 design
Added 2 pipeline stages in mode1

Added 1 pipeline stage in mode3

Added 2 pipeline stages in mode4

Added 2 pipeline stages in mode5

Added 1 pipeline stage in mode7
