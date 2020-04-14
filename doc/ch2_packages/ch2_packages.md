<img align="right" src="../psi_logo.png">

***


# 2	Packages

## 2.1	psi_common_array_pkg

This package defines various array types that are not defined by VHDL natively. Some of these definitions are no more required in VHDL 2008 but since VHDL 2008 is not yet fully synthesizable, the package is kept.

## 2.2	psi_common_logic_pkg

This package contains various logic functions (e.g. combinatorial conversions) that can be synthesized.

## 2.3	psi_common_axi_pkg

This package contains record definitions to allow representing a complete AXI interface including all ports by only two records (one in each direction). This helps improving the readability of entities with AXI interfaces.

## 2.4	psi_common_math_pkg

This package contains various mathematical functions (e.g. log2). The functions are meant for calculating compile-time constants (i.e. constans, port-widths, etc.). They can potentially be synthesized as combinatorial functions but this is neither guaranteed nor will it lead to optimal results.

[Index](../psi_common_index.md) **|** Previous: [Introduction](../ch1_introduction/ch1_introduction.md)  **|** Next: [Memories > sdp ram](../ch3_memories/ch3_1_sdp_ram.md)
