<img align="right" src="../doc/psi_logo.png">
***

# psi_common_axi_master_simple
 - VHDL source: [psi_common_axi_master_simple](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_axi_master_simple.vhd)
 - Testbench source: [psi_common_axi_master_simple_tb.vhd](../testbench/psi_common_axi_master_simple_tb/psi_common_axi_master_simple_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name                         | type    | Description          |
|:-----------------------------|:--------|:---------------------|
| axi_addr_width_g             | natural | $$ constant=32 $$    |
| axi_data_width_g             | natural | $$ constant=16 $$    |
| axi_max_beats_g              | natural | $$ constant=16 $$    |
| axi_max_open_transactions_g  | natural | $$ constant=3 $$     |
| user_transaction_size_bits_g | natural | $$ constant=10 $$    |
| data_fifo_depth_g            | natural | $$ constant=10 $$    |
| impl_read_g                  | boolean | $$ export=true $$    |
| impl_write_g                 | boolean | $$ export=true $$    |
| ram_behavior_g               | string  | $$ constant="rbw" $$ |

### Interfaces
| Name          | In/Out   | Length           | Description                                    |
|:--------------|:---------|:-----------------|:-----------------------------------------------|
| m_axi_aclk    | i        | 1                | $$ type=clk; freq=100e6 $$                     |
| m_axi_aresetn | i        | 1                | $$ type=rst; clk=m_axi_aclk; lowactive=true $$ |
| cmd_wr_rdy_o  | o        | 1                | $$ proc=user_cmd $$                            |
| cmd_rd_rdy_o  | o        | 1                | $$ proc=user_cmd $$                            |
| wr_rdy_o      | o        | 1                | $$ proc=user_data $$                           |
| rd_dat_o      | o        | axi_data_width_g | $$ proc=user_data $$                           |
| rd_vld_o      | o        | 1                | $$ proc=user_data $$                           |
| wr_done_o     | o        | 1                | $$ proc=user_resp $$                           |
| wr_error_o    | o        | 1                | $$ proc=user_resp $$                           |
| rd_done_o     | o        | 1                | $$ proc=user_resp $$                           |
| rd_error_o    | o        | 1                | $$ proc=user_resp $$                           |
| m_axi_awaddr  | o        | axi_addr_width_g | $$ proc=axi $$                                 |
| m_axi_awlen   | o        | 7                | $$ proc=axi $$                                 |
| m_axi_awsize  | o        | 2                | $$ proc=axi $$                                 |
| m_axi_awburst | o        | 1                | $$ proc=axi $$                                 |
| m_axi_awlock  | o        | 1                | $$ proc=axi $$                                 |
| m_axi_awcache | o        | 3                | $$ proc=axi $$                                 |
| m_axi_awprot  | o        | 2                | $$ proc=axi $$                                 |
| m_axi_awvalid | o        | 1                | $$ proc=axi $$                                 |
| m_axi_wdata   | o        | axi_data_width_g | $$ proc=axi $$                                 |
| m_axi_wstrb   | o        | axi_data_width_g | $$ proc=axi $$                                 |
| m_axi_wlast   | o        | 1                | $$ proc=axi $$                                 |
| m_axi_wvalid  | o        | 1                | $$ proc=axi $$                                 |
| m_axi_bready  | o        | 1                | $$ proc=axi $$                                 |
| m_axi_araddr  | o        | axi_addr_width_g | $$ proc=axi $$                                 |
| m_axi_arlen   | o        | 7                | $$ proc=axi $$                                 |
| m_axi_arsize  | o        | 2                | $$ proc=axi $$                                 |
| m_axi_arburst | o        | 1                | $$ proc=axi $$                                 |
| m_axi_arlock  | o        | 1                | $$ proc=axi $$                                 |
| m_axi_arcache | o        | 3                | $$ proc=axi $$                                 |
| m_axi_arprot  | o        | 2                | $$ proc=axi $$                                 |
| m_axi_arvalid | o        | 1                | $$ proc=axi $$                                 |
| m_axi_rready  | o        | 1                | $$ proc=axi $$                                 |