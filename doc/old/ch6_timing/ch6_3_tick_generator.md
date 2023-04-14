<img align="right" src="../psi_logo.png">

***
# psi_common_tick_generator

- VHDL source: [psi_common_tickgenerator.vhd](../../hdl/psi_common_tickgenerator.vhd)
- Testbench: [psi_common_tickgenerator_tb.vhd](../../testbench/psi_common_tickgenerator_tb/psi_common_tickgenerator_tb.vhd)


### Description

This component generated pulses at the commonly used time bases in a system (second, millisecond, microsecond) based on the clock frequency. The width of the tick-pulses is configurable.

### Generics

Generics                         | Description
---------------------------------|--------------
**g\_CLK\_IN\_MHZ** 						 |Clock frequency in MHz
**g\_TICK\_WIDTH**							 | Pulse-width of the tick outputs
**g\_SIM\_SEC\_SPEEDUP\_FACTOR** | Factor to speedup the second tick in simulations (reduction of simulation runtimes). For implementation this generic must be set to 1.

### Interfaces


Signal       |Direction  |Width  |Description
-------------|-----------|-------|-------------------------
clock\_i     |Input      |1      |Clock input
tick1us\_o   |Output     |1      |Microsecond tick output
tick1ms\_o   |Output     |1      |Millisecond tick output
tick1sec\_o  |Output     |1      |Second tick output

***
[Index](../psi_common_index.md) **|** Previous: [timing > strobe divider](../ch6_timing/ch6_2_strobe_divider.md) **|** Next: [timing > pulse shaper](../ch6_timing/ch6_4_pulse_shaper.md)
