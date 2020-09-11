---
title: "Address Computation Unit ('Memory Unit') Design"
keywords: 
last_updated: 
tags: 
sidebar: riscv_vector_processor_design_sidebar
permalink: Address-Computation-Unit.html
folder: Memory
---

### Description

The memory lane computes the 32-bit address based on the desired addressing mode, transfer size and some control signals. It is composed of lanes, similar to the ALU unit. Refer to Appendix B for the list of supported memory instructions.

### Implementation

Contrary to the ALU unit, the memory unit is clocked since it needs to increment and feed a new address to memory every clock cycle.

### Diagram

![Memory-Unit](../../images/Memory-Unit.png)