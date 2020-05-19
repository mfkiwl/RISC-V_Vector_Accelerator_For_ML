library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegFile_ALU is
    generic (
           -- Max Vector Length (max number of elements) 
           VLMAX: integer :=32;
           -- log(Number of Vector Registers)
           RegNum: integer:= 5; 
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32 --number of bits in register
           );
    Port(   clk: in STD_LOGIC; 
            rst: in STD_LOGIC;
            busy: in STD_LOGIC;
            Xdata_1: in STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 1
            Xdata_2: in STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 2
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
            funct3_1: in STD_LOGIC_VECTOR(2 downto 0); --to know which operation
            funct3_2: in STD_LOGIC_VECTOR(2 downto 0); --to know which operation
            WriteEn_i_1: in STD_LOGIC; --WriteEn for Lane 1 from controller
            WriteEn_i_2: in STD_LOGIC; --WriteEn for Lane 2 from controller
            result_1: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 1 (to remove)
            result_2: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 2 (to remove) 
            ------Register File
            sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
            vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
            vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
            newInst: in STD_LOGIC;
            op1_1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
            op2_1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
            op1_2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
            op2_2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
            RegSel1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            RegSel2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            RegSel3 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            RegSel4 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            WriteDest1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            WriteDest2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0)
);
end RegFile_ALU;

architecture Structural of RegFile_ALU is

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
            mask_in: in STD_LOGIC;
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
            funct3_1: in STD_LOGIC_VECTOR (2 downto 0); --to know which operation (Lane 1)
            funct3_2: in STD_LOGIC_VECTOR (2 downto 0); --to know which operation (Lane 2) 
            WriteEn_i_1: in STD_LOGIC; --WriteEn for Lane 1 from controller
            WriteEn_i_2: in STD_LOGIC; --WriteEn for Lane 2 from controller
            WriteEn_o_1: out STD_LOGIC; --WriteEn for Lane 1 out to Register File
            WriteEn_o_2: out STD_LOGIC; --WriteEn for Lane 2 out to Register File
            result_1: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 1
            result_2: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0) --result from Lane 2
            );
end component;

component RegisterFile is
    generic (
           -- Max Vector Length (max number of elements) 
           VLMAX: integer :=32;
           -- log(Number of Vector Registers)
           RegNum: integer:= 5; 
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32 --number of bits in register
           );
    Port ( clk : in STD_LOGIC;
           newInst: in STD_LOGIC;
           out1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out3 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out4 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           mask_bit: out STD_LOGIC;
           RegSel1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSel2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSel3 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSel4 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           WriteEn1 : in STD_LOGIC;
           WriteEn2 : in STD_LOGIC;
           WriteData1 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           WriteData2 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0));
end component;

signal     s_op1_1: STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     s_op2_1: STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     s_op1_2: STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     s_op2_2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
signal     s_result_1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
signal     s_result_2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
signal     s_WriteEn_1: STD_LOGIC; 
signal     s_WriteEn_2: STD_LOGIC;
signal     s_mask_bit: STD_LOGIC;
begin


RF: RegisterFile GENERIC MAP(VLMAX,RegNum,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
    PORT MAP(clk,newInst,s_op1_1,s_op2_1,s_op1_2,s_op2_2,s_mask_bit,RegSel1,RegSel2,RegSel3,RegSel4,s_WriteEn_1,s_WriteEn_2,s_result_1,WriteDest1,s_result_2,WriteDest2,sew,vl,vstart);
    
ALU: ALU_with_pipeline generic map(VLMAX, SEW_MAX, lgSEW_MAX, XLEN, VLEN)
                           port map(clk,rst,busy,s_mask_bit,
                                    Xdata_1,Xdata_2,s_op1_1,s_op2_1,s_op1_2,s_op2_2,Idata_1,Idata_2,
                                    op2_src_1,op2_src_2,funct6_1,funct6_2,funct3_1,funct3_2,WriteEn_i_1,WriteEn_i_2,s_WriteEn_1,s_WriteEn_2,s_result_1, s_result_2);

result_1<= s_result_1; result_2<= s_result_2; 
op1_1<= s_op1_1; op2_1<= s_op2_1; op1_2<= s_op1_2; op2_2<= s_op2_2;

 
end Structural;