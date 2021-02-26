<img align="right" src="../psi_logo.png">

***
# psi_common_axi_slave_ipif
**32 bits support**
- VHDL source: [psi_common_axi_slave_ipif.vhd](../../hdl/psi_common_axi_slave_ipif.vhd)
- Testbench: [psi_common_axi_slave_ipif_tb.vhd](../../testbench/psi_common_axi_slave_ipif_tb/psi_common_axi_slave_ipif_tb.vhd)

**64 bits support**
- VHDL source: [psi_common_axi_slave_ipif64.vhd](../../hdl/psi_common_axi_slave_ipif64.vhd)
- Testbench: [psi_common_axi_slave_ipif64_tb.vhd](../../testbench/psi_common_axi_slave_ipif64_tb) *(require library **psi_tb** release 2.6.0)*

The description has been written for original 32 bits support, the 64 bits IP IP block doesn't have a dedicated description but it is essentially what is presented here below.

### 1 Description

This entity implements a full AXI-4 slave interface that can be used to
make custom IP-Cores accessible through AXI.

On the user interface (where the user code is attached), it supports
using registers as well as access to synchronous memory (e.g. BRAMs).
Burst are supported, also across the boundary between registers and
memory range.

The limitations of this block are given below:

-   It cannot be operated with memory only (at least 1 register must be
    used)

-   The number of registers must be a power of two

-   The latency of memory attached must be exactly one clock cycle

-   AXI bus width is fixed to 32-bits

Especially the limitation of the memory latency to one clock cycle is
suboptimal, since this prevents any additional pipelining in large
IP-Cores.

For registers, this entity handles read/write registers completely
independently. If readback of register values written via AXI should be
possible, the user code must loop-back write values (*o\_reg\_wdata*) to
read values (*i\_reg\_rdata*).

The memory range is placed in the memory map directly after the
registers. Example: If 8 registers are implemented, the registers are at
AXI addresses 0x00, 0x04, ... 0x1C and memory starts at the AXI address
0x20.

The offset of the memory is removed internally. So in the example above,
an access to the AXI address 0x24 (second memory cell) leads to the
memory address (*o\_mem\_addr)* 0x04 because the offset of 0x20 is
subtracted in the *psi\_common\_axi\_slave\_ipif* component.

### 2 IP Interface transactions

Only burst transactions of length 4 are shown in the waveforms for
simplicity reasons. Single word transactions behave the same as length 1
bursts.

For all waveforms, an implementation with 4 registers (*NumReg\_g* = 4)
is assumed. Hence the memory range starts at address 0x10.

#### 2.1 Register Write

When a register is written, a pulse on the corresponding *o\_reg\_wr*
signal is asserted together with the new data value.

<p align="center"><img src="ch10_5_fig37.png"></p>
<p align="center"> Register Write </p>

#### 2.2 Register Read

When a register is read, its value is sampled together with the pulse
being applied on the corresponding *o\_reg\_rd* signal. Hence he
*o\_reg\_rd* signal can for example be used to acknowledge reading from
a FIFO.

<p align="center"><img src="ch10_5_fig38.png"></p>
<p align="center"> Register Read </p>

#### 2.2 Memory Write

In this example, data in the AXI-addresses 0x12 ... 0x1D is written.
Since the example assumes four registers (addresses 0x00 ... 0x0F), this
translates to memory addresses 0x02 ... 0x0D on the user interface,
because the memory offset of 0x10 is subtracted internally.

<p align="center"><img src="ch10_5_fig39.png"></p>
<p align="center"> Memory write Read </p>

#### 2.3 Memory Read

In this example, data in the AXI-addresses 0x10 ... 0x1F is read. Since
the example assumes four registers (addresses 0x00 ... 0x0F), this
translates to memory addresses 0x01 ... 0x0F on the user interface,
because the memory offset of 0x10 is subtracted internally.

The example also nicely shows, that read data must be applied after
exactly one clock cycle.

<p align="center"><img src="ch10_5_fig40.png"></p>
<p align="center"> Memory Read </p>

#### 2.4 Write over Register/Memory Boundary

In this example, four data words are written to the addresses 0x08 ...
0x17. This includes two registers and two memory locations. Note that
the register and memory interfaces are not delay compensated, therefore
the first memory access happens at the same time as the last register
access.

<p align="center"><img src="ch10_5_fig41.png"></p>
<p align="center"> Write over register boundary </p>

### 3 Generics

Generics              | Description
----------------------|--------------------------------
**NumReg\_g**         |Number of registers to implement
**ResetVal\_g**       |Reset values for registers. The size of the array passed does not have to match *NumReg\_g*, if it does not, the reset values are applied to the first N registers and the other registers are reset to zero.
**UseMem\_g**         |**True** = use memory interface, **False** = use registers only
**AxiIdWidth\_g**     |Number of bits used for the AXI ID signals
**AxiAddrWidth\_g**  |Number of AXI address bits supported

### 4 Interfaces

 Signal          | Direction | Width           | Description     
-----------------|-----------|-----------------|-----------------
 ***Control Signals***  |||   
 s\_axi\_aclk    | Input     | 1               | Clock           
 s\_axi\_aresetn | Input     | 1               | Reset (low active)         
 ***Register Interface***    |                 |                 |        
 o\_reg\_rd      | Output    | *NumReg\_g*     | Read-pulse for each register   
 i\_reg\_rdata   | Input     |*NumReg\_g x 32* | Register read values  
 o\_reg\_wr      | Input     | *NumReg\_g*     | Write-pulse for each register   
 o\_reg\_wdata   | Input     |*NumReg\_g x 32* | Register write values          
 ***Memory Interface***      |                 |                  |         
 o\_mem\_addr    | Output    | *AxiAddrWidth\_g* | Memory address  
 o\_mem\_wr      | Output    | *4*             | Memory byte write enables (one signal per byte)           
 o\_mem\_wdata   | Output    | 32              | Memory write data            
 i\_mem\_rdata   | Input     | 32              | Memory read data must be valid one clock cycle after *o\_mem\_addr*  
 ***AXI Slave Interface***   |                 |                  |
 s\_axi\_\*      | \*        | \*              | AXI signals, see AXI specification   

***
[Index](../psi_common_index.md) **|** Previous: [Interfaces > axi master full](../ch10_interfaces/ch10_4_axi_master_full.md) **|**
Next: [Interfaces > axilite slave ipif](./ch10_6_axilite_slave_ipif.md)
