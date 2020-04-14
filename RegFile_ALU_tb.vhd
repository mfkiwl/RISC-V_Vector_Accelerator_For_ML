library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegFile_ALU_tb is
end RegFile_ALU_tb;

architecture RegFile_ALU_tb_arch of RegFile_ALU_tb is

component RegFile_ALU is
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
end component;

constant        XLEN:integer:=32; --Register width
constant        ELEN:integer:=32; --Maximum element width
constant        VLEN:integer:=32;
constant        SEW_MAX:integer:=32;
constant        lgSEW_MAX:integer:=5;
constant        VLMAX: integer :=32;
constant        logVLMAX: integer := 5;
constant        RegNum: integer:= 5;

signal     clk : STD_LOGIC;
signal     newInst: STD_LOGIC;
signal     reset: STD_LOGIC;
signal     out1 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     out2 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     out3 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     out4 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     RegSel1 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal     RegSel2 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal     RegSel3 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal     RegSel4 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal     WriteEn1 : STD_LOGIC;
signal     WriteEn2 : STD_LOGIC;
signal     WriteData1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);   
signal     WriteDest1 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal     WriteData2 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     WriteDest2 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal     sew: STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
signal     vl: STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal     vstart: STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal     funct6: STD_LOGIC_VECTOR(5 downto 0);
signal     busy: STD_LOGIC;
signal     ld_RF: STD_LOGIC;

begin
    UUT: RegFile_ALU GENERIC MAP(VLMAX,RegNum,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
    PORT MAP(clk,newInst,reset,out1, out2, out3,out4,RegSel1,RegSel2,RegSel3,RegSel4,WriteEn1,WriteEn2,WriteData1,WriteDest1,WriteData2,WriteDest2,sew,vl,vstart,funct6, busy, ld_RF);
    
    clk_proc: process begin
        clk<='1';
        wait for 5ns;
        clk<='0'; 
        wait for 5ns;
    end process;
    
    process begin
        newInst<='0'; sew <= "01000"; vl <= x"00000004"; vstart <= x"00000000"; ld_RF<='1'; 
        WriteEn1<='1'; WriteData1<= x"00000004"; WriteDest1<="00000";
        RegSel1<="00000"; RegSel2<="00001";
        wait for 10ns; newInst<='1'; wait for 5ns; newInst<= '0'; wait for 5ns;
        WriteData1<= x"00000005"; wait for 10ns;
        WriteData1<= x"00000006"; wait for 10ns;
        WriteData1<= x"00000007"; wait for 30ns;
        newInst<='1'; WriteDest1<="00001"; wait for 5ns; newInst<= '0'; wait for 5ns;
        WriteData1<= x"00000004"; wait for 10ns;
        WriteData1<= x"00000005"; wait for 10ns;
        WriteData1<= x"00000006"; wait for 10ns;
        WriteData1<= x"00000007"; wait for 30ns;
        newInst<='1'; funct6<= "000000"; WriteDest1<="00010"; ld_RF<= '0'; wait for 5ns; newInst<= '0'; wait for 5ns;
        
        wait;
    end process;

end RegFile_ALU_tb_arch;
