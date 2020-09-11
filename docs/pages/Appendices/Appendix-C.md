---
title: "Code Repository Structure"
keywords: 
last_updated: 
tags: 
sidebar: riscv_vector_processor_design_sidebar
permalink: Appendix-C.html
folder: Appendices
---

All our code is present on this [Github Repository](https://github.com/imadassir/RISC-V_Vector_Accelerator_For_ML).

- Decoder can be found [here](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/Controller/Decoder.vhd).
- Controller (called Control Unit in our code) can be found [here](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/Controller/Control_Unit.vhd).
- There is a top level Controller that groups the decoder and control unit. It can be found [here](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/Controller/Controller.vhd).
- The register file consists of two banks , [Bank1](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/Register%20File/Bank1.vhd) which is the lower bank and contains v0, the mask register, and [Bank](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/Register%20File/Bank.vhd). These banks are joined under instantiated in the [Register File](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/Register%20File/RegisterFile.vhd). 
- The ALU consists of 2 [lanes](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/ALU/ALU_lane.vhd) instantiated in 1 [ALU unit](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/ALU/ALU_unit.vhd). The ALU unit has pipeline registers before and after it, splitting the the read, execute and write-back stages. The structure with these pipeline registers can be found [here](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/ALU/ALU_with_pipeline.vhd).
- The Memory Unit consists of 2 [Memory Lanes](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/Memory/MEM_Lane.vhd), similarly to the ALU. The unit’s purpose is to compute the address to fetch from in memory. The memory itself is formed of [banks](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/Memory/MEM_Bank.vhd), similarly to the register file.
- To test things out, we joined the register file and ALU [here](https://github.com/imadassir/RISCV_Vector_Unit/blob/master/hardware/Top%20Levels/RegFile_ALU.vhd).