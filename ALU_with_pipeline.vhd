library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU_with_pipeline is
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
end ALU_with_pipeline;

architecture Behavioral of ALU_with_pipeline is
    
component ALU_unit is
    generic (
           SEW_MAX: integer:=32 --max element width
           );
    Port (  operand1_1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 1 op1
            operand2_1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 1 op2
            operand1_2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 2 op1
            operand2_2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 2 op2
            funct6_1: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation (Lane 1)
            funct6_2: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation (Lane 2)
            result1: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 1 result
            result2: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0) --Lane 2 result
            ); 
end component;

signal s_operand2_1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 1 op2 (output from mux)
signal s_operand2_2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 2 op2 (output from mux)

--outputs from pipeline register between RegFile and ALU
signal s_busy: STD_LOGIC;
signal s_Xdata_1: STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 1
signal s_Xdata_2: STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 2
signal s_Vdata1_1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 1
signal s_Vdata2_1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 1
signal s_Vdata1_2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 2
signal s_Vdata2_2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --data coming from vector register to Lane 2
signal s_Idata_1: STD_LOGIC_VECTOR(4 downto 0); --data coming from immediate field to Lane 1
signal s_Idata_2: STD_LOGIC_VECTOR(4 downto 0); --data coming from immediate field to Lane 2
signal s_op2_src_1: STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 for Lane 1
signal s_op2_src_2: STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 for Lane 2
signal s_funct6_1: STD_LOGIC_VECTOR(5 downto 0); --to know which operation
signal s_funct6_2: STD_LOGIC_VECTOR(5 downto 0); --to know which operation


signal s_WriteEn_i_1: STD_LOGIC; --WriteEn for Lane 1 from controller
signal s_WriteEn_i_2: STD_LOGIC; --WriteEn for Lane 2 from controller

--output from ALU to pipeline register between ALU and WB stage
signal s_result_1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 1
signal s_result_2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 2
    
begin

    pipeline_regs: process(clk, rst) 
    begin
        if(rst='1') then --reset outputs of pipeline registers
            s_busy<= '0';
            s_Xdata_1<=  (others=>'0');
            s_Xdata_2<=  (others=>'0');
            s_Vdata1_1<= (others=>'0');
            s_Vdata2_1<= (others=>'0');
            s_Vdata1_2<= (others=>'0');
            s_Vdata2_2<= (others=>'0');
            s_Idata_1<=  (others=>'0');
            s_Idata_2<=  (others=>'0');
            s_op2_src_1<=(others=>'0');
            s_op2_src_2<=(others=>'0');
            s_funct6_1<= (others=>'0');
            s_funct6_2<= (others=>'0');
            s_result_1<= (others=>'0');
            s_result_2<= (others=>'0');
        elsif(rising_edge(clk) and busy= '0' ) then 
            s_Xdata_1<=  Xdata_1;
            s_Xdata_2<=  Xdata_2;
            s_Vdata1_1<= Vdata1_1;
            s_Vdata2_1<= Vdata2_1;
            s_Vdata1_2<= Vdata1_2;
            s_Vdata2_2<= Vdata2_2;
            s_Idata_1<=  Idata_1; 
            s_Idata_2<=  Idata_2; 
            s_op2_src_1<=op2_src_1;
            s_op2_src_2<=op2_src_2;
            s_funct6_1<= funct6_1;
            s_funct6_2<= funct6_2;
            result_1<= s_result_1;
            result_2<= s_result_2;
        end if;          
    end process;
    
    ALU: ALU_unit generic map(SEW_MAX)
                  port map(s_Vdata1_1, s_operand2_1, s_Vdata1_2, s_operand2_2,s_funct6_1, s_funct6_2, s_result_1, s_result_2);
    
    with s_op2_src_1 select s_operand2_1 <=
	Vdata2_1      when "00",
	Xdata_1       when "01", --need to check XLEN (use resize)
	Idata_1       when "10", --need to sign-extend
	(others=>'0') when "11";
	
	with s_op2_src_2 select s_operand2_2 <=
	Vdata2_2      when "00",
	Xdata_2       when "01", --need to check XLEN
	Idata_2       when "10", --need to sign-extend
	(others=>'0') when "11";
    
end Behavioral;
