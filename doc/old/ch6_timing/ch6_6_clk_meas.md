<img align="right" src="../psi_logo.png">

***
# psi_common_clk_meas

- VHDL source: [psi_common_clk_meas.vhd](../../hdl/psi_common_clk_meas.vhd)
- Testbench: [psi_common_clk_meas_tb.vhd](../../testbench/psi_common_clk_meas_tb/psi_common_clk_meas_tb.vhd)

### Description

This component measures the clock (*ClkTest*) under the assumption that a second clock (*ClkMaster*) runs at a known frequency.

### Generics
Generics                | Description
------------------------|--------------
**MasterFrequency\_g**  |Clock frequency of the master clock in Hz\
**MaxMeasFrequency\_g** | Maximum supported frequency for *ClkTest*

### Interfaces

Signal        |Direction  |Width  |Description
--------------|-----------|-------|-----------------------------------------------------------
ClkMaster     |Input      |1      |Master input clock
Rst           |Input      |1      |Reset (synchronous to *ClkMaster*)
ClkTest       |Input      |1      |Test input clock
FrequencyHz   |Output     |32     |Clock frequency for *ClkTest* in Hz
FrequencyVld  |Output     |1      |Handshaking signal (set on every update of *FrequencyHz*)

***
[Index](../psi_common_index.md) **|** Previous: [timing > pulse shaper cfg](../ch6_timing/ch6_5_pulse_shaper_cfg.md) **|** Next: [conversion > wconv n2xn](../ch7_conversions/ch7_1_wconv_n2xn.md)
