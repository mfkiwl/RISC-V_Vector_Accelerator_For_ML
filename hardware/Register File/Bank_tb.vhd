library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Bank_tb is
--  Port ( );
end Bank_tb;

architecture Behavioral of Bank_tb is

constant        XLEN:integer:=32; --Register width
constant        VLEN:integer:=32;
constant        SEW_MAX:integer:=32;
constant        lgSEW_MAX: integer:=5;
constant        VLMAX: integer :=32;
constant        RegNum: integer:= 5;

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

signal     clk : STD_LOGIC;
signal     newInst: STD_LOGIC;
signal     out1 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     out2 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     RegSel1 : STD_LOGIC_VECTOR (RegNum-2 downto 0);
signal     RegSel2 : STD_LOGIC_VECTOR (RegNum-2 downto 0);
signal     WriteEn : STD_LOGIC;
signal     WriteData : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     WriteDest : STD_LOGIC_VECTOR (RegNum-2 downto 0);
signal     sew: STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
signal     vl: STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal     vstart: STD_LOGIC_VECTOR(XLEN-1 downto 0); 

begin
    UUT: Bank GENERIC MAP(VLMAX, RegNum, SEW_MAX, lgSEW_MAX, XLEN, VLEN)
    PORT MAP(clk, newInst, out1, out2, RegSel1, RegSel2, WriteEn, WriteData, WriteDest, sew, vl, vstart);
    
    clk_proc: process begin
        clk<='1';
        wait for 5ns;
        clk<='0'; 
        wait for 5ns;
    end process;
    
    process begin
        newInst<='0'; sew <= "01000"; vl <= x"00000004"; vstart <= x"00000000"; WriteEn<='1'; WriteData<= x"00000004"; WriteDest<="0000"; RegSel1<="0000"; RegSel2<="0001";
        wait for 10ns; newInst<='1'; wait for 5ns; newInst<= '0'; wait for 5ns;
        WriteData<= x"00000005";  wait for 10ns;
        WriteData<= x"00000006"; wait for 10ns;
        WriteData<= x"FFFFFFF7";  wait for 30ns;
        --WriteData<= x"00000008"; RegSelA<="00000";  wait for 20ns; 
        newInst<= '1'; WriteData<= x"00000008"; vstart <= x"00000001"; wait for 5ns; newInst<= '0'; wait for 5ns; 
        WriteData<= x"00000009";  wait for 10ns;
        WriteData<= x"0000000A"; wait for 10ns;
        WriteData<= x"0000000B";  wait for 10ns;
        wait;
    end process;
    
--    newInst<='0', '1' after 10ns, '0' after 15ns;
--    sew <= "01000"; vl <= x"00000004"; 
--    WriteEn<='1';  WriteDest<="00000";
--    RegSelA<="00000"; RegSelB<="00001";
--    WriteData<= x"00000004", x"00000005" after 20ns, x"00000006" after 30ns, x"00000007" after 40ns;
    
end Behavioral;
