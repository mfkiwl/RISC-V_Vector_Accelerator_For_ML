library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity MEM_Top_tb is
--  Port ( );
end MEM_Top_tb;

architecture Structural of MEM_Top_tb is

component MEM_Top is
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
end component;

constant    BRAM_SIZE:integer:=36000;
constant    SEW_MAX: integer:=32;
constant    lgSEW_MAX: integer:=5;
constant    XLEN:integer:=32; --Register width
constant    VLEN:integer:=32; --number of bits in register

signal   clk:  STD_LOGIC;
signal   newInst:  STD_LOGIC;
signal   mask_bit:  STD_LOGIC;
signal   vm:  STD_LOGIC; --indicates if masked operation or not
signal   addrmode:  STD_LOGIC_VECTOR(1 downto 0); -- 00 if unit stride    
                                              -- 01 if strided
                                              -- 10 if indexed (unordered in case of a store)
                                              -- 11 if indexed (ordered in case of a store)   
signal   width:  STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0); -- necessary for reading and writing properly 
signal   vl:  STD_LOGIC_VECTOR(XLEN-1 downto 0); -- used for counter      
signal   extension:  STD_LOGIC;                                  
signal   rs1_data_1:  STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains base effective address for lane 1
signal   rs1_data_2:  STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains base effective address for lane 2
signal   rs2_data_1:  STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains stride offset incase of strided operation for lane 1
signal   rs2_data_2:  STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains stride offset incase of strided operation for lane 2
signal   vs2_data_1:  STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- contains stride offset incase of indexed operation for lane 1
signal   vs2_data_2:  STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- contains stride offset incase of indexed operation for lane 2         
signal   lumop_1:  STD_LOGIC_VECTOR(4 downto 0); --additional addressing field
signal   lumop_2:  STD_LOGIC_VECTOR(4 downto 0); --additional addressing field
signal   sumop_1:  STD_LOGIC_VECTOR(4 downto 0);  --additional addressing field
signal   sumop_2:  STD_LOGIC_VECTOR(4 downto 0);  --additional addressing field
signal   MemRead_1:  STD_LOGIC; -- coming from controller to lane 1
signal   MemRead_2:  STD_LOGIC; -- coming from controller to lane 2
signal   MemWrite_1:  STD_LOGIC; -- coming from controller to lane 1
signal   MemWrite_2:  STD_LOGIC; -- coming from controller to lane 2
signal   ReadPort_1:  STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- SEW_MAX since worst case is having to transfer SEW_MAX bits
signal   ReadPort_2:  STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- SEW_MAX since worst case is having to transfer SEW_MAX bits   
signal   WritePort_1:  STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);  
signal   WritePort_2:  STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);

begin
    DUT: MEM_Top generic map(BRAM_SIZE,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
                 port map(clk,newInst,mask_bit,vm,addrmode,width,vl,extension,rs1_data_1,rs1_data_2,rs2_data_1,rs2_data_2,
                             vs2_data_1,vs2_data_2,lumop_1,lumop_2,sumop_1,sumop_2,MemRead_1,MemRead_2,
                             MemWrite_1,MemWrite_2,ReadPort_1,ReadPort_2,WritePort_1,WritePort_2);
    clk_proc: process begin
        clk<='0';
        wait for 5ns;
        clk<='1'; 
        wait for 5ns;
    end process;
    
    process begin 
    
    newInst<='0';
    mask_bit<='0';vm<='0';addrmode<="00";width<="01000";vl<=x"00000020"; extension<='0';
    rs1_data_1<=x"00000000";rs1_data_2<=x"00001000";
    rs2_data_1<=x"00000000";rs2_data_2<=x"00000000";
    vs2_data_1<=x"00000000";vs2_data_2<=x"00000000";
    WritePort_1<=x"113262F1";WritePort_2<=x"111D23E6";
    MemRead_1<='0';MemRead_2<='0';
    MemWrite_1<='1';MemWrite_2<='1';
    wait for 1ns;newInst<='1';
    wait for 2ns;newInst<='0';wait for 3 ns;
    wait for 10 ns;
    WritePort_1<=x"11326262";WritePort_2<=x"111D2323";  
    wait for 45ns;
    newInst<='1';
    MemRead_1<='1';MemRead_2<='1';
    MemWrite_1<='0';MemWrite_2<='0';
    wait for 3 ns;
    newInst<='0'; 
    wait for 2 ns;
    wait;   
    end process; 

end Structural;
