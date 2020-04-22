<img align="right" src="../psi_logo.png">

***
# psi_common_pulse_shaper_cfg

- VHDL source: [psi_common_pulse_shaper_cfg.vhd](../../hdl/psi_common_pulse_shaper_cfg.vhd)
- Testbench: [psi_common_pulse_shaper_cfg_tb.vhd](../../testbench/psi_common_pulse_shaper_cfg_tb/psi_common_pulse_shaper_cfg_tb.vhd)

### Description

This component is similar to *psi\_common\_pulse\_shaper* ([psi_common_pulse_shaper](ch6_4_pulse_shaper.md)) but it is configurable in runtime. It
allows giving the pulse width (duration) and the hold off time as registers in runtime.

### Generics

Generics               | Description
-----------------------|----------------------------------------
**MaxDuration\_g**     | Maximum duration allowed in clock cycles
**HoldOffEna\_g**      | Enable hold-off mode -- skip new pulses if arrivingtoo fast
**HoldIn\_g**          | If true it holds the input at the output, in case thepulse isn't pulse but a start signal
**MaxHoldOff\_g**      | Maximum clock cycles for the minimum time between each new input pulse-rising-edges that are detected (in clock cycles) - Pulses arriving during the hold-off time are ignored
**RstPol\_g**          | Defines reset polarity

### Interfaces

Signal    |Direction  |Width                     |Description
----------|-----------|--------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------
clk\_i    |Input      |1                         |Clock input
rst\_i    |Input      |1                         |Reset input, polarity is set by generic
dat\_i    |Input      |1                         |Input Pulse
width\_i  |Input      |Log2ceil(MaxDuration\_g)  |Pulse width (duration) in clock cycles, if set to 0 no pulse will be generated.
hold\_i   |Input      |Log2ceil(MaxHoldOff\_g)   |Minimum time between each new input pulse-rising edges that are detected (in clock cycles) -- Pulse arriving during hold-off time are ignored
dat\_o    |Output     |1                         |Output Pulse

***
[Index](../psi_common_index.md) **|** Previous: [timing > pulse shaper](../ch6_timing/ch6_4_pulse_shaper.md) **|** Next: [timing > clk meas](../ch6_timing/ch6_6_clk_meas.md)
