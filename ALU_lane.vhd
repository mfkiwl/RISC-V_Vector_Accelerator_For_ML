library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU_lane is
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
end ALU_lane;

architecture ALU_lane_arch of ALU_lane is

function signed_minimum(X: in std_logic_vector; Y: in std_logic_vector) return std_logic_vector is
begin
    if (signed(X)>signed(Y)) then
        return Y;
    else return X;
    end if;
end signed_minimum;

function unsigned_minimum(X: in std_logic_vector; Y: in std_logic_vector) return std_logic_vector is
begin
    if (unsigned(X)>unsigned(Y)) then
        return Y;
    else return X;
    end if;
end unsigned_minimum;

function signed_maximum(X: in std_logic_vector; Y: in std_logic_vector) return std_logic_vector is
begin
    if (signed(X)<signed(Y)) then
        return Y;
    else return X;
    end if;
end signed_maximum;

function unsigned_maximum(X: in std_logic_vector; Y: in std_logic_vector) return std_logic_vector is
begin
    if (unsigned(X)<unsigned(Y)) then
        return Y;
    else return X;
    end if;
end unsigned_maximum;

begin
    process(funct6, operand1, operand2)
    begin
        case funct6 is
            when "000000" => --vadd
                result<= std_logic_vector(signed(operand1)+signed(operand2)); 
            when "000010" => --vsub
                result<= std_logic_vector(signed(operand2)-signed(operand1));
            when "000011" => --vrsub (reverse sub)
                result<= std_logic_vector(signed(operand1)-signed(operand2));
            when "000100" => --vminu (minimum unsigned)
                result <= unsigned_minimum(operand1, operand2);
            when "000101" => --vmin (minimum signed)
                result <= signed_minimum(operand1, operand2);
            when "000110" => --vmaxu (maximum unsigned)
                result <= unsigned_maximum(operand1, operand2);
            when "000111" => --vmin (maximum signed)
                result <= signed_maximum(operand1, operand2);
            when others => result<= (others=>'0');
        end case; 
        
    end process;

end ALU_lane_arch;
