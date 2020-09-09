library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU_lane is
    generic (
           	SEW_MAX: integer:=32; --max element width
			lgSEW_MAX: integer:=5
           );
    Port (  
            operand1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
            operand2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
            funct6: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation
            funct3: in STD_LOGIC_VECTOR (2 downto 0); 
            result: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0) 
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
    process(funct6, funct3, operand1, operand2)
    variable tmp:std_logic_vector(2*SEW_MAX-1 downto 0);
    begin
        if(funct3 = "000" or funct3 = "011" or funct3="100") then
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
                when "001001" => --vand
                    result <= (operand1 and operand2);
                when "001010" => --vor
                    result <= (operand1 or operand2); 
                when "001011" => --vxor
                    result <= (operand1 xor operand2);
                --when "010111" => --vmerge/vmv
                    --result <= ;
                when "011000" => --vmseq (set mask register element if equal)
                    if (operand1 = operand2) then
                        result(SEW_MAX-1 downto 1)<= (others=>'0'); result(0)<= '1';
                    else
                        result<= (others=>'0');
                    end if;
                when "011001" => --vmsne (set mask register element if not equal)
                    if (operand1 /= operand2) then
                        result(SEW_MAX-1 downto 1)<= (others=>'0'); result(0)<= '1';
                    else
                        result<= (others=>'0');
                    end if;
                when "011010" => --vmsltu (set mask register element if operand1 < operand2 unsigned)
                    if (unsigned(operand1) < unsigned(operand2) ) then
                        result(SEW_MAX-1 downto 1)<= (others=>'0'); result(0)<= '1';
                    else
                        result<= (others=>'0');
                    end if;
                when "011011" => --vmsltu (set mask register element if operand1 < operand2 signed)
                    if (signed(operand1) < signed(operand2)) then
                        result(SEW_MAX-1 downto 1)<= (others=>'0'); result(0)<= '1';
                    else
                        result<= (others=>'0');
                    end if;
                when "011100" => --vmsleu (set mask register element if operand1 <= operand2 unsigned)
                    if (unsigned(operand1) <= unsigned(operand2)) then
                        result(SEW_MAX-1 downto 1)<= (others=>'0'); result(0)<= '1';
                    else
                        result<= (others=>'0');
                    end if;
                when "011101" => --vmsleu (set mask register element if operand1 <= operand2 signed)
                    if (signed(operand1) <= signed(operand2)) then
                        result(SEW_MAX-1 downto 1)<= (others=>'0'); result(0)<= '1';
                    else
                        result<= (others=>'0');
                    end if;
                when "011110" => --vmsgtu (set mask register element if operand1 > operand2 unsigned)
                    if (unsigned(operand1) > unsigned(operand2)) then
                        result(SEW_MAX-1 downto 1)<= (others=>'0'); result(0)<= '1';
                    else
                        result<= (others=>'0');
                    end if;
                when "011111" => --vmsgt (set mask register element if operand1 > operand2 signed)
                    if (signed(operand1) > signed(operand2)) then
                        result(SEW_MAX-1 downto 1)<= (others=>'0'); result(0)<= '1';
                    else
                        result<= (others=>'0');
                    end if;
                when "100101" => --vsll (shift left logical)
					result<= std_logic_vector(shift_left(unsigned(operand1), to_integer(unsigned(operand2(lgSEW_MAX-1 downto 0))) ));
				when "101000" => --vsrl (shift right logical (zero-extension) ) 
					result<= std_logic_vector(shift_right(unsigned(operand1),to_integer( unsigned(operand2(lgSEW_MAX-1 downto 0))) ));
				when "101001" => --vsra (shift right arithmetic (sign-extension) )
					result<= std_logic_vector(shift_right(signed(operand1),to_integer( unsigned(operand2(lgSEW_MAX-1 downto 0)) )));
                when others => result<= (others=>'0'); 
            end case;
        elsif(funct3 = "010" or funct3 = "110") then
            case funct6 is
                when "100000" => --vdivu (division unsigned)
                    result<= std_logic_vector(unsigned(operand1)/unsigned(operand2));
                when "100001" => --vdiv (division signed)
                    result<= std_logic_vector(signed(operand1)/signed(operand2));
                when "100010" => --vremu (remainder unsigned)
                    result<= std_logic_vector(unsigned(operand1) rem unsigned(operand2));
                when "100011" => --vrem (remainder signed)
                    result<= std_logic_vector(signed(operand1) rem signed(operand2));
                when "100100" => --vmulhu (multiplication unsigned, returning high bits of product)
                	tmp:= std_logic_vector(unsigned(operand1)*unsigned(operand2));
                	result<=tmp(2*SEW_MAX-1 downto SEW_MAX);
                when "100101" => --vmul (multiplication signed, returning low bits of product)
                	tmp:= std_logic_vector(signed(operand1)*signed(operand2));
                	result<=tmp(SEW_MAX-1 downto 0);	
--				when "100110" => --vmulhsu: Signed(vs2)-Unsigned multiply, returning high bits of product
--                	tmp:= std_logic_vector(unsigned(operand1)*unsigned(operand2));
--                	result<=tmp(2*SEW_MAX-1 downto SEW_MAX);	
				when "100111" => --vmulh: Signed multiply, returning high bits of product
                	tmp:= std_logic_vector(signed(operand1)*signed(operand2));
                	result<=tmp(2*SEW_MAX-1 downto SEW_MAX);
                when others => result<= (others=>'0'); 
            end case;
        end if;
    end process;

end ALU_lane_arch;
