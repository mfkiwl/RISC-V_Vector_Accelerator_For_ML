----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/18/2020 10:41:49 AM
-- Design Name: 
-- Module Name: Bank1 - Behavioral
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
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- Each bank has 2 read ports and 2 write ports.
--Bypass is also implemented
entity Bank1 is

    generic (
           -- Max Vector Length
           VLMAX: integer :=32;
           -- log(Number of Vector Registers)
           RegNum: integer:= 5 
    
    
             );
    Port ( clk : in STD_LOGIC;
           outA : out STD_LOGIC_VECTOR (VLMAX-1 downto 0);
           outB : out STD_LOGIC_VECTOR (VLMAX-1 downto 0);
           RegSelA : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSelB : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           WriteEn : in STD_LOGIC;
           WriteData1 : in STD_LOGIC_VECTOR (VLMAX-1 downto 0);
           WriteData2 : in STD_LOGIC_VECTOR (VLMAX-1 downto 0);
           WriteDest1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           WriteDest2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0)
           );
end Bank1;

architecture Behavioral of Bank1 is
    type registerFile is array(0 to (2**(RegNum)-1)) of std_logic_vector(VLMAX-1 downto 0);   
    signal registers : registerFile;
begin
    process(clk) is
    begin
          if rising_edge(clk) then 
                --Read A and B
                outA<= registers(to_integer(unsigned(RegSelA)));
                outB<= registers(to_integer(unsigned(RegSelB)));
              if WriteEn = '1' then
                --Write
                registers(to_integer(unsigned(WriteDest1)))<=WriteData1;
                registers(to_integer(unsigned(WriteDest2)))<=WriteData2;       
               
                   --Bypass logic
                   if RegSelA = WriteDest1 then
                    outA<=WriteData1; --Bypass Data1 to read port A
                    
                   elsif RegSelA = WriteDest2 then
                    outA<=WriteData2; --Bypass Data2 to read port A
                    
                   elsif RegSelB = WriteDest1 then
                    outB<=WriteData1; --Bypass Data1 to read port B
                    
                   elsif RegSelB = WriteDest2 then
                    outB<=WriteData2; --Bypass Data2 to read port B 
                                     
                   end if;
               end if;
           end if;
    end process;
end Behavioral;
