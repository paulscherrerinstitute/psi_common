<img align="right" src="../doc/psi_logo.png">
***

# psi_common_ping_pong
 - VHDL source: [psi_common_ping_pong](C:/Users/stef_b/git/GFA/Libraries/Firmware/VHDL/psi_common/hdl/psi_common_ping_pong.vhd)
 - Testbench source: [psi_common_ping_pong_tb.vhd](../testbench/psi_common_ping_pong_tb/psi_common_ping_pong_tb.vhd)

### Description
*INSERT YOUR TEXT*

### Generics
| Name            | type      | Description                        |
|:----------------|:----------|:-----------------------------------|
| generic(ch_nb_g | natural   | channel number -> master 8         |
| sample_nb_g     | natural   | sample number per memory space     |
| dat_length_g    | positive  | data width in bits                 |
| tdm_g           | boolean   | tdm* behavior if false par         |
| ram_behavior_g  | string    | ram behavior "rbw"|"wbr" -> cf ram |
| rst_pol_g       | std_logic | reset polarity                     |

### Interfaces
| Name           | In/Out   | Length       | Description                                   |
|:---------------|:---------|:-------------|:----------------------------------------------|
| clk_i          | i        | 1            | clock data                                    |
| rst_i          | i        | 1            | rst data                                      |
| dat_i          | i        | tdm_g,       | data input                                    |
| str_i          | i        | ie           | strobe input (ie valid)                       |
| mem_irq_o      | o        | 1            | indicate when a set of buffer has been filled |
| mem_clk_i      | i        | 1            | clock mem                                     |
| mem_addr_ch_i  | i        | ch_nb_g)     | channel selection for mem read                |
| mem_addr_spl_i | i        | sample_nb_g) | sample selection for mem read                 |
| mem_dat_o      | o        | dat_length_g | data mem read                                 |