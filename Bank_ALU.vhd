library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity Bank_ALU is
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
           reset: in STD_LOGIC;
           out1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           RegSel1 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           RegSel2 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           WriteEn : in STD_LOGIC;
           WriteData : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           funct6: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation
           busy: out STD_LOGIC;
           cs: in STD_LOGIC;
           alu_res : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0)
           );
end Bank_ALU;

architecture Behavioral of Bank_ALU is
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
component Bank is

    generic (
           -- Max Vector Length
           VLMAX: integer :=32;
           -- log(Number of Vector Registers)
           RegNum: integer:= 5; 
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32
           );
    Port ( clk : in STD_LOGIC;
           newInst: in STD_LOGIC;
           out1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           RegSel1 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           RegSel2 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           WriteEn : in STD_LOGIC;
           WriteData : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0)
           );
end component;

signal     res: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
signal     op1:  STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
signal     op2:  STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
signal     WD:  STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
begin

WD<= res when cs='0' else WriteData when cs='1'; --mux to select writedata1
RF: Bank GENERIC MAP(VLMAX,RegNum,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
    PORT MAP(clk,newInst,op1,op2,RegSel1,RegSel2,WriteEn,WD,WriteDest,sew,vl,vstart);
    out1<=op1;out2<=op2;
    alu_res<=res;
ALU: ALU_lane generic map(SEW_MAX)
    port map(clk, reset, op1, op2, funct6, res, busy);

end Behavioral;
