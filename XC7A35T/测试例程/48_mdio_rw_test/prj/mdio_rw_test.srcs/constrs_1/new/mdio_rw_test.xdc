#------------------------------系统时钟和复位-----------------------------------
create_clock -period 20.000 -name sys_clk [get_ports sys_clk]
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports sys_clk]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sys_clk]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]

#----------------------以太网--------------------------- 
# B14_P_L5
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports eth_rst_n]
# B14_N_L5
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports eth_mdc]
# B14_N_L8
set_property -dict {PACKAGE_PIN AA21 IOSTANDARD LVCMOS33} [get_ports eth_mdio]


#----------------------------------按键-------------------------------------
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports touch_key]

#-----------------------------------LED-----------------------------------------
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33} [get_ports {led[1]}]