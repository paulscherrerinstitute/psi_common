<img align="right" src="psi_logo.png">

***
## Introduction

[read me first](old/ch1_introduction/ch1_introduction.md)

**Quick syntax rules to push into the library:**

 - **snake_case**
 - remove **tab to white space**
 - use of suffix for entity's signal following simple rules: **_i, _o and _io** respectively for input, output and inout
 - entity, architecture, package, procedure, function, etc... ends as such: **end entity; end architecture,** etc...
 - use of prefix to gather signal corresponding to same interface like: **adc**_clk_i, **adc**_data_i, **adc**_vld_i...
 - name of architecture: **behav, struc, rtl**
 - when strcutural architecture would be nice to link components with signal's prefixe name such as: fifo2filter_*  (e.g. component A to component B: compa2compb_)

## 	Packages

###	psi_common_array_pkg

This package defines various array types that are not defined by VHDL natively. Some of these definitions are no more required in VHDL 2008 but since VHDL 2008 is not yet fully synthesizable, the package is kept.

### psi_common_logic_pkg

This package contains various logic functions (e.g. combinatorial conversions) that can be synthesized.

###	psi_common_axi_pkg

This package contains record definitions to allow representing a complete AXI interface including all ports by only two records (one in each direction). This helps improving the readability of entities with AXI interfaces.

### psi_common_math_pkg

This package contains various mathematical functions (e.g. log2). The functions are meant for calculating compile-time constants (i.e. constants, port-widths, etc.). They can potentially be synthesized as combinatorial functions but this is neither guaranteed nor will it lead to optimal results.

## List of components available


### Memory components

Component 				                      | Source                                                      | Description
----------------------------------------|-------------------------------------------------------------|:-------------------------------------------:
Simple dual port RAM 										| [psi_common_sdp_ram.vhd](../hdl/psi_common_sdp_ram.vhd)	 		 	| [link](files/psi_common_sdp_ram.md)
Simple dual port RAM with byte enable  	| [psi_common_sp_ram_be.vhd](../hdl/psi_common_sp_ram_be.vhd)    | [link](files/psi_common_sp_ram_be.md)
True Dual port RAM  										| [psi_common_tdp_ram.vhd](../hdl/psi_common_tdp_ram.vhd)	  		| [link](files/psi_common_tdp_ram.md)
True dual port RAM with byte enable  		| [psi_common_tdp_ram_be.vhd](../hdl/psi_common_tdp_ram_be.vhd)	| [link](files/psi_common_tdp_ram.md)

***

### FIFO components
Component     				  | Source                                                      | Description
------------------------|-------------------------------------------------------------|:-------------------------------------------:
Asynchronous FIFO 			| [psi_common_async_fifo.vhd](../hdl/psi_common_async_fifo.vhd)	| [link](files/psi_common_async_fifo.md)
Synchronous FIFO  			| [psi_common_sync_fifo.vhd](../hdl/psi_common_sync_fifo.vhd)    | [link](files/psi_common_sync_fifo.md)

***

### Clock domain crossing (CDC) components
Component     					| Source                                                      | Description
------------------------|-------------------------------------------------------------|:-------------------------------------------:
Pulse clock crossing  (asynchronous pulse/vld transfer)	| [psi_common_pulse_cc.vhd](../hdl/psi_common_pulse_cc.vhd)   	  | [link](files/psi_common_pulse_cc.md)
Simple clock crossing (asynchronous data value transfer) | [psi_common_pulse_cc.vhd](../hdl/psi_common_simple_cc.vhd)   	  | [link](files/psi_common_simple_cc.md)
Status clock crossing (asynchronous slow changing value transfer) | [psi_common_status_cc.vhd](../hdl/psi_common_status_cc.vhd) | [link](files/psi_common_status_cc.md)
Synchronous CDC with AXI-S handshaking from **Lower** clock to **Higher** multiple integer clock frequency  | [psi_common_sync_cc_n2xn.vhd](../hdl/psi_common_sync_cc_n2xn.vhd)  |  [link](files/psi_common_sync_cc_n2xn.md)
Synchronous CDC with AXI-S handshaking from **Higher** clock to **lower** multiple integer clock frequency  | [psi_common_sync_cc_xn2n.vhd](../hdl/psi_common_sync_cc_xn2n.vhd)   |  [link](files/psi_common_sync_cc_xn2n.md)
Bit CDC  | [psi_common_bit_cc.vhd](../../hdl/psi_common_bit_cc.vhd)   | [link](files/psi_common_bit_cc.md)

