<img align="right" src="psi_logo.png">

***

### Memory components

Component 				                      | Source                                                      | Description
----------------------------------------|-------------------------------------------------------------|:-------------------------------------------:
Simple dual port RAM 										| [psi_common_sdp_ram.vhd](../hdl/psi_common_sdp_ram.vhd)	 		 	| [link](ch3_memories/ch3_1_sdp_ram.md)  
Simple dual port RAM with byte enable  	| [psi_common_sp_ram_be.vhd](../hdl/psi_common_sp_ram_be.vhd)    | [link](ch3_memories/ch3_2_sp_ram_be.md)  
True Dual port RAM  										| [psi_common_tdp_ram.vhd](../hdl/psi_common_tdp_ram.vhd)	  		| [link](ch3_memories/ch3_3_tdp_ram.md)    
True dual port RAM with byte enable  		| [psi_common_tdp_ram_be.vhd](../hdl/psi_common_tdp_ram_be.vhd)	| [link](ch3_memories/ch3_4_tdp_ram_be.md)    

***

### FIFO components
Component     				  | Source                                                      | Description
------------------------|-------------------------------------------------------------|:-------------------------------------------:
Asynchronous FIFO 			| [psi_common_async_fifo.vhd](../hdl/psi_common_async_fifo.vhd)	| [link](ch4_fifos/ch4_1_async_fifo.md)  
Synchronous FIFO  			| [psi_common_sync_fifo.vhd](../hdl/psi_common_sync_fifo.vhd)    | [link](ch4_fifos/ch4_2_sync_fifo.md)    

***

### Clock domain crossing (CDC) components
Component     					| Source                                                      | Description
------------------------|-------------------------------------------------------------|:-------------------------------------------:
Pulse clock crossing  (asynchronous pulse/vld transfer)	| [psi_common_pulse_cc.vhd](../hdl/psi_common_pulse_cc.vhd)   	  | [link](ch5_cc/ch5_1_pulse_cc.md)   
Simple clock crossing (asynchronous data value transfer) | [psi_common_pulse_cc.vhd](../hdl/psi_common_simple_cc.vhd)   	  | [link](ch5_cc/ch5_2_simple_cc.md)    
Status clock crossing (asynchronous slow changing value transfer) | [psi_common_status_cc.vhd](../hdl/psi_common_status_cc.vhd) | [link](ch5_cc/ch5_3_status_cc.md)  
Synchronous CDC with AXI-S handshaking from **Lower** clock to **Higher** multiple integer clock frequency  | [psi_common_sync_cc_n2xn.vhd](../hdl/psi_common_sync_cc_n2xn.vhd)  |  [link](ch5_cc/ch5_4_sync_cc_n2xn.md)  
Synchronous CDC with AXI-S handshaking from **Higher** clock to **lower** multiple integer clock frequency  | [psi_common_sync_cc_xn2n.vhd](../hdl/psi_common_sync_cc_xn2n.vhd)   |  [link](ch5_cc/ch5_5_sync_cc_xn2n.md)  
Bit CDC  | [psi_common_bit_cc.vhd](../../hdl/psi_common_bit_cc.vhd)   | [link](ch5_cc/ch5_6_bit_cc.md)  

##### Other components that can be used as cdc
- [psi_common_tdp_ram](ch3_memories/ch3_3_tdp_ram.md)
- [psi_common_async_fifo](ch4_fifos/ch4_1_async_fifo.md)

***

### Conversions components
Component     				  | Source                                                      | Description
------------------------|-------------------------------------------------------------|:-------------------------------------------:
Data width conversion from a N-bits to a multiple N-bits 		| [psi_common_wconv_n2xn.vhd](../hdl/psi_common_wconv_n2xn.vhd)	| [link](ch7_conversions/ch7_2_wconv_n2xn.md)  
Data width conversion from a multiple N-bits to a N-bits  	| [psi_common_wconv_x2nn.vhd](../hdl/psi_common_wconv_xn2n.vhd)    | [link](ch7_conversions/ch7_2_wconv_xn2n.md)

***

### Time Division Multiplexing (TDM) data Handling components
Component 					    | Source                                                      | Description
------------------------|-------------------------------------------------------------|:-------------------------------------------:
TDM data to parallel  	| [psi_common_tdm_par.vhd](../hdl/psi_common_tdm_par.vhd)   			|  [link](ch8_tdm_handling/ch8_2_tdm_par.md)
Parallel to TDM data  	| [psi_common_par_tdm.vhd](../hdl/psi_common_par_tdm.vhd)  				|  [link](ch8_tdm_handling/ch8_1_par.md)
TDM data to Parallel with configurable valid output channel number  |   [psi_common_tdm_par_cfg.vhd](../hdl/psi_common_tdm_par_cfg.vhd)  				|  [link](ch8_tdm_handling/ch8_3_tdm_par_cfg.md)  
TDM data multiplexer    | [psi_common_tdm_mux.vhd](../hdl/psi_common_tdm_mux.vhd)  | [link](ch8_tdm_handling/ch8_4_tdm_mux.md)  
Parallel to TDM with configurable valid output output channel |  [psi_common_par_tdm_cfg.vhd](../hdl/psi_common_par_tdm_cfg.vhd)  				|  [link](ch8_tdm_handling/ch8_5_par_tdm_cfg.md)
***

### Arbiters components
Component					  | 									Source                                    | Description
--------------------|-------------------------------------------------------------|:----------------------------------------:
Priority  					| [psi_common_arb_priority.vhd](../hdl/psi_common_arb_priority.vhd)   | [link](ch9_arbiters/ch9_1_arb_priority.md)  
Round robin  			  | [psi_common_arb_round_robin.vhd](../hdl/psi_common_arb_round_robin.vhd)   | [link](ch9_arbiters/ch9_2_arb_round_robin.md)  

