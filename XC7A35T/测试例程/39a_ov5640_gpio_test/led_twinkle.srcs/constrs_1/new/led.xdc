#时序约束
create_clock -period 20.000 -name sys_clk -waveform {0.000 10.000} [get_ports sys_clk]

#IO管脚约束
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports sys_clk]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports sys_rst_n]

#核心板LED
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS33} [get_ports led]

#CMEARA GPIO
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[0]}]
set_property -dict {PACKAGE_PIN AA8 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[1]}]
set_property -dict {PACKAGE_PIN AB5 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[2]}]
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[3]}]
set_property -dict {PACKAGE_PIN W1  IOSTANDARD LVCMOS33} [get_ports {cam_gpio[4]}]
set_property -dict {PACKAGE_PIN U1  IOSTANDARD LVCMOS33} [get_ports {cam_gpio[5]}]
set_property -dict {PACKAGE_PIN Y1  IOSTANDARD LVCMOS33} [get_ports {cam_gpio[6]}]
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[7]}]
set_property -dict {PACKAGE_PIN AA3 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[8]}]
set_property -dict {PACKAGE_PIN AB3 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[9]}]
set_property -dict {PACKAGE_PIN AA4 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[10]}]
set_property -dict {PACKAGE_PIN AB7 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[11]}]
set_property -dict {PACKAGE_PIN AA5 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[12]}]
set_property -dict {PACKAGE_PIN AA6 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[13]}]
set_property -dict {PACKAGE_PIN AB6 IOSTANDARD LVCMOS33} [get_ports {cam_gpio[14]}]

#固化
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS true [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE Yes [current_design]
