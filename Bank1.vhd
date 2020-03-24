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
           -- Max Vector Length (max number of elements) 
           VLMAX: integer :=32;
           -- log(Number of Vector Registers)
           RegNum: integer:= 5; 
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32 --number of bits in register
    
             );
    Port ( clk : in STD_LOGIC;
           newInst: in STD_LOGIC;
           busy: out STD_LOGIC;
           outA : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           outB : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           RegSelA : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSelB : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           WriteEn : in STD_LOGIC;
           WriteData : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0) 
           );
end Bank1;

architecture Bank1_arch of Bank1 is
    type registerFile is array(0 to (2**(RegNum)-1)) of std_logic_vector(VLEN-1 downto 0);   
    signal registers : registerFile;
    signal sew_int: integer;
    signal vl_int: integer;
    signal read_counter: integer range 0 to (VLEN-1):=0; -- first bit to read from
    signal write_counter: integer range 0 to (VLEN-1):=0; -- first bit to write to
    signal elements_read: integer range 0 to (VLMAX-1):=0; -- # of elements read so far
    signal elements_written: integer range 0 to (VLMAX-1):=0; -- # of elements written so far
begin
    sew_int<= to_integer(unsigned(sew)); --convert sew to integer for reading
    vl_int<= to_integer(unsigned(vl)); --convert vl to integer
    
    process(clk) is
    --variable sign_ext : std_logic_vector ( (VLEN-sew_int) downto 0) := (others=>'0');
    begin
          if rising_edge(clk) then 
              if(newInst = '1') then elements_read<=0; elements_written<=0; read_counter<=0; write_counter<=0; busy<='1'; end if; --new instruction from dispatcher, reset counters
              
              -- reading
              if(elements_read < vl_int) then
                --Bypass logic
                if ( RegSelA = WriteDest AND read_counter=write_counter) then
                    outA<=WriteData; --Bypass Data1 to read port A
                else
                    outA<= ( x"000000" & (registers(to_integer(unsigned(RegSelA))) ((read_counter+sew_int-1) downto read_counter) ));
                end if; 
                
                if ( RegSelB = WriteDest AND read_counter=write_counter) then
                    outB<=WriteData; --Bypass Data1 to read port B 
                else
                    outB<= ( x"000000" & (registers(to_integer(unsigned(RegSelB))) ((read_counter+sew_int-1) downto read_counter) ));                    
                end if;
                read_counter<= read_counter+sew_int;
                elements_read<= elements_read+1;
              end if;
              
              
              if WriteEn = '1' then
                --Write 
                if(elements_written < vl_int) then
                    registers(to_integer(unsigned(WriteDest)))((write_counter+sew_int-1) downto write_counter)<=WriteData(sew_int-1 downto 0);  
                    write_counter<= write_counter+sew_int;
                    elements_written<= elements_written+1;
                else --reached VL limit, so notify dispatcher that done.
                    busy<= '0';
                end if;
              end if;
              
           end if;
    end process;
end Bank1_arch;

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