***

### Interfaces components
Package   								| 									Source                                    						  	| Description
--------------------------|-----------------------------------------------------------------------------|:----------------------------------------:
SPI master  							| [psi_common_spi_master.vhd](../hdl/psi_common_spi_master.vhd)   					  | [link](ch10_interfaces/ch10_1_spi_master.md)  
I2C master  							| [psi_common_i2c_master.vhd](../hdl/psi_common_i2c_master.vhd)   						| [link](ch10_interfaces/ch10_2_i2c_master.md)  
AXI master Simple   			| [psi_common_axi_master_simple.vhd](../hdl/psi_common_axi_master_simple.vhd) | [link](ch10_interfaces/ch10_3_axi_master_simple.md)  
AXI master Full  	  			| [psi_common_axi_master_full.vhd](../hdl/psi_common_axi_master_full.vhd) 		| [link](ch10_interfaces/ch10_4_axi_master_full.md)  
AXI master IP (32 bits)	  | [psi_common_axi_slave_ipif.vhd](../hdl/psi_common_axi_slave_ipif.vhd)   		| [link](ch10_interfaces/ch10_5_axi_slave_ipif.md)  
AXI master IP (64 bits)	  | [psi_common_axi_slave_ipif64.vhd](../hdl/psi_common_axi_slave_ipif64.vhd)   	 | N.A
AXI multi pipeline stage  | [psi_common_axi_multi_pl_stage.vhd](../hdl/psi_common_axi_multi_pl_stage.vhd)  | N.A  
AXI Lite IP								| [psi_common_axilite_slave_ipif.vhd](../hdl/psi_common_axilite_slave_ipif.vhd)|[link](ch10_interfaces/ch10_6_axilite_slave_ipif.md)
***

### miscellaneous components
Component         		      | Source                                                      | Description
----------------------------|-------------------------------------------------------------|:-------------------------------------------:
Delay settable via generics	| [psi_common_delay.vhd](../hdl/psi_common_delay.vhd)					| [link](ch11_misc/ch11_1_delay.md)  
Pipeline stage  			    	| [psi_common_pl_stage.vhd](../hdl/psi_common_pl_stage.vhd)   | [link](ch11_misc/ch11_2_pl_stage.md)    
Multi pipeline stage      	| [psi_common_multi_pl_stage.vhd](../hdl/psi_common_multi_pl_stage.vhd)   | [link](ch11_misc/ch11_3_multi_pl_stage.md)   
Sizable Ping pong buffer // & tdm (interface to stream continuously data into DPRAM)  	        | [psi_common_ping_pong.vhd](../hdl/psi_common_ping_pong.vhd) | [link](ch11_misc/ch11_4_ping_pong.md)   
Delay settable via register | [psi_common_delay_cfg.vhd](../hdl/psi_common_delay_cfg.vhd) | [link](ch11_misc/ch11_5_delay_cfg.md)   
Generic Watchdog 						| [psi_common_watchdog.vhd](../hdl/psi_common_watchdog.vhd)   | [link](ch11_misc/ch11_6_watchdog.md)  
Don't optimize (Xilinx) allows evaluating synthesis  | [psi_common_dont_opt.vhd](../hdl/psi_common_dont_opt.vhd)   | [link](ch11_misc/ch11_7_dont_opt.md)  
Generic Debouncer  					| [psi_common_debouncer.vhd](../hdl/psi_common_debouncer.vhd)  | [link](ch11_misc/ch11_8_debouncer.md)  
Analog Trigger Generator  	| [psi_common_trigger_analog.vhd](../hdl/psi_trigger_analog.vhd)  | [link](ch11_misc/ch11_9_trigger_analog.md)  
Digital Trigger Generator  	| [psi_common_trigger_digital.vhd](../hdl/psi_trigger_digital.vhd)  | [link](ch11_misc/ch11_10_trigger_digital.md)
Dynamic Shifter             | [psi_common_dyn_sft.vhd](../hdl/psi_common_dyn_sft.vhd)     | [link](ch11_misc/ch11_11_dyn_sft.md)
Pulse/Ramp generator        | [psi_common_ramp_gene.vhd](../hdl/psi_common_ramp_gene.vhd)     | [link](ch11_misc/ch11_12_ramp_gene.md)   
Pulse generator ctrl static | [psi_common_pulse_generator_ctrl_static.vhd](../hdl/psi_common_pulse_generator_ctrl_static.vhd)     | [link](ch11_misc/ch11_13_pulse_generator_ctrl_static.md)  
Parallel to serial  				| [psi_common_par_ser.vhd](../hdl/psi_common_par_ser.vhd)   | [link](ch11_misc/ch11_14_par_ser.md)  
Serial to parallel  				| [psi_common_ser_par.vhd](../hdl/psi_common_ser_par.vhd)   | [link](ch11_misc/ch11_15_ser_par.md)     
***

### Packages

Package    					| 									Source                                    | Description
--------------------|-------------------------------------------------------------|:----------------------------------------:
Math  							| [psi_common_math_pkg.vhd](../hdl/psi_common_math_pkg.vhd)	 	| [link](ch2_packages/ch2_packages.md)  
array 							| [psi_common_array_pkg.vhd](../hdl/psi_common_array_pkg.vhd) | [link](ch2_packages/ch2_packages.md)  
logic								| [psi_common_logic_pkg.vhd](../hdl/psi_common_logic_pkg.vhd)	| [link](ch2_packages/ch2_packages.md)     
AXI 							  | [psi_common_axi_pkg.vhd](../hdl/psi_common_axi_pkg.vhd)			| [link](ch2_packages/ch2_packages.md)
