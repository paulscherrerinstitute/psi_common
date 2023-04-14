<img align="right" src="../psi_logo.png">

***

[**component list**](../README.md)

# psi_common_bit_cc
 - VHDL source: [psi_common_bit_cc](../../hdl/psi_common_bit_cc.vhd)
 - Testbench source: ..

### Description

This component implements a clock crossing for multiple independent single-bit signals. It contains double-stage synchronizers and sets all the attributes required for proper synthesis.
Note that this clock crossing does not guarantee that all bits arrive in the same clock cycle at the destination clock domain, therefore it can only be used for independent single-bit signals.

### Generics
| Name       | type     | Description                                             |
|:-----------|:---------|:--------------------------------------------------------|
| num_bits_g | positive | Number of data bits to implement the clock crossing for |

### Interfaces
| Name   | In/Out   | Length     | Description   		 |
|:-------|:---------|:-----------|:------------------|
| dat_i  | i        | num_bits_g | Input signals     |
| clk_i  | i        | 1          | Destination clock |
| dat_o  | o        | num_bits_g | Output signals    |

[**component list**](../README.md)
