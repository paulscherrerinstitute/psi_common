## 2.17.0
* Added Features
  * Added *psi\_common\_tdm_par_fill* - update tdm par to cope with AXI
* Bugfixes
  * update static_pulse due to new egenric for ramp gene
  * solve issue in sync fifo - outvld no assign to 1 prior reset is release
## 2.16.0
* Added Features
  	* Added *psi\_common\_find\_min\_max* - find min and max value withn a dedicated time period
  	* Added *psi\_common\_min\_max\_mean* - quick statistics within a dedicated time period
  	* Added new generic for init value into *psi\_common\_ramp\_gene* 
* Bugfixes
  	* Add support for explicit "+" signs in front of number and/or exponent

## 2.15.0
* Added Features
  * Added *psi\_common\_spi\_master\_cfg* - SPI master with dynamically change of the data length to forward on bus 
  * Added *psi\_common\_ser\_par* - Generic serialize to parallel
  * Added *psi\_common\_par\_ser* - Generic parallel to serialize
* Bugfixes
  * Remove VHDL 2008 statements in *psi\_common\_par\_tdm\_cfg*
  * Correct *psi\_common\_trigger\_digital* in case of one bit only
  
## 2.14.0
*Added Features
  * Added *psi\_common\_ramp\_gene - Ramp generator 
  * Added *psi\_common\_pulse\_gene - Pulse generator
  * Added max min within an array & ratio computation to determine if integer in Math package
  
## 2.14.0
*Added Features
  * Added *psi\_common\_ramp\_gene - Ramp generator 
  * Added *psi\_common\_pulse\_gene - Pulse generator
  * Added max min within an array & ratio computation to determine if integer in Math package
  
## 2.13.0
*Added Features
  * Added *psi\_common\_trigger\_analog* - Generic Analog trigger 
  * Added *psi\_common\_trigger\_digital* - Generic Digital trigger
  * Added *psi\_common\_dyn\_sft* - Dynamic barrel shifter
  
## 2.12.0
*Added Features
  * Added *psi\_common\_axi\_slave\_ipif64* - AXI BUS interface 64 bits capable 
  * Added *psi\_common\_axilight\_slave\_ipif* - AXI LIGHT BUS interface 
  * Added string to real conversion function

## 2.11.0
* Added Features
	* Added *psi\_common\_psi\_common\_debouncer* - Configurable debounce component
	* Added InvertBitOrder function in *psi\_common\_logic\_pkg*
	* Added backpressure handling to *psi\_common\_tdm\_par* - **Warning** as port has changed
	* Added backpressure handling to *psi\_common\_par\_tdm* - **Warning** as port has changed
	* Added interactiveGhdl.tcl
* Documentation
	* MD file instead of docx

## 2.10.0
  * Added Features
    * Added *psi\_common\_psi\_common\_par\_tdm\_cfg* - // to TDM with configurable number of enabled channels

## 2.9.0
  * Added Features
    * Added *psi\_common\_psi\_common\_axi\_multi_pl_stage* - Axi Multi pipeline stage

## 2.8.0
  * Added Features
    * Added *psi\_common\_watchdog* - Watchdog with several settable parameters
    * Added *psi\_common\_tdm\_par\_cfg* - TDM to // with configurable number of enabled channels
    * Added *psi\_common\_dont\_optimize* - Allows creating virtual pins to check implementation

## 2.7.1
* Bugfixes
  * Made *psi\_common\_ping\_pong\_tdm\_burst\_tb* runnable in Vivado

## 2.7.0
* Added Features
  * Added *psi\_common\_ping\_pong* ping-pong buffer (also known as double buffer)
* Bugfixes
  * In *psi\_common\_pulse\_shaper* fixed hold-off handling for *HoldIn\_g=True*

## 2.6.4
* Bugfixes
  * Made simulations working for GHDL

## 2.6.3
* Added Features
  * None
* Bugfixes
  * In *psi\_common\_axi\_slave\_ipif*: fixed behavior when writing to memory address if memory is disabled

## 2.6.2
* Added Features
  * None
* Bugfixes
  * In *psi\_common\_i2c\_master*: replace ranged integers by unsigned numbers and added attribute because of Vivado synthesis error

## 2.6.1
* Added Features
  * None
* Bugfixes
  * In *psi\_common\_i2c\_master*: Pull CmdRdy low when bus is busy
  * In *psi\_common\_i2c\_master*: Make sure SDA is always high for at least half an SCL clock cycle

## 2.6.0
* Added Features
  * Added *psi\_common\_i2c\_master*: Multi-master capable I2C master
  * Added *psi\_common\_tdp\_ram\_be*: True dual port RAM with byte enables
* Bugfixes
  * Fixed bug in *psi\_common\_axi\_master\_simple* that led to errors in simulations (no problem in HW)
* Others
  * Changed AXI record names in *psi\_common\_axi\_pkg* to be clear for master and slave ports

## 2.5.1
* Added Features
  * None
* Bugfixes
  * Disable *psi_commonaxi_slave_ipif_tb* for vivado simulator because it uses constructs not supported by the Vivado simulator

## 2.5.0
* Added Features
  * Added functions to *psi\_common\_math\_pkg*: log2ceil() for real, isLog2()
  * Added dependency resolution script
  * Added *psi\_common\_axi\_slave\_ipif*: Full AXI slave interface for IP-Cores
* Bugfixes
  * Fixed modelsim call in continuous integration script

## 2.4.1
* Added Features
  * None
* Bugfixes
  * Update PDF Documentation
  * Made compatible with Vivado simulator