##### Other components that can be used as cdc
- [psi_common_tdp_ram](files/psi_common_tdp_ram.md)
- [psi_common_async_fifo](files/psi_common_async_fifo.md)

***

### Conversions components
Component     				  | Source                                                      | Description
------------------------|-------------------------------------------------------------|:-------------------------------------------:
Data width conversion from a N-bits to a multiple N-bits 		| [psi_common_wconv_n2xn.vhd](../hdl/psi_common_wconv_n2xn.vhd)	| [link](files/psi_common_wconv_n2xn.md)
Data width conversion from a multiple N-bits to a N-bits  	| [psi_common_wconv_x2nn.vhd](../hdl/psi_common_wconv_xn2n.vhd)    | [link](files/psi_common_wconv_xn2n.md)

***

### Time Division Multiplexing (TDM) data Handling components
Component 					    | Source                                                      | Description
------------------------|-------------------------------------------------------------|:-------------------------------------------:
TDM data to parallel  	| [psi_common_tdm_par.vhd](../hdl/psi_common_tdm_par.vhd)   	|  [link](ch8_tdm_handling/psi_common_tdm_par.md)
Parallel to TDM data  	| [psi_common_par_tdm.vhd](../hdl/psi_common_par_tdm.vhd)  		|  [link](ch8_tdm_handling/psi_common_par_tdm.md)
TDM data to Parallel with configurable valid output channel number  |   [psi_common_tdm_par_cfg.vhd](../hdl/psi_common_tdm_par_cfg.vhd)  				|  [link](files/psi_common_tdm_par_cfg.md)
TDM data multiplexer    | [psi_common_tdm_mux.vhd](../hdl/psi_common_tdm_mux.vhd)  | [link](ch8_tdm_handling/psi_common_tdm_mux.md)
Parallel to TDM with configurable valid output output channel |  [psi_common_par_tdm_cfg.vhd](../hdl/psi_common_par_tdm_cfg.vhd)  				|  [link](files/ch8_5_par_tdpsi_common_par_tdm_cfgm_cfg.md)
TDM data to parallel with last support and completion  	| [psi_common_tdm_par_fill.vhd](../hdl/psi_common_tdm_par_fill.vhd)   			|  [link](files/psi_common_tdm_par_fill.md)
***

### Arbiters components
Component					  | 									Source                                    | Description
--------------------|-------------------------------------------------------------|:----------------------------------------:
Priority  					| [psi_common_arb_priority.vhd](../hdl/psi_common_arb_priority.vhd)   | [link](files/psi_common_arb_priority.md)
Round robin  			  | [psi_common_arb_round_robin.vhd](../hdl/psi_common_arb_round_robin.vhd)   | [link](files/psi_common_arb_round_robin.md)

***

### Interfaces components
Package   								| 									Source                                    						  	| Description
--------------------------|-----------------------------------------------------------------------------|:----------------------------------------:
SPI master  							| [psi_common_spi_master.vhd](../hdl/psi_common_spi_master.vhd)   					  | [link](files/psi_common_spi_master.md)
SPI master configurable width  | [psi_common_spi_master_cfg.vhd](../hdl/psi_common_spi_master_cfg.vhd)  		  |  [link](files/psi_common_spi_master_cfg.md)
I2C master  							| [psi_common_i2c_master.vhd](../hdl/psi_common_i2c_master.vhd)   						| [link](files/psi_common_i2c_master.md)
AXI master Simple   			| [psi_common_axi_master_simple.vhd](../hdl/psi_common_axi_master_simple.vhd) | [link](files/psi_common_axi_master_simple.md)
AXI master Full  	  			| [psi_common_axi_master_full.vhd](../hdl/psi_common_axi_master_full.vhd) 		| [link](files/psi_common_axi_master_full.md)
AXI slave IP (32 bits)	  | [psi_common_axi_slave_ipif.vhd](../hdl/psi_common_axi_slave_ipif.vhd)   		| [link](files/psi_common_axi_slave_ipif.md)
AXI slave IP (64 bits)	  | [psi_common_axi_slave_ipif64.vhd](../hdl/psi_common_axi_slave_ipif64.vhd)   	 | N.A
AXI multi pipeline stage  | [psi_common_axi_multi_pl_stage.vhd](../hdl/psi_common_axi_multi_pl_stage.vhd)  | N.A
AXI slave Lite IP					| [psi_common_axilite_slave_ipif.vhd](../hdl/psi_common_axilite_slave_ipif.vhd)|[link](files/psi_common_axilite_slave_ipif.md)
***

