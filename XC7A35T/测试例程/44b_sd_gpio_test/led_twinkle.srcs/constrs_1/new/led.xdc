#时序约束
create_clock -period 20.000 -name sys_clk -waveform {0.000 10.000} [get_ports sys_clk]

#IO管脚约束
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports sys_clk]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]

#sd B34_P_L15 B34_N_L15 B34_N_L12 B34_P_L11 B34_P_L9 B34_N_L4 B34_P_L4
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports sd_card[0]]
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports sd_card[1]]
set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS33} [get_ports sd_card[2]]
set_property -dict {PACKAGE_PIN Y4 IOSTANDARD LVCMOS33} [get_ports sd_card[3]]
set_property -dict {PACKAGE_PIN Y3 IOSTANDARD LVCMOS33} [get_ports sd_card[4]]
set_property -dict {PACKAGE_PIN Y2 IOSTANDARD LVCMOS33} [get_ports sd_card[5]]
set_property -dict {PACKAGE_PIN W2 IOSTANDARD LVCMOS33} [get_ports sd_card[6]]

#固化
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE Yes [current_design]
