<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_spi_master_cfg
 - VHDL source: [psi_common_spi_master_cfg](../../hdl/psi_common_spi_master_cfg.vhd)
 - Testbench source: [psi_common_spi_master_cfg_tb.vhd](../../testbench/psi_common_spi_master_cfg_tb/psi_common_spi_master_cfg_tb.vhd)

### Description

**This component allows enlarging dynamically the bit width of the transfer via MaxTransWidth_g generic statement and TransWidth input.**

The description here below is the same as *psi_common_spi_master*

This entity implements a simple SPI master. All common SPI settings are
settable to ensure the master can be configured for different
applications.

The clock and data phase is configurable according to the SPI standard
terminology described in the picture below:

<p align="center"><img src="psi_common_spi_master_fig0.png"> </p>
<p align="center"> CPOL and CPHA meaning </p>

For CPHA = 1, the sampling happens on the second edge (blue) and data is
applied on the first edge (red). For CPHA = 0 it is the opposite way.

### Generics
| Name              | type      | Description                                |
|:------------------|:----------|:-------------------------------------------|
| clock_divider_g   | natural   | Must be a multiple of two, Ratio between clk_i and the spi_sck_o frequency
| max_trans_width_g | positive  | Maximum SPI Transfer width (bits per transfer)
| cs_high_cycles_g  | positive  | Minimal number of spi_cs_n_o high cycles between two transfers
| spi_cpol_g        | natural   | SPI clock polarity
| spi_cpha_g        | natural   | SPI sampling edge configuration
| slave_cnt_g       | positive  | Number of slaves to support (number of spi_cs_n_o* lines)
| lsb_first_g       | boolean   | False => MSB first transmission, True => LSB first transmission
| mosi_idle_state_g | std_logic | Idle state of the MOSI line
| rst_pol_g         | std_logic | reset polarity, '1' active high


### Interfaces
| Name          | In/Out   | Length             | Description                |
|:--------------|:---------|:-------------------|:---------------------------|
| clk_i         | i        | 1                  |  system clock |
| rst_i         | i        | 1                  |  system reset |
| start_i       | i        | 1                  | starts the transfer. Note that starting a transaction is  only possible when busy_o is low.
| slave_i       | i        | slave_cnt_g)       | Slave number to access  
| busy_o        | o        | 1                  | High during a transaction
| done_o        | o        | 1                  | Goes high for a clock cycle after transaction is done and *rd_dat_o* is valid  
| wr_dat_i      | i        | max_trans_width_g  | Data to send to slave. Sampled  during start_i = '1'
| rd_dat_o      | o        | max_trans_width_g  | Data received from slave. Must be sampled during done = '1' or busy = '0'.   
| trans_width_i | i        | max_trans_width_g) | indicate the actual vector length to forward/receive
| spi_sck_o     | o        | 1                  | SPI clock  
| spi_mosi_o    | o        | 1                  | SPI master to slave data signal
| spi_miso_i    | i        | 1                  | SPI slave to master data signal  
| spi_cs_n_o    | o        | slave_cnt_g        | SPI slave select signal (low active)

<p align="center"><img src="psi_common_spi_master_fig1.png"> </p>
<p align="center"> Parallel interface signal behavior </p>

[**component list**](../README.md)
