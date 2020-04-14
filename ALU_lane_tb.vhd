library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

entity ALU_lane_tb is
end ALU_lane_tb;

architecture ALU_lane_tb_arch of ALU_lane_tb is

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

constant SEW_MAX: integer:=32; --max element width in bits

signal clk : STD_LOGIC;
signal reset: STD_LOGIC;
signal operand1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
signal operand2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
signal funct6: STD_LOGIC_VECTOR (5 downto 0); --to know which operation
signal result: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
signal busy: STD_LOGIC; 

begin
    UUT: ALU_lane generic map(SEW_MAX)
    port map(clk, reset, operand1, operand2, funct6, result, busy);
    
--    clk_proc: process begin
--        clk<='1';
--        wait for 5ns;
--        clk<='0'; 
--        wait for 5ns;
--    end process;
    
    process begin
        reset <= '0'; operand1<= x"00000002"; operand2 <= x"00000003"; funct6 <= "000000"; wait for 10ns; --testing add
        operand1<=x"FFFFFFFE"; operand2<= x"FFFFFFFD"; wait for 10ns; --testing add with negative numbers
        funct6<= "000010"; operand1<=x"FFFFFFFE"; operand2<= x"FFFFFFFD"; wait for 10ns; --signed subtract
        funct6<= "000011"; operand1<=x"FFFFFFFE"; operand2<= x"FFFFFFFD"; wait for 10ns; --signed reverse subtract
        funct6<= "000100"; operand1<=x"00000005"; operand2<= x"00000008"; wait for 10ns; --unsigned min
        funct6<= "000101"; operand1<=x"FFFFFFFE"; operand2<= x"FFFFFFFD"; wait for 10ns; --signed min
        funct6<= "000110"; operand1<=x"00000005"; operand2<= x"00000008"; wait for 10ns; --unsigned max
        funct6<= "000111"; operand1<=x"FFFFFFFE"; operand2<= x"FFFFFFFD"; wait for 10ns; --signed max
        wait; 
    end process;

end ALU_lane_tb_arch;
