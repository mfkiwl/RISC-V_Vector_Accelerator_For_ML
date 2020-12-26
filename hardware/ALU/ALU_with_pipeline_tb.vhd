library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU_with_pipeline_tb is
end ALU_with_pipeline_tb;

architecture ALU_with_pipeline_tb_arch of ALU_with_pipeline_tb is

component ALU_with_pipeline is
    generic(
           NB_LANES: integer:=2; --Number of lanes            
           VLMAX: integer :=32; -- Max Vector Length (max number of elements) 
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32 --number of bits in register
           );
    Port (  clk: in STD_LOGIC; 
            rst: in STD_LOGIC;
            busy: in STD_LOGIC;
            mask_in: in STD_LOGIC;
            Xdata: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0); --data from scalar register
            Vdata: in STD_LOGIC_VECTOR(2*NB_LANES*SEW_MAX-1 downto 0); --data coming from Register File, 2 since we always have 2 operands
            Idata: in STD_LOGIC_VECTOR(NB_LANES*5-1 downto 0); --data coming from immediate field of size 5 bits
            op2_src: in STD_LOGIC_VECTOR(2*NB_LANES-1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 
                                                -- 00 = vector reg
                                                -- 01 = scalar reg
                                                -- 10 = immediate
                                                -- 11 = RESERVED (unbound)
            funct6: in STD_LOGIC_VECTOR(NB_LANES*6-1 downto 0); --to know which operation
            funct3: in STD_LOGIC_VECTOR (NB_LANES*3-1 downto 0); --to know which operation
            WriteEn_i: in STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn from controller
            WriteEn_o: out STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn out to Register File
            result: out STD_LOGIC_VECTOR(NB_LANES*SEW_MAX-1 downto 0) --result vector
            );
end component;
constant    NB_LANES: integer:=2; --Number of lanes  
constant    VLMAX: integer :=32; -- Max Vector Length (max number of elements) 
constant    SEW_MAX: integer:=32;
constant    lgSEW_MAX: integer:=5;
constant    XLEN:integer:=32; --Register width
constant    VLEN:integer:=32; --number of bits in register

signal      clk:  STD_LOGIC; 
signal      rst:  STD_LOGIC;
signal      busy:  STD_LOGIC;
signal      mask_in:  STD_LOGIC;
signal      Xdata:  STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0); --data from scalar register
signal      Vdata:  STD_LOGIC_VECTOR(2*NB_LANES*SEW_MAX-1 downto 0); --data coming from Register File, 2 since we always have 2 operands
signal      Idata:  STD_LOGIC_VECTOR(NB_LANES*5-1 downto 0); --data coming from immediate field of size 5 bits
signal      op2_src:  STD_LOGIC_VECTOR(2*NB_LANES-1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 
signal      funct6:  STD_LOGIC_VECTOR(NB_LANES*6-1 downto 0); --to know which operation
signal      funct3:  STD_LOGIC_VECTOR (NB_LANES*3-1 downto 0); --to know which operation
signal      WriteEn_i:  STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn from controller
signal      WriteEn_o:  STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn out to Register File
signal      result: STD_LOGIC_VECTOR(NB_LANES*SEW_MAX-1 downto 0); --result vector
begin
    DUT: ALU_with_pipeline generic map(NB_LANES,VLMAX, SEW_MAX, lgSEW_MAX, XLEN, VLEN)
                           port map(clk,rst,busy,mask_in,
                                    Xdata,Vdata,Idata,
                                    op2_src,funct6,funct3,WriteEn_i,WriteEn_o,result);
                                    
    clk_proc: process begin
        clk<='0';
        wait for 5ns;
        clk<='1'; 
        wait for 5ns;
    end process;
    
    process begin
        rst<='1'; wait for 10ns; rst<= '0'; busy<='0';
        funct3<="000000";
        Xdata<= x"0000000300000006";
        Vdata<= x"FFFFFFF2FFFFFFF3FFFFFFF5FFFFFFF5"; 
        Idata<= "0011100011"; 
        op2_src<= "0000";
        funct6<="000000000000";
        WriteEn_i<= "11"; wait for 8ns;
        Vdata<= x"FFFFFFF200000008FFFFFFF500000003";
        op2_src<= "1001"; wait for 8 ns;
        Vdata<= x"FFFFFFF200000007FFFFFFF500000006";
        op2_src<= "0000";
        Vdata<= x"FFFFFFF3000000070000000600000003"; 
        funct6<="010111000010";mask_in<='1';wait for 8ns;
        wait; 
    end process;

end ALU_with_pipeline_tb_arch;
