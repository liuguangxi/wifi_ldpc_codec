create_clock -period 3.333 -name clk [get_ports clk]


set_property PACKAGE_PIN T25 [get_ports clk]
set_property PACKAGE_PIN P25 [get_ports test_i]
set_property PACKAGE_PIN P26 [get_ports test_o]

set_property IOSTANDARD LVCMOS18 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports test_i]
set_property IOSTANDARD LVCMOS18 [get_ports test_o]
