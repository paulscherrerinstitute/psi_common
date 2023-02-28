<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_axilite_slave_ipif
 - VHDL source: [psi_common_axilite_slave_ipif](../../hdl/psi_common_axilite_slave_ipif.vhd)
 - Testbench source: [psi_common_axilite_slave_ipif_tb.vhd](../../testbench/psi_common_axilite_slave_ipif_tb/psi_common_axilite_slave_ipif_tb.vhd)

### Description

This entity is equal to [psi_common_axi_slave_ipif](psi_common_axi_slave_ipif.md) but it does only implement the AXILite protocol (e.g. no bursts, no exclusive access, no pending transfers, etc.). See [psi_common_axi_slave_ipif](psi_common_axi_slave_ipif.md) for details.

### Generics
| Name             | type     | Description                               |
|:-----------------|:---------|:------------------------------------------|
| num_reg_g        | integer  | $$ export=true $$                         |
| rst_val_g        | t_aslv32 | $$ constant=(x"0001abcd", x"00021234") $$ |
| use_mem_g        | boolean  | $$ export=true $$                         |
| axi_addr_width_g | integer  | N.A                                       |

### Interfaces
| Name          | In/Out   | Length           | Description                                    |
|:--------------|:---------|:-----------------|:-----------------------------------------------|
| s_axi_*    		| N.A      | N.A              | AXI Slave interfaces				                  
| o_reg_rd      | o        | num_reg_g        | Read-pulse for each register
| o_reg_wr      | o        | num_reg_g        | Write-pulse for each register             
| i_reg_rdata   | i        | num_reg_g        | Register read values  
| o_reg_wdata   | o        | 2                | Register write values              
| o_mem_addr    | o        | axi_addr_width_g | Memory address             
| o_mem_wr      | o        | 4                | Memory byte write enables ()one signal per byte)             
| o_mem_wdata   | o        | 32               | Memory write data  
| i_mem_rdata   | i 			 | 32								| Memory read data            


[**component list**](../README.md)
