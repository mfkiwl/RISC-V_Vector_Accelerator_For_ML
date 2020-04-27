library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegFile_tb is
--  Port ( );
end RegFile_tb;

architecture Behavioral of RegFile_tb is

constant        XLEN:integer:=32; --Register width
constant        ELEN:integer:=32; --Maximum element width
constant        VLEN:integer:=32;
constant        SEW_MAX:integer:=32;
constant        lgSEW_MAX:integer:=5;
constant        VLMAX: integer :=32;
constant        logVLMAX: integer := 5;
constant        RegNum: integer:= 5;

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

signal     clk : STD_LOGIC;
signal     newInst: STD_LOGIC;
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
signal     WriteData1 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     WriteDest1 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal     WriteData2 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     WriteDest2 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal     sew: STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
signal     vl: STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal     vstart: STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal     mask_bit: STD_LOGIC;

begin

    UUT: RegisterFile GENERIC MAP(VLMAX,RegNum,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
    PORT MAP(clk,newInst,out1,out2,out3,out4,mask_bit,RegSel1,RegSel2,RegSel3,RegSel4,WriteEn1,WriteEn2,WriteData1,WriteDest1,WriteData2,WriteDest2,sew,vl,vstart);

    clk_proc: process begin
        clk<='1';
        wait for 5ns;
        clk<='0'; 
        wait for 5ns;
    end process;
    
    process begin
        newInst<='0'; sew <= "01000"; vl <= x"00000004"; vstart <= x"00000000"; 
        WriteEn1<='1'; WriteData1<= x"00000004"; WriteDest1<="00000";
        WriteEn2<='1'; WriteData2<= x"00000008"; WriteDest2<="10000";
        RegSel1<="00000"; RegSel2<="00001"; RegSel3<= "10000"; RegSel4<= "10001";
        wait for 10ns; newInst<='1'; wait for 5ns; newInst<= '0'; wait for 5ns;
        WriteData1<= x"00000005"; WriteData2 <= x"00000009"; wait for 10ns;
        WriteData1<= x"00000006"; WriteData2 <= x"0000000A"; wait for 10ns;
        WriteData1<= x"00000007"; WriteData2 <= x"0000000B"; wait for 30ns;
        WriteEn1<= '0'; WriteEn2<= '0';
        newInst<='1'; wait for 5ns; newInst<= '0'; wait for 5ns;
        wait;
        
    end process;
    
end Behavioral;