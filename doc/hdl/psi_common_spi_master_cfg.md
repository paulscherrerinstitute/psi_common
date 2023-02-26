<img align="right" src="../doc/psi_logo.png">
***

# psi_common_spi_master_cfg
 - VHDL source: [psi_common_spi_master_cfg](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_spi_master_cfg.vhd)
 - Testbench source: [psi_common_spi_master_cfg_tb.vhd](../testbench/psi_common_spi_master_cfg_tb/psi_common_spi_master_cfg_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name              | type      | Description                                |
|:------------------|:----------|:-------------------------------------------|
| clock_divider_g   | natural   | must be a multiple of two $$ constant=8 $$ |
| max_trans_width_g | positive  | spi transaction width $$ constant=8 $$     |
| cs_high_cycles_g  | positive  | $$ constant=2 $$                           |
| spi_cpol_g        | natural   | $$ export=true $$                          |
| spi_cpha_g        | natural   | $$ export=true $$                          |
| slave_cnt_g       | positive  | $$ constant=2 $$                           |
| lsb_first_g       | boolean   | $$ export=true $$                          |
| mosi_idle_state_g | std_logic | N.A                                        |
| rst_pol_g         | std_logic | N.A                                        |

### Interfaces
| Name          | In/Out   | Length             | Description                |
|:--------------|:---------|:-------------------|:---------------------------|
| clk_i         | i        | 1                  | $$ type=clk; freq=100e6 $$ |
| rst_i         | i        | 1                  | $$ type=rst; clk=clk $$    |
| start_i       | i        | 1                  | N.A                        |
| slave_i       | i        | slave_cnt_g)       | N.A                        |
| busy_o        | o        | 1                  | N.A                        |
| done_o        | o        | 1                  | N.A                        |
| wr_dat_i      | i        | max_trans_width_g  | N.A                        |
| rd_dat_o      | o        | max_trans_width_g  | N.A                        |
| trans_width_i | i        | max_trans_width_g) | N.A                        |
| spi_sck_o     | o        | 1                  | N.A                        |
| spi_mosi_o    | o        | 1                  | N.A                        |
| spi_miso_i    | i        | 1                  | N.A                        |
| spi_cs_n_o    | o        | slave_cnt_g        | N.A                        |