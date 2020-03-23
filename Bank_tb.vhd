----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.03.2020 17:46:35
-- Design Name: 
-- Module Name: Bank_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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

component Bank1 is

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
           busy: out STD_LOGIC;
           outA : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           outB : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           RegSelA : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSelB : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           WriteEn : in STD_LOGIC;
           WriteData : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0) 
           );
end component;

signal     clk : STD_LOGIC;
signal     newInst: STD_LOGIC;
signal     busy: STD_LOGIC;
signal     outA : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     outB : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     RegSelA : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal     RegSelB : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal     WriteEn : STD_LOGIC;
signal     WriteData : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     WriteDest : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal     sew: STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
signal     vl: STD_LOGIC_VECTOR(XLEN-1 downto 0); 

begin
    UUT: Bank1 GENERIC MAP(VLMAX, RegNum, SEW_MAX, lgSEW_MAX, XLEN, VLEN)
    PORT MAP(clk, newInst, busy, outA, outB, RegSelA, RegSelB, WriteEn, WriteData, WriteDest, sew, vl);
    
    clk_proc: process begin
        clk<='1';
        wait for 5ns;
        clk<='0'; 
        wait for 5ns;
    end process;
    
    process begin
        wait for 5ns; newInst<='1'; sew <= "01000"; vl <= x"00000004"; wait for 5ns;
        newInst <= '0'; WriteEn<='1'; WriteData<= x"00000004"; WriteDest<="00000"; RegSelA<="00000"; RegSelB<="00001";  wait for 10ns;
        WriteData<= x"00000005";  wait for 10ns;
        WriteData<= x"00000006"; wait for 10ns;
        WriteData<= x"00000007";  wait for 10ns;
        --WriteData<= x"00000008"; RegSelA<="00000";  wait for 20ns; 
        WriteEn<= '0'; newInst<= '1'; wait;
    end process;
end Behavioral;
