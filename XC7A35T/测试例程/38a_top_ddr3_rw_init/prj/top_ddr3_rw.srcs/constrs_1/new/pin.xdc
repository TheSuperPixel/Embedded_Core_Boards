############## NET - IOSTANDARD ######################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
#############SPI Configurate Setting##################
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design] 
set_property CONFIG_MODE SPIx4 [current_design] 
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design] 
#############clock and reset Setting##################
create_clock -period 20 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports {sys_clk}]
set_property PACKAGE_PIN R4 [get_ports {sys_clk}]

set_property IOSTANDARD LVCMOS33 [get_ports {sys_rst_n}]
set_property PACKAGE_PIN U2 [get_ports {sys_rst_n}]
#############led Setting##############################
#核心板LED
# 官方板卡现象：LED0和LED1为高电平，按下复位后LED1闪烁
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property PACKAGE_PIN F15 [get_ports {led[0]}]


set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property PACKAGE_PIN G21 [get_ports {led[1]}]











