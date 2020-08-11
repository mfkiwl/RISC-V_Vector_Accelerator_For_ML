library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MEM_Bank is

generic (BRAM_SIZE:integer:=36000;
         SEW_MAX: integer:=32;
         lgSEW_MAX: integer:=5;
         XLEN:integer:=32; --Register width
         VLEN:integer:=32 --number of bits in register
);
  Port ( clk: in STD_LOGIC;
         MemRead: in STD_LOGIC; -- coming from controller
         MemWrite: in STD_LOGIC; -- coming from controller
         MemAddr: in STD_LOGIC_VECTOR(9 downto 0);
         ReadPort: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- SEW_MAX since worst case is having to transfer SEW_MAX bits
         WritePort: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
         width: in STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0); -- necessary for reading and writing properly
         extension: in STD_LOGIC
  );
end MEM_Bank;

architecture Behavioral of MEM_Bank is
   -- 1 BRAM is 36Kb = 36,000 bits.
   -- 36,000 / 32  = 1,125
   -- This will be made to a generic but I'm just testing things out.
   type Mem is array(0 to 1024) of std_logic_vector(SEW_MAX-1 downto 0);   
   signal data : Mem;
   signal width_int:integer;
begin
    width_int<= to_integer(unsigned(width));
    process(clk, MemAddr,MemRead,MemWrite,data)
    begin
        if rising_edge(clk) then
            if (MemWrite = '1') then
            -- How to map between 32 bit address and the array?
            data(to_integer(unsigned(MemAddr)))(width_int-1 downto 0)<=WritePort(width_int-1 downto 0); 
            end if; 
            if (MemRead = '1') then
                if (extension='1') then -- sign extend
                ReadPort<= std_logic_vector(resize( signed((data(to_integer(unsigned(MemAddr))) ((width_int-1) downto 0)) ), ReadPort'length));
                else -- zero extend
                ReadPort<= std_logic_vector(resize( unsigned((data(to_integer(unsigned(MemAddr))) ((width_int-1) downto 0)) ), ReadPort'length));                
                end if;       
            end if;
        end if;
    end process;

end Behavioral;
