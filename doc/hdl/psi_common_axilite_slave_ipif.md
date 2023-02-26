<img align="right" src="../doc/psi_logo.png">
***

# psi_common_axilite_slave_ipif
 - VHDL source: [psi_common_axilite_slave_ipif](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_axilite_slave_ipif.vhd)
 - Testbench source: [psi_common_axilite_slave_ipif_tb.vhd](../testbench/psi_common_axilite_slave_ipif_tb/psi_common_axilite_slave_ipif_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name             | type     | Description                               |
|:-----------------|:---------|:------------------------------------------|
| num_reg_g        | integer  | $$ export=true $$                         |
| rst_val_g        | t_aslv32 | $$ constant=(x"0001abcd", x"00021234") $$ |
| use_mem_g        | boolean  | $$ export=true $$                         |
| axi_addr_width_g | integer  | N.A                                       |

### Interfaces
| Name              | In/Out   | Length           | Description                                    |
|:------------------|:---------|:-----------------|:-----------------------------------------------|
| s_axilite_aclk    | i        | 1                | $$ type=clk; freq=100e6 $$                     |
| s_axilite_aresetn | i        | 1                | $$ type=rst; clk=s_axi_aclk; lowactive=true $$ |
| s_axilite_araddr  | i        | axi_addr_width_g | $$ proc=axi $$                                 |
| s_axilite_arvalid | i        | 1                | $$ proc=axi $$                                 |
| s_axilite_arready | o        | 1                | $$ proc=axi $$                                 |
| s_axilite_rdata   | o        | 31               | $$ proc=axi $$                                 |
| s_axilite_rresp   | o        | 1                | $$ proc=axi $$                                 |
| s_axilite_rvalid  | o        | 1                | $$ proc=axi $$                                 |
| s_axilite_rready  | i        | 1                | $$ proc=axi $$                                 |
| s_axilite_awaddr  | i        | axi_addr_width_g | $$ proc=axi $$                                 |
| s_axilite_awvalid | i        | 1                | $$ proc=axi $$                                 |
| s_axilite_awready | o        | 1                | $$ proc=axi $$                                 |
| s_axilite_wdata   | i        | 31               | $$ proc=axi $$                                 |
| s_axilite_wstrb   | i        | 3                | $$ proc=axi $$                                 |
| s_axilite_wvalid  | i        | 1                | $$ proc=axi $$                                 |
| s_axilite_wready  | o        | 1                | $$ proc=axi $$                                 |
| s_axilite_bresp   | o        | 1                | $$ proc=axi $$                                 |
| s_axilite_bvalid  | o        | 1                | $$ proc=axi $$                                 |
| s_axilite_bready  | i        | 1                | $$ proc=axi $$                                 |
| o_reg_rd          | o        | num_reg_g        | $$ proc=ip $$                                  |
| o_reg_wr          | o        | num_reg_g        | $$ proc=ip $$                                  |
| o_reg_wdata       | o        | 1                | $$ proc=ip $$                                  |
| o_mem_addr        | o        | axi_addr_width_g | $$ proc=ip $$                                  |
| o_mem_wr          | o        | 3                | $$ proc=ip $$                                  |
| o_mem_wdata       | o        | 31               | $$ proc=ip $$                                  |