<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_tdp_ram_be
 - VHDL source: [psi_common_tdp_ram_be](../../hdl/psi_common_tdp_ram_be.vhd)
 - Testbench source: [psi_common_tdp_ram_be_tb.vhd](../../testbench/psi_common_tdp_ram_be_tb/psi_common_tdp_ram_be_tb.vhd)


### Description
Same as [psi_common_tdp_ram](psi_common_tdp_ram.md) but with byte-enables. A byte is only
 written if **Wr** is set and the corresponding **Be** bit is set too. Work well for 32 bits, we observed issue and recommend to use xilinx templates.

### Generics

 Generics        | Description
 ----------------|--------------------
 **Depth\_g**    | Depth of the memory
 **Width\_g**    | Width of the memory, must be a multiple of 8
 **Behavior\_g** | **"RBW"** Read-before-write implementation, **"WBR"** Write-before-read implementation

 ### Interfaces

 Signal                  |Direction   |Width                 |Description
 ----------------------- |----------- |----------------------|-----------------------------------
  a_clk_i                    |Input       |1                     |Port A clock
  a_addr_i                   |Input       |Width\_g/8            |Port A byte enables
  a_be_i                     |Input       |ceil(log2(Depth\_g))  |Port A address
  a_wr_i                     |Input       |1                     |Port A write enable (active high)
  a_dat_i                    |Input       |Width\_g              |Port A write data
  a_dat_o                    |Output      |Width\_g              |Port A read data
  b_clk_i                    |Input       |1                     |Port B clock
  b_addr_i                   |Input       |Width\_g/8            |Port B byte enables
  b_be_i                     |Input       |ceil(log2(Depth\_g))  |Port B address
  b_wr_i                     |Input       |1                     |Port B write enable (active high)
  b_dat_i                    |Input       |Width\_g              |Port B write data
  b_dat_o                   |Output      |Width\_g              |Port B read data
 ### Constraints

 [**component list**](../README.md)
