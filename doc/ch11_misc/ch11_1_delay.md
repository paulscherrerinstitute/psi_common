<img align="right" src="../psi_logo.png">

***
# psi_common_delay

- VHDL source: [psi_common_delay.vhd](../../hdl/psi_common_delay.vhd)
- Testbench: [psi_common_delay_tb.vhd](../../testbench/psi_common_delay_tb/psi_common_delay_tb.vhd)

### Description

This component is an efficient implementation for delay chains. It uses
FPGA memory resources (Block-RAM and distributed RAM resp. SRLs) for
implementing the delays (instead of many FFs). The last delay stage is
always implemented in FFs to ensure good timing (RAM outputs are usually
slow).

One Problem with using RAM resources to implement delays is that they
don't have a reset, so the content of the RAM persists after resetting
the logic. The *psi\_common\_delay* entity works around this issue by
some logic that ensures that any persisting data is replaced by zeros
after a reset. The replacement is done at the output of the
*psi\_common\_delay*, so no time to overwrite memory cells after a reset
is required and the entity is ready to operate on the first clock cycle
after the reset.

If the delay is implemented using a RAM, the behavior of the RAM
(read-before-write or write-before-read) can be selected to allow
efficient implementation independently of the target technology.

### Generics

Generics             | Description
---------------------|-------------------------------------------------------
**Width\_g**         |Width of the data to delay
**Delay\_g**         |Number of delay taps
**Resource\_g**    |**"AUTO"** (default) automatically use SRL or BRAM according to *BramThreshold\_g, **"BRAM"** use Block RAM to implement the delay taps, **"SRL"** use SRLs (LUTs used as shift registers) to implement the delay taps
**BramThreshold\_g** |This generic controls the resources to use for the delay taps in case *Resource\_g ="AUTO".* SRLs are used if *Delay\_g* \< *BramThreshold\_g*. Otherwise BRAMs are used.
**RstState\_g**      |**True** Persisting memory content is replaced by zeros after reset, **False** Persisting memory content is visible at output after reset (less resource usage)
**RamBehavior\_g**   |**"RBW"** Read-before-write implementation, **"WBR"** Write-before-read implementation This generic is only used if a BRAM is used for the delay.

### Interfaces

Signal                 |Direction  |Width     |Description
-----------------------|-----------|----------|------------------------------------------------
Clk                    |Input      |1         |Clock
Rst                    |Input      |1         |Reset (high active)
Vld                    |Input      |1         |InData valid (clock enable for shift register)
InData                 |Input      |Width\_g  |Data input
OutData                |Output     |Width\_g  |Data output


***
[Index](../psi_common_index.md) **|** Previous: [Interfaces > axi slave ipif](../ch10_interfaces/ch10_5_axi_slave_ipif.md) **|** Next: [Misc > pl stage](../ch11_misc/ch11_2_pl_stage.md)
