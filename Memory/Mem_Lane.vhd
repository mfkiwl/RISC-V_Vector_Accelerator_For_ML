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
    clk: in STD_LOGIC;
    newInst: in STD_LOGIC;
    mask_bit: in STD_LOGIC;
    vm: in STD_LOGIC; --indicates if masked operation or not
    addrmode: in STD_LOGIC_VECTOR(1 downto 0); -- 00 if unit stride    
                                               -- 01 if strided
                                               -- 10 if indexed (unordered in case of a store)
                                               -- 11 if indexed (ordered in case of a store)   
    width: in STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0); -- necessary for reading and writing properly 
    vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0); -- used for counter                                         
    rs1_data: in STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains base effective address
    rs2_data: in STD_LOGIC_VECTOR(XLEN-1 downto 0); -- contains stride offset incase of strided operation
    vs2_data: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --   
    lumop: in STD_LOGIC_VECTOR(4 downto 0); --additional addressing field
    -- 00000: unit stride
    -- 01000: unit stride, whole registers
    -- 10000: unit stride fault only first
    sumop: in STD_LOGIC_VECTOR(4 downto 0);  --additional addressing field
    -- 00000: unit stride
    -- 01000: unit stride, whole registers
    mem_address: out STD_LOGIC_VECTOR(XLEN-1 downto 0)
 );
end MEM_Lane;

architecture Behavioral of MEM_Lane is
signal address: STD_LOGIC_VECTOR(XLEN-1 downto 0); -- stores the address reached so far
signal width_int:integer;
signal vl_int:integer;
begin
    vl_int<= to_integer(unsigned(vl));    
    width_int<= to_integer(unsigned(width));
    process (clk,addrmode,rs1_data,rs2_data,vs2_data)
        variable counter:integer:=0; -- counts the number of elements
    begin
    if rising_edge(clk) then
        if(newInst='1') then counter:=0; end if; --reset counter
        if(counter<vl_int) then
            if (counter=0) then
                address<=rs1_data;
            else
                case addrmode is
                    when "00"=>  address<=std_logic_vector(unsigned(address)+width_int/8);                                                   
                    when "01"=>  address<=std_logic_vector(unsigned(address)+unsigned(rs2_data));
                    when "10"=>  address<=std_logic_vector(unsigned(address)+unsigned(vs2_data)); 
                    when "11"=>  -- unordered is an optimization, won't be implemented now
                    when others => address<= (others=>'0');               
                end case;
            end if;
            counter:=counter+1;
        end if;
    end if;
    end process;
    mem_address<=address;         
end Behavioral;
