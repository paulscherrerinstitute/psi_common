<img align="right" src="../doc/psi_logo.png">
***

# psi_common_axi_slave_ipif
 - VHDL source: [psi_common_axi_slave_ipif](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_axi_slave_ipif.vhd)
 - Testbench source: [psi_common_axi_slave_ipif_tb.vhd](../testbench/psi_common_axi_slave_ipif_tb/psi_common_axi_slave_ipif_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name             | type     | Description                               |
|:-----------------|:---------|:------------------------------------------|
| num_reg_g        | integer  | $$ export=true $$                         |
| rst_val_g        | t_aslv32 | $$ constant=(x"0001abcd", x"00021234") $$ |
| use_mem_g        | boolean  | $$ export=true $$                         |
| axi_id_width_g   | integer  | N.A                                       |
| axi_addr_width_g | integer  | N.A                                       |

### Interfaces
| Name          | In/Out   | Length           | Description                                    |
|:--------------|:---------|:-----------------|:-----------------------------------------------|
| s_axi_aclk    | i        | 1                | $$ type=clk; freq=100e6 $$                     |
| s_axi_aresetn | i        | 1                | $$ type=rst; clk=s_axi_aclk; lowactive=true $$ |
| s_axi_arid    | i        | axi_id_width_g   | $$ proc=axi $$                                 |
| s_axi_araddr  | i        | axi_addr_width_g | $$ proc=axi $$                                 |
| s_axi_arlen   | i        | 7                | $$ proc=axi $$                                 |
| s_axi_arsize  | i        | 2                | $$ proc=axi $$                                 |
| s_axi_arburst | i        | 1                | $$ proc=axi $$                                 |
| s_axi_arlock  | i        | 1                | $$ proc=axi $$                                 |
| s_axi_arcache | i        | 3                | $$ proc=axi $$                                 |
| s_axi_arprot  | i        | 2                | $$ proc=axi $$                                 |
| s_axi_arvalid | i        | 1                | $$ proc=axi $$                                 |
| s_axi_arready | o        | 1                | $$ proc=axi $$                                 |
| s_axi_rid     | o        | axi_id_width_g   | $$ proc=axi $$                                 |
| s_axi_rdata   | o        | 31               | $$ proc=axi $$                                 |
| s_axi_rresp   | o        | 1                | $$ proc=axi $$                                 |
| s_axi_rlast   | o        | 1                | $$ proc=axi $$                                 |
| s_axi_rvalid  | o        | 1                | $$ proc=axi $$                                 |
| s_axi_rready  | i        | 1                | $$ proc=axi $$                                 |
| s_axi_awid    | i        | axi_id_width_g   | $$ proc=axi $$                                 |
| s_axi_awaddr  | i        | axi_addr_width_g | $$ proc=axi $$                                 |
| s_axi_awlen   | i        | 7                | $$ proc=axi $$                                 |
| s_axi_awsize  | i        | 2                | $$ proc=axi $$                                 |
| s_axi_awburst | i        | 1                | $$ proc=axi $$                                 |
| s_axi_awlock  | i        | 1                | $$ proc=axi $$                                 |
| s_axi_awcache | i        | 3                | $$ proc=axi $$                                 |
| s_axi_awprot  | i        | 2                | $$ proc=axi $$                                 |
| s_axi_awvalid | i        | 1                | $$ proc=axi $$                                 |
| s_axi_awready | o        | 1                | $$ proc=axi $$                                 |
| s_axi_wdata   | i        | 31               | $$ proc=axi $$                                 |
| s_axi_wstrb   | i        | 3                | $$ proc=axi $$                                 |
| s_axi_wlast   | i        | 1                | $$ proc=axi $$                                 |
| s_axi_wvalid  | i        | 1                | $$ proc=axi $$                                 |
| s_axi_wready  | o        | 1                | $$ proc=axi $$                                 |
| s_axi_bid     | o        | axi_id_width_g   | $$ proc=axi $$                                 |
| s_axi_bresp   | o        | 1                | $$ proc=axi $$                                 |
| s_axi_bvalid  | o        | 1                | $$ proc=axi $$                                 |
| s_axi_bready  | i        | 1                | $$ proc=axi $$                                 |
| o_reg_rd      | o        | num_reg_g        | $$ proc=ip $$                                  |
| o_reg_wr      | o        | num_reg_g        | $$ proc=ip $$                                  |
| o_reg_wdata   | o        | 1                | $$ proc=ip $$                                  |
| o_mem_addr    | o        | axi_addr_width_g | $$ proc=ip $$                                  |
| o_mem_wr      | o        | 3                | $$ proc=ip $$                                  |
| o_mem_wdata   | o        | 31               | $$ proc=ip $$                                  |