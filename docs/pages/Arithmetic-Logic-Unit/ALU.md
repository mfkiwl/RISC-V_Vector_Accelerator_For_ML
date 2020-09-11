---
title: "Arithmetic-Logic Unit Design"
keywords: 
last_updated: 
tags: 
sidebar: riscv_vector_processor_design_sidebar
permalink: ALU.html
folder: Arithmetic-Logic-Unit
---

The ALU Unit is composed of two sets of ALU Lanes and MV Blocks.

### ALU Lane

#### Description

The ALU is the unit that performs all arithmetic and logical operations. It consists of lanes, where each lane is assigned a bank in the register file (e.g Bank 1 maps to Lane 1, Bank 2 to Lane 2). Refer to Appendix B for the list of supported ALU instructions.

#### Implementation

The ALU lane in itself is purely combinational; it performs the desired operation based on funct6 and funct3, where the operands are SEW MAX bits wide.

### Mv Block

#### Description

The MV block handles merge/move instructions. We chose to make a dedicated block for these 2 instructions because they require knowledge of the mask bits, unlike the regular ALU operations.

#### Implementation

The circuit is purely combinational, just like the ALU. The mask bit is examined and the operation is executed. The outputs of the ALU and MV blocks are multiplexed and selected by the controller, based on the funct6 field (which acts like an opcode for ALU instructions).

### Overall Diagram for the ALU Unit

![ALU-Unit](C:\Users\Hade\Desktop\RISC-V-Documentation\images\ALU-Unit.png)