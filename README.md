# General Information

## Maintainer
Oliver Bründler [oliver.bruendler@psi.ch]

## Authors
Oliver Bründler [oliver.bruendler@psi.ch]

## License
This library is published under [PSI HDL Library License](License.txt), which is [LGPL](LGPL2_1.txt) plus some additional exceptions to clarify the LGPL terms in the context of firmware development.

## Detailed Documentation
See [Documentation](doc/psi_common.pdf)

## Changelog
See [Changelog](Changelog.md)

## What belongs into this Library
This library contains general VHDL code that is not very application specific and can be reused easily. 
Code must be written with reuse in mind. All important settings must be implemented as Generics (e.g. port widths,
FIFO depths, etc,).

It is suggested to use one .vhd file per Package or Entity.

Examples for things that belong into this library:
* Clock-Crossings
* FIFOs
* Vendor Independent RAM implementations
* Packages that extend the language

## What does not belong into this Library

 * Any project specific code
 * Code that better fits into another library (e.g. signal processing code using psi_fix belongs into psi_fix)
 * Code that is not fully parametrizable

## Tagging Policy
Stable releases are tagged in the form *major*.*minor*.*bugfix*. 

* Whenever a change is not fully backward compatible, the *major* version number is incremented
* Whenever new features are added, the *minor* version number is incremented
* If only bugs are fixed (i.e. no functional changes are applied), the *bugfix* version is incremented
 
# Dependencies

The required folder structure looks as given below (folder names must be matched exactly). 

Alternatively the repository [psi\_fpga\_all](https://github.com/paulscherrerinstitute/psi_fpga_all) can be used. This repo contains all FPGA related repositories as submodules in the correct folder structure.
* TCL
  * [PsiSim](https://github.com/paulscherrerinstitute/PsiSim) 
* VHDL
  * [psi\_common](https://github.com/paulscherrerinstitute/psi_common)
  * [psi\_tb](https://github.com/paulscherrerinstitute/psi_tb)

# Simulations and Testbenches

For everything that is non-trivial, self-checking testbenches shall be provided to allow easy and safe reuse of 
the library elements.

A regression test script for Modelsim is present. New Testbenches must therefore be added to the configuration of the 
regression test script *sim/config.tcl*.

To run the regression test, execute the following command in modelsim from within the directory *sim*

```
source ./run.tcl
``` 


