---
title: "Instructions Supported by current Design"
keywords: 
last_updated: 
tags: 
sidebar: riscv_vector_processor_design_sidebar
permalink: Appendix-B.html
folder: Appendices
---

Since the project is still in its early stages, only part of the RISC-V instruction set was implemented. These instructions are listed below, with a quick description. Please refer to the spec sheet for more details. Note that `.vv` stands for *vector-vector instructions*, `.vx` *vector-scalar instruc-*
*tions*, and `.vi` *vector-immediate instructions*.

### 7.4 - Vector Unit-Stride Instructions
- `vlw.v`: vector load word signed

- `vlwu.v`: vector load word unsigned
- `vle.v`: vector load element
- `vsw.v`: vector store word
- `vse.v`: vector store element

### 7.5 - Vector Strided Instructions

- `vlsw.v`: vector load word strided signed
- `vlswu`: vector load word strided unsigned
- `vlse.v`: vector load element strided
- `vssw.v`: vector store word strided
- `vsse.v`: vector store element strided

### 7.6 - Vector Indexed Instructions
- `vlxw.v`: vector load word indexed signed
- `vlxwu.v`: vector load word indexed unsigned
- `vlxe.v`: vector load element indexed
- `vsxw.v`: vector store word indexed
- `vsxe.v`: vector store element indexed
- `vsuxw.v`: vector store word unsigned indexed
- `vsuxe.v`: vector store element unsigned indexed

### 12.1 - Vector Single-Width Integer Add and Subtract
- `vadd.vv`: element-wise vector addition
- `vadd.vx`
- `vadd.vi`
- `vsub.vv`: element-wise vector subtraction (vs2[i]-vs1[i])
- `vsub.vx`
- `vrsub.vx` : element-wise vector reverse subtraction (vs1[i]-vs2[i])
- `vrsub.vi`

### 12.4 - Vector Bitwise Logical Instructions
- `vand.vv`: element-wise vector AND
- `vand.vx`
- `vand.vi`
- `vor.vv`: element-wise vector OR
- `vor.vx`
- `vor.vi`
- `vxor.vv`: element-wise vector XOR
- `vxor.vx`
- `vxor.vi`

### 12.5 - Vector Single-Width Bit Shift Instructions
- `vsll.vv`: shift left logical
- `vsll.vx`
- `vsll.vi`
- `vsrl.vv`: shift right logical (zero-extended)
- `vsrl.vx`
- `vsrl.vi`
- `vsra.vv`: shift right arithmetic (sign-extended)
- `vsra.vx`
- `vsra.vi`

### 12.7 - Vector Integer Comparison Instructions
- `vmseq.vv`: vd[i]= vs2[i]==vs1[i]
- `vmseq.vx`:
- `vmseq.vi`
- `vmsne.vv`: vd[i]= vs2[i] != vs1[i]
- `vmsne.vx`
- `vmsne.vi`
- `vmsltu.vv`: vd[i]= vs2[i] < vs1[i] unsigned
- `vmsltu.vx`
- `vmslt.vv`: vd[i]= vs2[i] < vs1[i] signed
- `vmslt.vx`
- `vmsleu.vv`: vd[i]= vs2[i] <= vs1[i] unsigned
- `vmsleu.vx`
- `vmsleu.vi`
- `vmsle.vv`: vd[i]= vs2[i] <= vs1[i] signed
- `vmsle.vx`
- `vmsle.vi`
- `vmsgtu.vx`: vd[i]= vs2[i] > vs1[i] unsigned
- `vmsgtu.vi`
- `vmsgt.vx`: vd[i]= vs2[i] > vs1[i] signed
- `vmsgt.vi`

### 12.8 - Vector Integer Min/Max Instructions
- `vminu.vv`: element-wise minimum unsigned: vd[i]= min(vs2[i],vs1[i])
- `vminu.vx`
- `vmin.vv`: element-wise minimum signed: vd[i]= min(vs2[i],vs1[i])
- `vmin.vx`
- `vmaxu.vv`: element-wise maximum unsigned: vd[i]= max(vs2[i],vs1[i])
- `vmaxu.vx`
- `vmax.vv`: element-wise maximum signed: vd[i]= max(vs2[i],vs1[i])
- `vmax.vx`

### 12.9 - Vector Single-Width Integer Multiply Instructions

**Note :** These instructions return the same number of bits as the operands (i.e. SEW)

- `vmul.vv`: returns lower SEW bits of element-wise multiply signed
- `vmul.vx`
- `vmulh.vv`: returns higher SEW bits of element-wise multiply signed
- `vmulh.vx`
- `vmulhu.vv`: returns higher SEW bits of element-wise multiply unsigned
- `vmulhu.vx`
- `vmulhsu.vv`: returns higher SEW bits of element-wise multiply signed-unsigned
- `vmulhsu.vx`

### 12.10 - Vector Integer Divide Instructions
- `vdivu.vv`: vd[i]= vs2[i]/vs1[i] unsigned
- `vdivu.vx`
- `vdiv.vv`: vd[i]= vs2[i]/vs1[i] signed
- `vdiv.vx`
- `vremu.vv`: vd[i]= vs2[i] rem vs1[i] unsigned
- `vremu.vx`
- `vrem.vv`: vd[i]= vs2[i] rem vs1[i] signed
- `vrem.vx`

### 12.15 - Vector Integer Merge Instructions
- `vmerge.vvm`: vd[i] = v0[i].LSB ? vs1[i] : vs2[i]
- `vmerge.vxm`
- `vmerge.vim`

### 12.6 - Vector Integer Move Instructions
- `vmv.v.v`
- `vmv.v.x`
- `vmv.v.i`