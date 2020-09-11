---
title: "Reference of Decoder Instruction Fields, CSRs, and Generics"
keywords: 
last_updated: 
tags: 
sidebar: riscv_vector_processor_design_sidebar
permalink: Appendix-A.html
folder: Appendices
---


### Decoder - Instruction fields

- **funct6**: used to differentiate between ALU instruction families (add, subtract, etc...).
- **funct3**: used to differentiate between ALU instruction families further.
- **opcode**: used to differentiate between instruction types (ALU, MEM, `vsetvl`).
- **bit31**: Most significant bit of the instruction; used for `vsetvl` and `vsetvli` instructions.
- **nf**: encodes the number of whole vector registers to transfer for the whole vector register load/store instructions.
- **mop**: memory addressing modes.
- **vm**: indicates if instruction is masked or not (1 if unmasked, 0 if masked).
- **vs1**: first vector operand.
- **vs2/rs2**: second vector operand/scalar register.
- **vd/vs3**: vector destination.

### Controller - Control and Status Registers
- **vstart**: specifies the index of the first element to be executed by an instruction.
- **vxsat**: fixed-point accrued saturation flag.
- **vxrm**: fixed-point rounding mode.
- **vl**: specifies the number of elements to be read/written from/to a vector register.
- **vtype**: contains the following fields:
  - **vill**: used to encode that a previous `vsetvli` instruction attempted to write an unsupported value to `vtype`.
  - **vediv**: used by EDIV extension.
  - **vlmul**: vector register group multiplier (LMUL) setting.
  - **vsew**: standard element width encoding.
- **vlenb**: number of elements in bytes (VLEN/8).



### Controller - Generics

- **ELEN**: maximum element width in bits.
- **XLEN**: scalar register length in bits. 
- **VLEN**: number of bits in register.
- **VLMAX**: maximum number of elements in a vector register.
- **SEW MAX**: standard element width in bits.
- **lgSEW MAX**: log of maximum standard element width.