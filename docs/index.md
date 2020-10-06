---
title: "Configurable RISC-V Vector Accelerator for Machine Learning Applications"
keywords:
tags:
permalink: index.html
sidebar: fyp_information_sidebar
summary:
---



*The following descriptions have been taken from the AUB FYP website, and have been written exclusively by Dr. Mazen Saghir*

---

This website contains all documentation related to our progress in our FYP with the topic *Configurable RISC-V Vector Accelerator for Machine Learning Applications*.

### FYP Team

- Advisor : **Dr. Mazen Saghir**
- Undergraduate Students
  - **Imad Assir (EECE)**, responsible of components related to Hardware, Computer Architecture and Digital Systems.
  - **Mohammad El Iskandarani (EECMP)**, responsible of Hardware and Software Optimization related to Machine learning.
  - **Hadi Rayan Al Sandid (ECMP)**, responsible of components related to Software Engineering.

### Design Project Description

"With increased reliance on artificial intelligence and machine learning there is a growing need for efficient computing platforms to support emerging applications at suitable levels of performance and energy efficiency. Vector processing is a computing style that exploits high levels of data parallelism, making it well suited for efficiently accelerating machine learning algorithms used in video, image, and audio processing applications.

The aim of this project is to design, implement, and evaluate a configurable RISC-V vector accelerator using a Xilinx FPGA device. The accelerator should communicate with a host processor using a suitable AXI4 interface. It should also be capable of transferring data between a vector register file and a DDR memory chip. Finally, the vector accelerator should be programmable in C using appropriate intrinsics. The latency and throughput of vectorized machine learning kernels will be measured using appropriate Xilinx Vivado tools and compared against non-vectorized software implementations."

- Applicable Standards : *RISC-V 'V' ISA; ARM AXI4*
- Contemporary Issues : *Machine learning hardware accelerators; vector architectures; RISC-V.*
- Resources and Engineering Tools : *Xilinx Vivado and SDK; RISC-V Toolchain*
- Required Courses : *EECE 420, EECE 421, EECE 423, EECE 430 and/or CMPS 274.*

### Expected Deliverables

1. A design-time configurable VHDL model of the vector accelerator.

2. A C cross-compiler that supports programming the accelerator using suitable intrinsics.

3. A functional hardware prototype implemented on a Xilinx FPGA and capable of executing vectorized machine learning kernels.

### Technical Constraints

1. The accelerator should be compliant with the RISC-V Vector ISA.

2. The accelerator should be programmable in C using appropriate intrinsics.

3. The hardware prototype should operate at a clock rate of 150 MHz or better.
