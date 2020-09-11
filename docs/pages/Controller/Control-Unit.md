---
title: "Control Unit Design"
keywords: 
last_updated: 
tags: 
sidebar: riscv_vector_processor_design_sidebar
permalink: Control-Unit.html
folder: Controller
---

### Description

The controller takes the instruction fields from the decoder and outputs control signals according to the instruction type. It also contains Control and Status Registers (CSRs). Refer to Appendix A for a detailed description of each field.

### Implementation

Our controller code is split into 3 processes:

1. The first one implements reading and writing from/to the CSRs.
2.  The second is purely combinational and implements the control signals generation logic.
3. The third implements writing to `vl` (`vsetvl` and `vsetvli` instructions). Although `vl` is a CSR, we chose to implement the writing in a separate process since it is read-only and can only be modified through the `vsetvl` and `vsetvli` instructions.

Here are the control signals used :

-  **WriteEn**: Enables writing to register file
-  **SrcB**: Selects vector, scalar, or immediate as second operand
- **MemWrite**: Enables writing to memory
- **MemRead**: Enables reading from memory
- **WBSrc**: Selects if write back source is from ALU or MEM
- **mv**: Indicates if instruction is a move/merge instruction or not
- **extension**: Specifies if extension from memory is signed or unsigned
- **addrmode**: Specifies addressing mode (unit stride, strided, indexed)
- **memwidth**: Specifies number of bits per memory transfer



### Diagram

![Decoder-Diagram](C:\Users\Hade\Desktop\RISC-V-Documentation\Images\Controller.png)