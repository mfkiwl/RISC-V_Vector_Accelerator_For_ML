# RISCV_Vector_Unit

RISC-V implementation of a vector unit that will eventually be used to accelerate Machine Learning algorithms.

--------------------------------------------------------------------
--------------------      SPECIFICATIONS      ----------------------
--------------------------------------------------------------------
1. Controller
   - Decoder: decodes vector instruction into fields
   - Control Unit: outputs control signals to ALU, MEM units based on opcode,funct3 fields
   - Dispatcher: manages busy signals coming from ALU, MEM units
   
2. Register File
   - 2 Banks: 2 read + 1 write ports each
   
3. ALU Unit
   - 2 Lanes
   - Supports chaining
   
-Register File with 2 banks with 2 read ports and 1 write port each. 
-2 execution lanes with support for chaining.
