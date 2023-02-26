<img align="right" src="../doc/psi_logo.png">
***

# psi_common_axi_multi_pl_stage
 - VHDL source: [psi_common_axi_multi_pl_stage](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_axi_multi_pl_stage.vhd)
 - Testbench source: [psi_common_axi_multi_pl_stage_tb.vhd](../testbench/psi_common_axi_multi_pl_stage_tb/psi_common_axi_multi_pl_stage_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name         | type      | Description   |
|:-------------|:----------|:--------------|
| addr_width_g | positive  | N.A           |
| data_width_g | positive  | N.A           |
| stages_g     | positive  | N.A           |
| rst_pol_g    | std_logic | N.A           |

### Interfaces
| Name        | In/Out   | Length       | Description                  |
|:------------|:---------|:-------------|:-----------------------------|
| clk_i       | i        | 1            | $$ type=clk; freq=100.0e6 $$ |
| rst_i       | i        | 1            | $$ type=rst; clk=clk $$      |
| in_awaddr   | i        | addr_width_g | N.A                          |
| in_awvalid  | i        | 1            | N.A                          |
| in_awready  | o        | 1            | N.A                          |
| in_awlen    | i        | 7            | N.A                          |
| in_awsize   | i        | 2            | N.A                          |
| in_awburst  | i        | 1            | N.A                          |
| in_awlock   | i        | 1            | N.A                          |
| in_awcache  | i        | 3            | N.A                          |
| in_awprot   | i        | 2            | N.A                          |
| in_wdata    | i        | data_width_g | N.A                          |
| in_wstrb    | i        | data_width_g | N.A                          |
| in_wvalid   | i        | 1            | N.A                          |
| in_wready   | o        | 1            | N.A                          |
| in_wlast    | i        | 1            | N.A                          |
| in_bresp    | o        | 1            | N.A                          |
| in_bvalid   | o        | 1            | N.A                          |
| in_bready   | i        | 1            | N.A                          |
| in_araddr   | i        | addr_width_g | N.A                          |
| in_arvalid  | i        | 1            | N.A                          |
| in_arready  | o        | 1            | N.A                          |
| in_arlen    | i        | 7            | N.A                          |
| in_arsize   | i        | 2            | N.A                          |
| in_arburst  | i        | 1            | N.A                          |
| in_arlock   | i        | 1            | N.A                          |
| in_arcache  | i        | 3            | N.A                          |
| in_arprot   | i        | 2            | N.A                          |
| in_rdata    | o        | data_width_g | N.A                          |
| in_rvalid   | o        | 1            | N.A                          |
| in_rready   | i        | 1            | N.A                          |
| in_rresp    | o        | 1            | N.A                          |
| in_rlast    | o        | 1            | N.A                          |
| out_awaddr  | o        | addr_width_g | N.A                          |
| out_awvalid | o        | 1            | N.A                          |
| out_awready | i        | 1            | N.A                          |
| out_awlen   | o        | 7            | N.A                          |
| out_awsize  | o        | 2            | N.A                          |
| out_awburst | o        | 1            | N.A                          |
| out_awlock  | o        | 1            | N.A                          |
| out_awcache | o        | 3            | N.A                          |
| out_awprot  | o        | 2            | N.A                          |
| out_wdata   | o        | data_width_g | N.A                          |
| out_wstrb   | o        | data_width_g | N.A                          |
| out_wvalid  | o        | 1            | N.A                          |
| out_wready  | i        | 1            | N.A                          |
| out_wlast   | o        | 1            | N.A                          |
| out_bresp   | i        | 1            | N.A                          |
| out_bvalid  | i        | 1            | N.A                          |
| out_bready  | o        | 1            | N.A                          |
| out_araddr  | o        | addr_width_g | N.A                          |
| out_arvalid | o        | 1            | N.A                          |
| out_arready | i        | 1            | N.A                          |
| out_arlen   | o        | 7            | N.A                          |
| out_arsize  | o        | 2            | N.A                          |
| out_arburst | o        | 1            | N.A                          |
| out_arlock  | o        | 1            | N.A                          |
| out_arcache | o        | 3            | N.A                          |
| out_arprot  | o        | 2            | N.A                          |
| out_rdata   | i        | data_width_g | N.A                          |
| out_rvalid  | i        | 1            | N.A                          |
| out_rready  | o        | 1            | N.A                          |
| out_rresp   | i        | 1            | N.A                          |
| out_rlast   | i        | 1            | N.A                          |