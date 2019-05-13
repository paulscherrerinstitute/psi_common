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