<img align="right" src="../psi_logo.png">

***
# psi_common_async_fifo

- VHDL source: [psi_common_async_fifo.vhd](../../hdl/psi_common_async_fifo.vhd)
- Testbench: [psi_common_async_fifo_tb.vhd](../../testbench/psi_common_async_fifo_tb/psi_common_async_fifo_tb.vhd)

### Description

This component implements an asynchronous FIFO (different clocks for
write and read port). The memory is described in a way that it utilizes
RAM resources (Block-RAM) available in FPGAs with commonly used tools.

The FIFO is a fall-through FIFO and has AXI-S interfaces on read and
write side.

The RAM behavior (read-before-write or write-before-read) can be
selected. This allows efficiently implementing FIFOs for different
technologies (some technologies implement one, some the other behavior).

### Generics

Generics            | Description
--------------------|-----------------
**Width\_g**        | Width of the FIFO
**Depth\_g**        | Depth of the FIFO
**AlmFullOn\_g**    | **True** = Almost full output is provided, **False** = Almost full output is omitted
**AlmFullLevel\_g** | Almost full output is high if the level is \>= AlmFullLevel\_g
**AlmEmptyOn\_g**   | True = Almost empty output is provided, False = Almost empty output is omitted
**AlmEmptyLevel\_g**| Almost empty output is high if the level is \<= AlmFullLevel\_g
**RamStyle\_g**     | **"auto"** (default) Automatic choice of block- or distributed-RAM **"distributed"** Use distributed RAM (LUT-RAM), **"block"** Use block RAM
**RamBehavior\_g**  | **"RBW"** Read-before-write implementation, **"WBR"** Write-before-read implementation
**RdyRstState\_g**  | State of *InRdy* signal during reset. Usually this does not play a role and the default setting ('1') that leads to the least logic on the InRdy path is fine. Setting the value to '0' may lead to less optimal performance in terms of FMAX.


### Interfaces


 Signal          | Direction | Width    | Description     
-----------------|-----------|----------|-----------------
 InClk           | Input     | 1        | Write side clock    
 InRst           | Input     | 1        | Write side reset input (active high)   
 OutClk          | Input     | 1        | Read side clock
 OutRst          | Input     | 1        | Read side reset  input (active high)  
 InData          | Input     | Width\_g | Write data      
 InVld           | Input     | 1        | AXI-S  handshaking signal
 InRdy           | Output    | 1        | AXI-S  handshaking signal
 OutData         | Output    | Width\_g | Read data       
 OutVld          | Output    | 1        | AXI-S  handshaking signal          
 OutRdy          | Input     | 1        | AXI-S handshaking signal  
 InFull          | Output    | 1        | FIFO full signal synchronous to *InClk*     
 InEmpty         | Output    | 1        | FIFO empty signal synchronous to *InClk*    
 InAlmFull       | Output    | 1        | FIFO almost full signal synchronous to *InClk*, Only exists if *AlmFullOn\_g*  = true          
 InAlmEmpty      | Output    | 1        | FIFO almost empty signal synchronous to *InClk*, Only exists if   *AlmEmptyOn\_g* = true
 InLevel         | Output    | ceil(log2(Depth\_g))+1  | FIFO level synchronous to  *InClk*         
 OutFull         | Output    | 1        | FIFO full  signal  synchronous to *OutClk*   
 OutEmpty        | Output    | 1        | FIFO empty signal   synchronous to *OutClk*        
 OutAlmFull      | Output    | 1        | FIFO almost full signal synchronous to *OutClk* Only exists if *AlmFullOn\_g* = true          
 OutAlmEmpty     | Output    | 1        | FIFO almost   empty signal  synchronous to *OutClk*  Only exists if  *AlmEmptyOn\_g* = true          
 OutLevel        | Output    | ceil(log2(Depth\_g))+1 | FIFO level synchronous to   *OutClk*

### Architecture

The rough architecture of the FIFO is shown in the figure below. Note
that the figure does only depict the general architecture and not each
and every detail.

Read and write address counters are handled in their corresponding clock
domain. The current address counter value is then transferred to the
other clock-domain by converting it to gray code, synchronizing it using
a double-stage synchronizer and convert it back to a two's complement
number. This approach ensures that a correct value is received, even if
the clock edges are aligned in a way that causes metastability on the
first flip-flop. Because the data is transferred in gray code, in this
case either the correct value before an increment of the counter or the
correct value after the increment is received, so the result is always
correct.

All status information is calculated separately in both clock domains to
make it available synchronously to both clocks.

This architecture is independent of the FPGA technology used and can
also be used to combine more than just one Block-RAM into one big FIFO.

<p align="center">
<img width="700" height="300" src="async_fifo.png">
</p>

### Constraints

For the FIFO to work correctly, signals from one clock domain to the
other must be constrained to have not more delay that one clock cycle of
the faster clock.

Example with a 100 MHz clock (10.0 ns period) and a 33.33 MHz clock (30
ns period) for Vivado:

```tcl
set_max_delay --datapath_only --from <ClkA> -to <ClkB> 10.0
set_max_delay --datapath_only --from <ClkB> -to <ClkA> 10.0
```
***
[Index](../psi_common_index.md) **|** Previous: [Memories > tdp ram be](../ch3_memories/ch3_4_tdp_ram_be.md) **|** Next: [FIFO > tdp ram](../ch4_fifos/ch4_2_sync_fifo.md)
