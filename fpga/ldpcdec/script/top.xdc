create_clock -period 2.5 -name clk [get_ports clk]


set_property PACKAGE_PIN T25 [get_ports clk]
set_property PACKAGE_PIN P25 [get_ports test_i]
set_property PACKAGE_PIN P26 [get_ports test_o]

set_property IOSTANDARD LVCMOS18 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports test_i]
set_property IOSTANDARD LVCMOS18 [get_ports test_o]


set_property rom_style distributed [get_cells u_ldpcdec_core/u_ldpcdec_dpu/u_ldpcdec_main_tbl/*_w*]
set_property rom_style distributed [get_cells u_ldpcdec_core/u_ldpcdec_dpu/u_ldpcdec_calc_pc/u_ldpcdec_pc_tbl/pc_*]
