---
title: "Register File"
keywords: 
last_updated: 
tags: 
sidebar: riscv_vector_processor_design_sidebar
permalink: Register-File.html
folder: Register-File
---

### Description

The register file stores the vector registers in banks. Each bank is composed of 16 vector registers. The current design contains 2 banks, since our ALU unit has 2 lanes. More about that later.

### Implementation

Here are some details about our register file implementation:

- **Register mapping**: 1 bank contains the upper 16 registers, and the other
  contains the lower 16 registers
- **Implicit dispatcher**: We assigned each bank to a respective memory or ALU lane, meaning both operands should belong to the same lane (i.e. it is the compiler’s job to ensure that). However, writing can be to any bank, not necessarily the same as the corresponding lane.
- **Mask bit**: If the instruction is masked, the first bit of an element from vector v0 is read to see if this element is masked or not. This signal is driven to the other bank as well as to the output of the register file.
- **Counters**: We used the following counters to keep track of the elements read/written in the vector register: number of elements read, number of elements written, number of bits read, number of bits written.
- **newInst**: Is a control signal that signals the entry of a new instruction. It is used to reset the counters.
- **Read on rising edge, write on falling edge**: We found it to be more sensible than reading on the falling edge and writing on the rising edge, since the pipeline registers are clocked on the rising edge.
- **SEW-size transfer**: On every clock cycle, SEW bits are read and, if the result is ready, SEW bits are written. The elements read are sign extended.
- **Masked operations**: When the result is ready, we look at the mask bit: if it is 0, neglect the result and don’t write, else write. Note that this is a naïve implementation of masking; a more efficient one is to be implemented soon.

### Diagram

![Register File](C:\Users\Hade\Desktop\RISC-V-Documentation\Images\Register-File.png)