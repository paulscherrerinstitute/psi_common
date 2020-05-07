<img align="right" src="../psi_logo.png">

***
# psi_common_sync_fifo

- VHDL source: [psi_common_sync_fifo.vhd](../../hdl/psi_common_sync_fifo.vhd)
- Testbench: [psi_common_sync_fifo_tb.vhd](../../testbench/psi_common_sync_fifo_tb/psi_common_sync_fifo_tb.vhd)

### Description

This component implements a synchronous FIFO (same clock for write and
read port). The memory is described in a way that it utilizes RAM
resources (Block-RAM or distributed RAM) available in FPGAs with
commonly used tools.

The FIFO is a fall-through FIFO and has AXI-S interfaces on read and
write side.

The RAM behavior (read-before-write or write-before-read) can be
selected. This allows efficiently implementing FIFOs for different
technologies (some technologies implement one, some the other behavior).

### Generics

Generics            | Description
--------------------|----------------------------------------------------------------------------
**Width\_g**        | Width of the FIFO
**Depth\_g**        | Depth of the FIFO
**AlmFullOn\_g**    | **True** = Almost full output is provided, **False** = Almost full output is omitted
**AlmFullLevel\_g** | Almost full output is high if the level is \>= AlmFullLevel\_g
**AlmEmptyOn\_g**   | **True** = Almost empty output is provided, **False** = Almost empty output is omitted
**AlmEmptyLevel\_g**| Almost empty output is high if the level is \<= AlmFullLevel\_g
**RamStyle\_g**     | **"auto"** (default) Automatic choice of block- or distributed-RAM, **"distributed"** Use distributed RAM (LUT-RAM, **"block"** Use block RAM\
**RamBehavior\_g**  | **"RBW"** Read-before-write implementation, **"WBR"** Write-before-read implementation
**RdyRstState\_g**  | State of *InRdy* signal during reset. Usually this does not play a role and the default setting ('1') that leads to the least logic on the InRdy path is fine. Setting the value to '0' may lead to less optimal performance in terms of FMAX.

### Interfaces

Signal                             |Direction  |Width     |Description
-----------------------------------|-----------|----------|---------------------------
Clk                                |Input      |1         |Clock
Rst                                |Input      |1         |Reset input (active high)
InData                             |Input      |Width\_g  |Write data
InVld                              |Input      |1         |AXI-S handshaking signal
InRdy                              |Output     |1         |AXI-S handshaking signal
OutData                            |Output     |Width\_g  |Read data
OutVld                             |Output     |1         |AXI-S handshaking signal
OutRdy                             |Input      |1         |AXI-S handshaking signal
InFull                             | Output    |1         |FIFO full signal synchronous to *InClk*          
InEmpty                            | Output    |1         |FIFO empty signal synchronous to *InClk*          
InAlmFull                          | Output    |1         | FIFO almost full signal synchronous to *InClk* Only exists if *AlmFullOn\_g* = true            
InAlmEmpty                         | Output    |1         | FIFO almost empty signal synchronous to *InClk*  Only exists if *AlmEmptyOn\_g* = true  
InLevel                            | Output    | ceil(log2(Depth\_g))+1    | FIFO level synchronous to *InClk*   
OutFull                            | Output    | 1        | FIFO full signal synchronous to *OutClk*       
OutEmpty                           | Output    | 1        | FIFO empty signal synchronous to *OutClk*         
OutAlmFull                         | Output    | 1        | FIFO almost full signal synchronous to *OutClk*  Only exists if *AlmFullOn\_g* =  true      
OutAlmEmpty                        | Output    | 1        | FIFO almost  empty signal synchronous to *OutClk* Only exists if *AlmEmptyOn\_g*= true           
OutLevel                           | Output    | ceil(log2(Depth\_g))+1  | FIFO level     synchronous to  *OutClk*

***
[Index](../psi_common_index.md)**|** Previous: [FIFO > async fifo](../ch4_fifos/ch4_1_async_fifo.md) **|** Next: [CC | Pulse cc](../ch5_cc/ch5_1_pulse_cc.md)
