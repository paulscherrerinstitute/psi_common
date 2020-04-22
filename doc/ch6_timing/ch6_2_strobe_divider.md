<img align="right" src="../psi_logo.png">

***
# psi_common_strobe_divider

- VHDL source: [psi_common_strobe_divider.vhd](../../hdl/psi_common_strobe_divider.vhd)
- Testbench: [psi_common_strobe_divider_tb.vhd](../../testbench/psi_common_strobe_divider_tb/psi_common_strobe_divider_tb.vhd)


### Description

This component divides the rate of a strobe signal. Only every N strobe signal is forwarded to the output. If the input is not a single cycle strobe signal, a rising edge detection is done (strobe is detected on the first cycle the input is high).

The division ratio is selectable at runtime.

### Generics

Generics        | Description
----------------|------------
**length\_g**   | Width of the *ratio\_i* input in bits
**rst\_pol\_g** | Reset polarity ('1' = high active)

### Interfaces


 Signal  | Direction | Width     | Description                     
---------|-----------|-----------|---------------------------------
 InClk   | Input     | 1         | Clock                           
 InRst   | Input     | 1         | Reset input                     
 InVld   | Input     | 1         | Strobe input                    
 InRatio | Input     | length\_g | Division ratio (1 = no division, 2 = division by 2) 0 leads to the same behavior as  1.                              
 OutVld  | Output    | 1         | Strobe output                 


***
[Index](../psi_common_index.md) **|** Previous: [timing > strobe generator](../ch6_timing/ch6_1_strobe_generator.md) **|** Next: [timing > tick generator](../ch6_timing/ch6_3_tick_generator.md)
