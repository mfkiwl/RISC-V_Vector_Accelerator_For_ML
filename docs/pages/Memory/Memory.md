---
title: "Memory Design"
keywords: 
last_updated: 
tags: 
sidebar: riscv_vector_processor_design_sidebar
permalink: Memory.html
folder: Memory
---

### Description

The memory is the address space where we store to/load from data. Similar to our register file, it is composed of banks. Each bank has 1 read and 1 write ports.

### Implementation

- **Size**: We decided to make each bank fit into 1 BRAM chip of our *Zynq* FPGA.
- **Transfer size**: The width of the transfer is determined by the controller. It could be 8, 16, 32 or SEW bits.
- **Addressing**: Although the address coming from the MEM lane is 32 bits, the bits above the 10th are used to select the bank, since the address space of each bank is 10 bits wide.

### Diagram

![Memory](C:\Users\Hade\Desktop\RISC-V-Documentation\images\Memory.png)