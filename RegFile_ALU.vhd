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
    Port(  clk : in STD_LOGIC;
           reset: in STD_LOGIC;
           newInst: in STD_LOGIC;
           out1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out3 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out4 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
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
           vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           funct6: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation
           busy: out STD_LOGIC;
           ld_RF: in STD_LOGIC);
end RegFile_ALU;

architecture Structural of RegFile_ALU is

component ALU_lane is
    generic (
           SEW_MAX: integer:=32 --max element width
           );
    Port (  clk : in STD_LOGIC;
            reset: in STD_LOGIC;
            operand1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
            operand2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
            funct6: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation
            result: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
            busy: out STD_LOGIC      
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

signal     op1 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     op2 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     res: STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     WD1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);

begin

WD1<= res when ld_RF='0' else WriteData1 when ld_RF='1'; --mux to select writedata1

RF: RegisterFile GENERIC MAP(VLMAX,RegNum,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
    PORT MAP(clk,newInst,op1,op2,out3,out4,RegSel1,RegSel2,RegSel3,RegSel4,WriteEn1,WriteEn2,WD1,WriteDest1,WriteData2,WriteDest2,sew,vl,vstart);
    
ALU: ALU_lane generic map(SEW_MAX)
    port map(clk, reset, op1, op2, funct6, res, busy);
    
    out1<= op1; out2 <= op2;
    

end Structural;
