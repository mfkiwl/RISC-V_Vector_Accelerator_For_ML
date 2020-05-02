library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MEM_Lane is
generic (
    SEW_MAX: integer:=32;
    lgSEW_MAX: integer:=5;
    XLEN:integer:=32; --Register width
    VLEN:integer:=32 --number of bits in register
);
Port (
    mask_bit: in STD_LOGIC;
    vm: in STD_LOGIC; --indicates if masked operation or not
    rs1: in STD_LOGIC_VECTOR(4 downto 0); -- contains base effective address
    rs2: in STD_LOGIC_VECTOR(4 downto 0); -- contains stride offset incase of strided operation
    vs2: in STD_LOGIC_VECTOR(4 downto 0); -- 
    mop: in STD_LOGIC_VECTOR(2 downto 0); -- addressing modes 
    --
    --
    --
    lumop: in STD_LOGIC_VECTOR(4 downto 0); --additional addressing field
    -- 00000: unit stride
    -- 01000: unit stride, whole registers
    -- 10000: unit stride fault only first
    sumop: in STD_LOGIC_VECTOR(4 downto 0);  --additional addressing field
    -- 00000: unit stride
    -- 01000: unit stride, whole registers
   width_in: in STD_LOGIC_VECTOR(2 downto 0 );
   -- 000: 8 bits/transfer
   -- 101: 16 bits/transfer
   -- 110: 32 bits/transfer
   -- 111: sew bits/transfer
   width_out: out STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0); -- to be used for memory bank
   sew: in STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0); -- determines width of memory transfer
   mem_address: out STD_LOGIC_VECTOR(XLEN-1 downto 0)
 );
end MEM_Lane;

architecture Behavioral of MEM_Lane is

begin

width_out<="01000" when width_in="000" else -- 8 bits
           "10000" when width_in="000" else -- 16 bits
                                            -- still missing 32 bit case
           sew     when width_in="111";

end Behavioral;
