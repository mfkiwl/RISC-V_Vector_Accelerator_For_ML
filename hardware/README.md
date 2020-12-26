# A Configurable RISC-V Vector Accelerator for Machine Learning

RISC-V implementation of a vector unit that will eventually be used to accelerate Machine Learning algorithms.
We plan on supporting special types such as bfloat16 and posits to accelerate these workloads.

--------------------------------------------------------------------
                                    SPECIFICATIONS      
--------------------------------------------------------------------
1. Controller
   - Decoder: decodes vector instruction into fields
   - Control Unit: outputs control signals to ALU, MEM units based on opcode,funct3 fields
   - Lane Specifier: logic that dispatches instructions to appropriate vector lanes. Currently, the lane is specified based on the MSB of the destination register, since our banks are split in half.
   
2. Register File
   - Offset Generator: generates correct read and write element offsets within a vector register.
   - 2 Banks of 16 registers each: split into upper and lower for simplicity. 2 read + 1 write ports each
   
3. ALU Unit
   - 2 Lanes
   - Will support chaining.
   
