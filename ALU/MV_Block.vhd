library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MV_Block is
    generic (
           SEW_MAX: integer:=32 --max element width
           );
    Port (  vs1_data: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- data from VS1 vector register
            vs2_data: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- data from VS2 vector register
            mask_in: in STD_LOGIC; --mask bit of ith element
            data_out: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0)
     );
end MV_Block;

architecture Behavioral of MV_Block is

begin
    process (vs1_data,vs2_data,mask_in)
    begin
            if (mask_in = '1') then -- decide on which data to write based on mask bit
                data_out<=vs1_data; -- write vs1 data if mask bit is 1
            else
                data_out<=vs2_data; -- write vs2 data if mask bit is 0
            end if;
      
    end process;

end Behavioral;
