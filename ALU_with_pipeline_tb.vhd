library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU_with_pipeline_tb is
end ALU_with_pipeline_tb;

architecture ALU_with_pipeline_tb_arch of ALU_with_pipeline_tb is

component ALU_with_pipeline is
    generic(
           VLMAX: integer :=32; -- Max Vector Length (max number of elements) 
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32 --number of bits in register
           );
    Port (  clk: in STD_LOGIC; 
            rst: in STD_LOGIC;
            busy: in STD_LOGIC;
            Xdata_1: in STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 1
            Xdata_2: in STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 2
            Vdata1_1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 1
            Vdata2_1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 1
            Vdata1_2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 2
            Vdata2_2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 2
            Idata_1: in STD_LOGIC_VECTOR(4 downto 0); --data coming from immediate field to Lane 1
            Idata_2: in STD_LOGIC_VECTOR(4 downto 0); --data coming from immediate field to Lane 2
            op2_src_1: in STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 for Lane 1
                                                -- 00 = vector reg
                                                -- 01 = scalar reg
                                                -- 10 = immediate
                                                -- 11 = RESERVED (unbound)
            op2_src_2: in STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 for Lane 2
            funct6_1: in STD_LOGIC_VECTOR(5 downto 0); --to know which operation
            funct6_2: in STD_LOGIC_VECTOR(5 downto 0); --to know which operation
            WriteEn_i_1: in STD_LOGIC; --WriteEn for Lane 1 from controller
            WriteEn_i_2: in STD_LOGIC; --WriteEn for Lane 2 from controller
            WriteEn_o_1: out STD_LOGIC; --WriteEn for Lane 1 out to Register File
            WriteEn_o_2: out STD_LOGIC; --WriteEn for Lane 2 out to Register File
            result_1: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 1
            result_2: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0) --result from Lane 2
            );
end component;

constant    VLMAX: integer :=32; -- Max Vector Length (max number of elements) 
constant    SEW_MAX: integer:=32;
constant    lgSEW_MAX: integer:=5;
constant    XLEN:integer:=32; --Register width
constant    VLEN:integer:=32; --number of bits in register

signal      clk: STD_LOGIC; 
signal      rst: STD_LOGIC;
signal      busy: STD_LOGIC;
signal      Xdata_1: STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 1
signal      Xdata_2: STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 2
signal      Vdata1_1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 1
signal      Vdata2_1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 1
signal      Vdata1_2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 2
signal      Vdata2_2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 2
signal      Idata_1: STD_LOGIC_VECTOR(4 downto 0); --data coming from immediate field to Lane 1
signal      Idata_2: STD_LOGIC_VECTOR(4 downto 0); --data coming from immediate field to Lane 2
signal      op2_src_1: STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 for Lane 1
signal      op2_src_2: STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 for Lane 2
signal      funct6_1: STD_LOGIC_VECTOR(5 downto 0); --to know which operation
signal      funct6_2: STD_LOGIC_VECTOR(5 downto 0); --to know which operation
signal      WriteEn_i_1: STD_LOGIC; --WriteEn for Lane 1 from controller
signal      WriteEn_i_2: STD_LOGIC; --WriteEn for Lane 2 from controller
signal      WriteEn_o_1: STD_LOGIC; --WriteEn for Lane 1 out to Register File
signal      WriteEn_o_2: STD_LOGIC; --WriteEn for Lane 2 out to Register File
signal      result_1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 1
signal      result_2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 2

begin
    DUT: ALU_with_pipeline generic map(VLMAX, SEW_MAX, lgSEW_MAX, XLEN, VLEN)
                           port map(clk,rst,busy,
                                    Xdata_1,Xdata_2,Vdata1_1,Vdata2_1,Vdata1_2,Vdata2_2,Idata_1,Idata_2,
                                    op2_src_1,op2_src_2,funct6_1,funct6_2,WriteEn_i_1,WriteEn_i_2,WriteEn_o_1,WriteEn_o_2,result_1, result_2);
                                    
    clk_proc: process begin
        clk<='0';
        wait for 5ns;
        clk<='1'; 
        wait for 5ns;
    end process;
    
    process begin
        rst<='1'; wait for 10ns; rst<= '0'; busy<='0'; Xdata_1<= x"00000006"; Xdata_2<= x"00000003"; Vdata1_1<= x"FFFFFFF5"; Vdata2_1<= x"FFFFFFF5"; Vdata1_2<= x"FFFFFFF3"; Vdata2_2<= x"FFFFFFF2";
        Idata_1<= "00011"; Idata_2<= "00111"; op2_src_1<= "00"; op2_src_2<= "00"; funct6_1<="000000"; funct6_2<="000000";  WriteEn_i_1<= '1'; WriteEn_i_2<= '1'; wait for 8ns;
        Vdata1_1<= x"00000003";  Vdata1_2<= x"00000008"; op2_src_1<= "01"; op2_src_2<= "10";
        
        wait; 
    end process;

end ALU_with_pipeline_tb_arch;
