library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU_unit is
    generic (
           SEW_MAX: integer:=32; --max element width
           lgSEW_MAX: integer:=5
           );
    Port (  operand1_1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 1 op1
            operand2_1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 1 op2
            operand1_2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 2 op1
            operand2_2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 2 op2
            funct6_1: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation (Lane 1)
            funct6_2: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation (Lane 2)
            funct3_1: in STD_LOGIC_VECTOR (2 downto 0);
            funct3_2: in STD_LOGIC_VECTOR (2 downto 0);
            result1: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --Lane 1 result
            result2: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0) --Lane 2 result
            ); 
end ALU_unit;

architecture ALU_unit_arch of ALU_unit is

component ALU_lane is
    generic (
           SEW_MAX: integer:=32 --max element width
           );
    Port (  operand1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
            operand2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
            funct6: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation
            funct3: in STD_LOGIC_VECTOR (2 downto 0);
            result: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0) 
            );
end component;

begin
ALU1: ALU_lane generic map(SEW_MAX)
               port map(operand1_1, operand2_1, funct6_1, funct3_1, result1);

ALU2: ALU_lane generic map(SEW_MAX)
               port map(operand1_2, operand2_2, funct6_2, funct3_2, result2);

end ALU_unit_arch;
