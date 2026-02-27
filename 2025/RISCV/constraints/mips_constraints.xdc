# Clock signal
set_property PACKAGE_PIN W5 [get_ports i_clk_crudo]
    set_property IOSTANDARD LVCMOS33 [get_ports i_clk_crudo]
    create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports i_clk_crudo]
    ##create_generated_clock -name baud_clk -source [get_pins uut_baud_gen/i_clk] -edges {1 2 3} -edge_shift {0 217 434} [get_pins uut_baud_gen/o_flag_max_tick]

##Buton reset
set_property PACKAGE_PIN U17 [get_ports i_reset_button]						
	set_property IOSTANDARD LVCMOS33 [get_ports i_reset_button]
	
##Buton reset
set_property PACKAGE_PIN W19 [get_ports i_reset_clock]						
	set_property IOSTANDARD LVCMOS33 [get_ports i_reset_clock]

##Buton reset
set_property PACKAGE_PIN T18 [get_ports i_flag_edge]						
	set_property IOSTANDARD LVCMOS33 [get_ports i_flag_edge]
	
##USB-RS232 Interface (UART en neustro caso)
set_property PACKAGE_PIN B18 [get_ports i_rx_B18]						
	set_property IOSTANDARD LVCMOS33 [get_ports i_rx_B18]
set_property PACKAGE_PIN A18 [get_ports o_tx_A18]						
	set_property IOSTANDARD LVCMOS33 [get_ports o_tx_A18]
	
# LED para el estado rx (bit 0)
#set_property PACKAGE_PIN U16 [get_ports {o_led_state[0]}]
#    set_property IOSTANDARD LVCMOS33 [get_ports {o_led_state[0]}]

# LED para el estado rx (bit 1)
#set_property PACKAGE_PIN E19 [get_ports {o_led_state[1]}]
#    set_property IOSTANDARD LVCMOS33 [get_ports {o_led_state[1]}]

# LED para el estado rx (bit 2)
#set_property PACKAGE_PIN U16 [get_ports {o_led_state[2]}]
#    set_property IOSTANDARD LVCMOS33 [get_ports {o_led_state[2]}]
    
# LED para el done de tx
#set_property PACKAGE_PIN V13 [get_ports done]
#    set_property IOSTANDARD LVCMOS33 [get_ports done]


# LED para el data_rx 0 LD8
set_property PACKAGE_PIN V13 [get_ports o_rx_data[0]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_rx_data[0]]
# LED para el data_rx 1 LD9
set_property PACKAGE_PIN V3 [get_ports o_rx_data[1]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_rx_data[1]]
# LED para el data_rx 2 LD10
set_property PACKAGE_PIN W3 [get_ports o_rx_data[2]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_rx_data[2]]
# LED para el data_rx 3 LD11
set_property PACKAGE_PIN U3 [get_ports o_rx_data[3]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_rx_data[3]]
# LED para el data_rx 4 LD12
set_property PACKAGE_PIN P3 [get_ports o_rx_data[4]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_rx_data[4]]
# LED para el data_rx 5 LD13
set_property PACKAGE_PIN N3 [get_ports o_rx_data[5]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_rx_data[5]]
# LED para el data_rx 6 LD14
set_property PACKAGE_PIN P1 [get_ports o_rx_data[6]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_rx_data[6]]
# LED para el data_rx 7 LD15
set_property PACKAGE_PIN L1 [get_ports o_rx_data[7]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_rx_data[7]]
    
# LED para el o_instruction_8 0 LD0
set_property PACKAGE_PIN U16 [get_ports o_instruction_8[0]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_instruction_8[0]]
# LED para el o_instruction_8 1 LD1
set_property PACKAGE_PIN E19 [get_ports o_instruction_8[1]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_instruction_8[1]]
# LED para el o_instruction_8 2 LD2
set_property PACKAGE_PIN U19 [get_ports o_instruction_8[2]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_instruction_8[2]]
# LED para el o_instruction_8 3 LD3
set_property PACKAGE_PIN V19 [get_ports o_instruction_8[3]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_instruction_8[3]]
# LED para el o_instruction_8 4 LD4
set_property PACKAGE_PIN W18 [get_ports o_instruction_8[4]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_instruction_8[4]]
# LED para el o_instruction_8 5 LD5
set_property PACKAGE_PIN U15 [get_ports o_instruction_8[5]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_instruction_8[5]]
# LED para el o_instruction_8 6 LD6
set_property PACKAGE_PIN U14 [get_ports o_instruction_8[6]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_instruction_8[6]]
# LED para el o_instruction_8 7 LD7
set_property PACKAGE_PIN V14 [get_ports o_instruction_8[7]]
    set_property IOSTANDARD LVCMOS33 [get_ports o_instruction_8[7]]


# LED para EXEC_MODE (bit 2)
#set_property PACKAGE_PIN U19 [get_ports {o_led_state_scan[2]}]
#    set_property IOSTANDARD LVCMOS33 [get_ports {o_led_state_scan[2]}]

# LED para STEP (bit 3)
#set_property PACKAGE_PIN V19 [get_ports {o_led_state_scan[3]}]
#    set_property IOSTANDARD LVCMOS33 [get_ports {o_led_state_scan[3]}]


## --- DISPLAYS DE 7 SEGMENTOS ---
## Estos son los segmentos (a, b, c, d, e, f, g)
set_property PACKAGE_PIN W7 [get_ports o_seg_bus[0]]					
	set_property IOSTANDARD LVCMOS33 [get_ports o_seg_bus[0]]
set_property PACKAGE_PIN W6 [get_ports o_seg_bus[1]]					
	set_property IOSTANDARD LVCMOS33 [get_ports o_seg_bus[1]]
set_property PACKAGE_PIN U8 [get_ports o_seg_bus[2]]					
	set_property IOSTANDARD LVCMOS33 [get_ports o_seg_bus[2]]
set_property PACKAGE_PIN V8 [get_ports o_seg_bus[3]]					
	set_property IOSTANDARD LVCMOS33 [get_ports o_seg_bus[3]]
set_property PACKAGE_PIN U5 [get_ports o_seg_bus[4]]					
	set_property IOSTANDARD LVCMOS33 [get_ports o_seg_bus[4]]
set_property PACKAGE_PIN V5 [get_ports o_seg_bus[5]]					
	set_property IOSTANDARD LVCMOS33 [get_ports o_seg_bus[5]]
set_property PACKAGE_PIN U7 [get_ports o_seg_bus[6]]					
	set_property IOSTANDARD LVCMOS33 [get_ports o_seg_bus[6]]

## Ánodos (Controlan qué dígito se enciende)
set_property PACKAGE_PIN U2 [get_ports o_an[0]]					
	set_property IOSTANDARD LVCMOS33 [get_ports o_an[0]]
set_property PACKAGE_PIN U4 [get_ports o_an[1]]					
	set_property IOSTANDARD LVCMOS33 [get_ports o_an[1]]
set_property PACKAGE_PIN V4 [get_ports o_an[2]]					
	set_property IOSTANDARD LVCMOS33 [get_ports o_an[2]]
set_property PACKAGE_PIN W4 [get_ports o_an[3]]					
	set_property IOSTANDARD LVCMOS33 [get_ports o_an[3]]