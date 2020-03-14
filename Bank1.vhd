library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Each bank has 2 read ports and 2 write ports.
--Bypass is also implemented
entity Bank1 is

    generic (
           -- Max Vector Length
           VLMAX: integer :=32;
           -- log(Number of Vector Registers)
           RegNum: integer:= 5; 
           SEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32
    
             );
    Port ( clk : in STD_LOGIC;
           busy: in STD_LOGIC;
           WriteEn : in STD_LOGIC;                        -- Write Enable signal
           sew: in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); -- standard element width in bits
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0) ;     -- vector length in bits
          ------------------------------------------------------
          -- Read Outputs
           outA : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           outB : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
          ------------------------------------------------------
          -- Registers to read from
           RegSelA : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSelB : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
          ------------------------------------------------------
          -- Registers to write to
           WriteDest1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           WriteDest2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           ------------------------------------------------------
          -- Data to write
           WriteData1 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteData2 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0)
           );
end Bank1;

architecture Behavioral of Bank1 is
    ------------------------------------------------------
    -- Instantiate Register file 
    type registerFile is array(0 to (2**(RegNum)-1)) of std_logic_vector(VLMAX-1 downto 0);   
    signal registers : registerFile;
    signal sew_int: integer;
    ------------------------------------------------------
    -- Counters
    signal read_counter: integer range 0 to (VLMAX-1):=0; 
    signal write_counter: integer range 0 to (VLMAX-1):=0;
begin
    sew_int<= to_integer(unsigned(sew)); --convert sew to integer for reading
    process(clk) is
    begin
          if(busy='0') then read_counter<=0; write_counter<=0; end if; --Upon new instruction, reset counters
          if rising_edge(clk) then 
              if WriteEn = '1' then
                --Write
                registers(to_integer(unsigned(WriteDest1)))((write_counter+sew_int-1) downto write_counter)<=WriteData1;
                registers(to_integer(unsigned(WriteDest2)))((write_counter+sew_int-1) downto write_counter)<=WriteData2;       
               
--                   --Bypass logic
--                   if RegSelA = WriteDest1 then
--                    outA<=WriteData1; --Bypass Data1 to read port A
                    
--                   elsif RegSelA = WriteDest2 then
--                    outA<=WriteData2; --Bypass Data2 to read port A
                    
--                   elsif RegSelB = WriteDest1 then
--                    outB<=WriteData1; --Bypass Data1 to read port B
                    
--                   elsif RegSelB = WriteDest2 then
--                    outB<=WriteData2; --Bypass Data2 to read port B 
                                     
--                   end if;
              end if;
              --Read A and B
              outA<= registers(to_integer(unsigned(RegSelA))) ((read_counter+sew_int-1) downto read_counter);
              outB<= registers(to_integer(unsigned(RegSelB))) ((read_counter+sew_int-1) downto read_counter);
              
              --increment counters
              read_counter<= read_counter+1;
              write_counter<= write_counter+1;
           end if;
    end process;
end Behavioral;