## 2.4.0
* Added Features
  * Added integer to std\_logic converstion to *psi\_common\_logic\_pkg*
  * Added Last handling to *psi\_common\_wconv\_...* entities
  * Added full AXI master (incl. unaligned transfers) *psi\_common\_axi\_master\_full*
* Bugfixes
  * Made All Testbenches compatible with GHDL

## 2.3.0
* Added Features
  * Added generator scripts for wrappers to ease usage of *psi\_common\_par\_tdm*, *psi\_common\_tdm\_par*, *psi\_common\_simple\_cc* and *psi\_common\_status\_cc*
  * Added *psi\_common\_axi\_master\_simple* (AXI-Master, supporting aligned transfers only)
* Bugfixes
  * None

## 2.2.0
* Added Features
  * Added generic to control Rdy-behavior during reset
* Bugfixes
  * None

## 2.1.0
* Added Features
  * Added psi\_common\_spi\_master
  * Added FrequencyVld signals to psi\_common\_clk\_meas
* Bugfixes
  * Fixed bug for psi\_common\_strobe\_divider Ratio\_g=1
* Documentation
  * Added power point presentation about the library

## 2.0.0
* First open-source version (older versions not kept in history)
* Added Features
  * Added psi\_common\_bit\_cc (double-stage synchronizer including all attributes required)
  * Support GHDL as simulator for regression tests
* Bugfixes
  * Arbitters (psi\_common\_arb\_priority and psi\_common\_arb\_round\_robin) are now also working for size=0
* Changes that are not reverse compatible
  * Syntax changes for consistency in the following entities
    * psi\_common\_strobe\_divider
    * psi\_common\_strobe\_generator
    * psi\_common\_tdm\_mux
  * Changed RAMs for implementing either read-before-write or write-before-read

## 1.11.1
* Added Features
  * None
* Bugfixes
  * psi\_common\_tdm\_mux did not work correctly if input Vld was not kept asserted during a whole TDM run (i.e. all samples of a TDM run had to arrive back-to-back for the mux to work)
  * psi\_common\_async\_fifo timing optimization (from 1.11.0) did not work for OutRdy asserted when a single input sample arrives

## 1.11.0
* Added Features
  * Added clock measurement logic (psi\_common\_clk\_meas)
  * Added pulse shaper (create fixed duration pulse with limited frequency) (psi\_common\_pulse\_shaper)
* Bugfixes
  * Fixed timing issue in psi\_common\_async\_fifo (Timing was often not met for fast clock speeds)
  * psi\_common\_multi\_pl\_stage now also supports the case of 0 pipeline stages

## 1.10.1

* Added Features
  * None
* Bugfixes
  * Fixed bug in simulation script that led to an error message with new PsiSim

## 1.10.0

* Added Features
  * Priority Arbieter (psi\_common\_arb\_priority)
  * Round Robin Arbiter (psi\_common\_arb\_round\_robin)
  * TDM Mux (psi\_common\_tdm\_mux)
* Bugfixes
  * None

## 1.9.0

* Added Features
  * Added parallel to TDM conversion (psi\_common\_par\_tdm)
  * Added TDM to parallel conversion (psi\_common\_tdm\_par)
* Bugfixes
  * None

## 1.8.0

* Added Features
  * Added psi\_common\_multi\_pl\_stage (multiple psi\_common\_pl\_stage in one entity)
  * The ready-path (Rdy-handling) can now optionally be disabled for the pipelilne stages
  * The implementation style of RAMs (block or distributed) is now accessible via Generic
* Changes
  * FIFOs are now using psi\_common\_sdp\_ram\_rbw (instead of psi\_common\_tdp\_ram\_rbw) to allow using distributed RAM for memory.
* Bugfixes
  * None

## 1.7.0

* Added Features
  * Added psi\_common\_wconv\_n2xn: width converter N->x*N
  * Added psi\_common\_wconv\_xn2n: width converter x*N->N
  * Added psi\_common\_sync\_cc\_n2xn: Clock crossing between synchronous clocks (from N MHz to x*N MHz)
  * Added psi\_common\_sync\_cc\_xn2n: Clock crossing between synchronous clocks (from xN MHz to N MHz)
  * Added psi\_common\_pl\_stage: Pipelinestage with handshaking (incl. Back-Pressure handling) that registers all signals in both directions (incl. handshaking signals)
* Bugfixes
 * None

## 1.6.0

* Added Features
  * Added more std\_logic\_vector array types to psi\_common\_array\_pkg
  * Added bool and string arrays to psi\_common\_array\_pkg
  * Added choose() for string and real to psi\_common\_math\_pkg
* Bugfixes
  * None

## 1.5.0

* Added Features
  * Added psi\_common\_strobe\_generator (configurable frequency pulse generator)
  * Added psi\_common\_strobe\_divider (divide pulse rate)
  * Added psi\_common\_delay (timing optimal delay using SRLs or BRAMs)
* Bugfixes
  * Added init values to two-process records in psi\_common\_fifo\_async to prevent Modelsim Warnings

## 1.4.0

* Added Features
  * Added single port RAM with byte enables
* Bugfixes
  * None

## 1.3.1

* Added Features
  * None
* Bugfixes
 * Added missing signals to reset in psi\_common\_async\_fifo.vhd

## 1.3.0

* Added Features
  * Added Tick Generator
* Bugfixes
  * None

## 1.2.0

* Added Features
  * Added choose function for integers
* Bugfixes
  * None

## V1.01

* Added Features
  * Added synchronous FIFO
  * Added separate package for logic functions
  * Added Gray <-> Binary conversions
  * Added asynchronous FIFO
* Bugfixes
  * Added correct attributes for all double-stage-synchronizers in clock crossings

## V1.00
* First release
