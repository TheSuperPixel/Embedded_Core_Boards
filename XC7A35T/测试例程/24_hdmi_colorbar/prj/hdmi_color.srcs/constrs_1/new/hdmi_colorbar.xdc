#系统时钟和复位
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports sys_clk]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]

#HDMI
set_property -dict {PACKAGE_PIN F19 IOSTANDARD TMDS_33} [get_ports {tmds_data_p[2]}]
set_property -dict {PACKAGE_PIN E22 IOSTANDARD TMDS_33} [get_ports {tmds_data_p[1]}]
set_property -dict {PACKAGE_PIN E21 IOSTANDARD TMDS_33} [get_ports {tmds_data_p[0]}]
set_property -dict {PACKAGE_PIN C22 IOSTANDARD TMDS_33} [get_ports tmds_clk_p]

create_clock -period 20.000 -name sys_clk -waveform {0.000 10.000} [get_ports sys_clk]


set_property PACKAGE_PIN A19 [get_ports tmds_oen]
set_property IOSTANDARD LVCMOS33 [get_ports tmds_oen]
