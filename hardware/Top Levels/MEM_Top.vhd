library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MEM_Top is
generic (
    BRAM_SIZE:integer:=36000;
    SEW_MAX: integer:=32;
    lgSEW_MAX: integer:=5;
    XLEN:integer:=32; --Register width
    VLEN:integer:=32 --number of bits in register
);
  Port (
    clk: in STD_LOGIC;
    newInst: in STD_LOGIC;
    mask_bit: in STD_LOGIC;
    vm: in STD_LOGIC; --indicates if masked operation or not
    addrmode: in STD_LOGIC_VECTOR(1 downto 0); -- 00 if unit stride    
                                               -- 01 if strided
                                               -- 10 if indexed (unordered in case of a store)
                                               -- 11 if indexed (ordered in case of a store)   
    width: in STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0); -- necessary for reading and writing properly 
    vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0); -- used for counter      
    extension: in STD_LOGIC;                                  
    rs1_data_1: in STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains base effective address for lane 1
    rs1_data_2: in STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains base effective address for lane 2
    rs2_data_1: in STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains stride offset incase of strided operation for lane 1
    rs2_data_2: in STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains stride offset incase of strided operation for lane 2
    vs2_data_1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- contains stride offset incase of indexed operation for lane 1
    vs2_data_2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- contains stride offset incase of indexed operation for lane 2         
    lumop_1: in STD_LOGIC_VECTOR(4 downto 0); --additional addressing field
    lumop_2: in STD_LOGIC_VECTOR(4 downto 0); --additional addressing field
    sumop_1: in STD_LOGIC_VECTOR(4 downto 0);  --additional addressing field
    sumop_2: in STD_LOGIC_VECTOR(4 downto 0);  --additional addressing field
    MemRead_1: in STD_LOGIC; -- coming from controller to lane 1
    MemRead_2: in STD_LOGIC; -- coming from controller to lane 2
    MemWrite_1: in STD_LOGIC; -- coming from controller to lane 1
    MemWrite_2: in STD_LOGIC; -- coming from controller to lane 2
    ReadPort_1: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- SEW_MAX since worst case is having to transfer SEW_MAX bits
    ReadPort_2: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- SEW_MAX since worst case is having to transfer SEW_MAX bits   
    WritePort_1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);  
    WritePort_2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0)   
  
  
   );
end MEM_Top;

architecture Behavioral of MEM_Top is

component MEM_Lane is
generic (
    SEW_MAX: integer:=32;
    lgSEW_MAX: integer:=5;
    XLEN:integer:=32; --Register width
    VLEN:integer:=32 --number of bits in register
);
Port (
    clk: in STD_LOGIC;
    newInst: in STD_LOGIC;
    mask_bit: in STD_LOGIC;
    vm: in STD_LOGIC; --indicates if masked operation or not
    addrmode: in STD_LOGIC_VECTOR(1 downto 0); -- 00 if unit stride    
                                               -- 01 if strided
                                               -- 10 if indexed (unordered in case of a store)
                                               -- 11 if indexed (ordered in case of a store)   
    width: in STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0); -- necessary for reading and writing properly 
    vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0); -- used for counter                                         
    rs1_data: in STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains base effective address
    rs2_data: in STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains stride offset incase of strided operation
    vs2_data: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --   
    lumop: in STD_LOGIC_VECTOR(4 downto 0); --additional addressing field
    -- 00000: unit stride
    -- 01000: unit stride, whole registers
    -- 10000: unit stride fault only first
    sumop: in STD_LOGIC_VECTOR(4 downto 0);  --additional addressing field
    -- 00000: unit stride
    -- 01000: unit stride, whole registers
    mem_address: out STD_LOGIC_VECTOR(XLEN-1 downto 0)
 );
end component;

component MEM_Bank is

generic (
    BRAM_SIZE:integer:=36000;
    SEW_MAX: integer:=32;
    lgSEW_MAX: integer:=5;
    XLEN:integer:=32; --Register width
    VLEN:integer:=32 --number of bits in register
);
  Port ( 
    clk: in STD_LOGIC;
    MemRead: in STD_LOGIC; -- coming from controller
    MemWrite: in STD_LOGIC; -- coming from controller
    MemAddr: in STD_LOGIC_VECTOR(9 downto 0);
    ReadPort: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- SEW_MAX since worst case is having to transfer SEW_MAX bits
    WritePort: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
    width: in STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0); -- necessary for reading and writing properly
    extension: in STD_LOGIC
  );
end component;


signal s_mem_address_1: STD_LOGIC_VECTOR(XLEN-1 downto 0); -- output from lane 1
signal s_mem_address_2: STD_LOGIC_VECTOR(XLEN-1 downto 0); -- output from lane 2
signal s_MemAddr_1:STD_LOGIC_VECTOR(9 downto 0); --input to bank 1
signal s_MemAddr_2:STD_LOGIC_VECTOR(9 downto 0); -- input to bank 2

begin

Bank1: MEM_Bank GENERIC MAP(BRAM_SIZE,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
                PORT MAP (clk,MemRead_1,MemWrite_1,s_MemAddr_1,ReadPort_1,WritePort_1,width,extension);

Bank2: MEM_Bank GENERIC MAP(BRAM_SIZE,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
                PORT MAP (clk,MemRead_2,MemWrite_2,s_MemAddr_2,ReadPort_2,WritePort_2,width,extension);

Lane1: MEM_Lane GENERIC MAP(SEW_MAX,lgSEW_MAX,XLEN,VLEN)
                PORT MAP(clk,newInst,mask_bit,vm,addrmode,width,vl,rs1_data_1,rs2_data_1,vs2_data_1,lumop_1,sumop_1,s_mem_address_1);
                
Lane2: MEM_Lane GENERIC MAP(SEW_MAX,lgSEW_MAX,XLEN,VLEN)
                PORT MAP(clk,newInst,mask_bit,vm,addrmode,width,vl,rs1_data_2,rs2_data_2,vs2_data_2,lumop_2,sumop_2,s_mem_address_2); 

s_MemAddr_1<=s_mem_address_1(9 downto 0);  
s_MemAddr_2<=s_mem_address_2(9 downto 0);                                          
end Behavioral;
