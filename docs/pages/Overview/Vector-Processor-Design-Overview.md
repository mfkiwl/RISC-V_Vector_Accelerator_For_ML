---
title: "Vector Processor Design"
keywords: 
last_updated: 
tags: 
sidebar: riscv_vector_processor_design_sidebar
permalink: Vector-Processor-Design-Overview.html
folder: Overview
---

This RISC-V Vector Unit Implementation has been realized in the scope of EECE-499, during the Spring 2018-2019 semester. It has been developed by team members Imad Assir and Mohammad El-Iskandarini, and supervised by Dr. Mazen Saghir.

The EECE-499 final report can be downloaded [here](../pdf/RISCV_Vector_ALU_report.pdf).

### Introduction

Field Programmable Gate Arrays (FPGA) have been in the hardware scene for quite some time now. Their programmable fabric allows the creation of highly parallelizable and modular applications with respectable efficiency. This trait made it the perfect platform for our RISC-V Vector Processor Unit design.

Vector processors are processing units that operate on one dimensional arrays called vectors. Instead of an instruction targeting a single scalar register, a vector instruction targets a vector register composed of several elements. Another key feature are the lanes that operate in parallel, thus boosting throughput and making them optimal for number crunching applications, such as machine learning algorithms.

### Design :

We have designed the foundations of a RISC-V vector processor (i.e. a decoder, controller, register file, Arithmetic-Logic Unit (ALU), and memory). The processor consists of 3 pipeline stages (for simplicity): Decode (Control signals generation and Register File access), Execute (ALU and memory) and Write-Back. The processor supports chaining between ALU lanes themselves, and between memory and ALU. This technique aims to reduce computational speed by taking the result directly from the generating unit, thus skipping additional register file accesses and avoiding Read-After-Write (RAW) hazards. To be able to implement chaining, we chose to have 2 execution lanes (for both ALU and memory). This also implies having 2 register banks to be able to service the lanes efficiently.



Our implementation was based on the [RISC-V Vector Extension Spec v0.8](https://github.com/riscv/riscv-v-spec/releases/tag/0.8).