### miscellaneous components
Component         		      | Source                                                      | Description
----------------------------|-------------------------------------------------------------|:-------------------------------------------:
Delay settable via generics	| [psi_common_delay.vhd](../hdl/psi_common_delay.vhd)					| [link](files/psi_common_delay.md)
Pipeline stage  			    	| [psi_common_pl_stage.vhd](../hdl/psi_common_pl_stage.vhd)   | [link](files/psi_common_pl_stage.md)
Multi pipeline stage      	| [psi_common_multi_pl_stage.vhd](../hdl/psi_common_multi_pl_stage.vhd)   | [link](files/psi_common_multi_pl_stage.md)
Sizable Ping pong buffer // & tdm (interface to stream continuously data into DPRAM)  	        | [psi_common_ping_pong.vhd](../hdl/psi_common_ping_pong.vhd) | [link](files/psi_common_ping_pong.md)
Delay settable via register | [psi_common_delay_cfg.vhd](../hdl/psi_common_delay_cfg.vhd) | [link](files/psi_common_delay_cfg.md)
Generic Watchdog 						| [psi_common_watchdog.vhd](../hdl/psi_common_watchdog.vhd)   | [link](files/psi_common_watchdog.md)
Don't optimize (Xilinx) allows evaluating synthesis  | [psi_common_dont_opt.vhd](../hdl/psi_common_dont_opt.vhd)   | [link](files/psi_common_dont_opt.md)
Generic Debouncer  					| [psi_common_debouncer.vhd](../hdl/psi_common_debouncer.vhd)  | [link](files/psi_common_debouncer.md)
Analog Trigger Generator  	| [psi_common_trigger_analog.vhd](../hdl/psi_trigger_analog.vhd)  | [link](files/psi_trigger_analog.md)
Digital Trigger Generator  	| [psi_common_trigger_digital.vhd](../hdl/psi_trigger_digital.vhd)  | [link](files/psi_trigger_digital.md)
Dynamic Shifter             | [psi_common_dyn_sft.vhd](../hdl/psi_common_dyn_sft.vhd)     | [link](files/psi_common_dyn_sft.md)
Pulse/Ramp generator        | [psi_common_ramp_gene.vhd](../hdl/psi_common_ramp_gene.vhd)     | [link](files/psi_common_ramp_gene.md)
Pulse generator ctrl static | [psi_common_pulse_generator_ctrl_static.vhd](../hdl/psi_common_pulse_generator_ctrl_static.vhd)     | [link](files/psi_common_pulse_generator_ctrl_static.md)
Parallel to serial  				| [psi_common_par_ser.vhd](../hdl/psi_common_par_ser.vhd)   | [link](files/psi_common_par_ser.md)
Serial to parallel  				| [psi_common_ser_par.vhd](../hdl/psi_common_ser_par.vhd)   | [link](files/psi_common_ser_par.md)
Find Min Max  							| [psi_common_find_min_max.vhd](../hdl/psi_common_find_min_max.vhd)   | [link](files/psi_common_find_min_max.md)
Min Max Sum  						   	| [psi_common_find_min_max.vhd](../hdl/psi_common_min_max_sum.vhd)   | [link](files/psi_common_min_max_sum.md)
PRBS  						  		  	| [psi_common_prbs.vhd](../hdl/psi_common_prbs.vhd)   | [link](files/psi_common_prbs.md)    
***

### Packages

Package    					| 									Source                                    |
--------------------|-------------------------------------------------------------|
Math  							| [psi_common_math_pkg.vhd](../hdl/psi_common_math_pkg.vhd)	 	|
array 							| [psi_common_array_pkg.vhd](../hdl/psi_common_array_pkg.vhd) |
logic								| [psi_common_logic_pkg.vhd](../hdl/psi_common_logic_pkg.vhd)	|
AXI 							  | [psi_common_axi_pkg.vhd](../hdl/psi_common_axi_pkg.vhd)			|
