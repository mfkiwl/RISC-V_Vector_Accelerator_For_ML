library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Chaining_controller is
    Port ( clk : in STD_LOGIC;
           vd_1 : in STD_LOGIC_VECTOR (4 downto 0);
           vd_2 : in STD_LOGIC_VECTOR (4 downto 0);
           vs1_1 : in STD_LOGIC_VECTOR (4 downto 0);
           vs1_2 : in STD_LOGIC_VECTOR (4 downto 0);
           vs2_1 : in STD_LOGIC_VECTOR (4 downto 0);
           vs2_2 : in STD_LOGIC_VECTOR (4 downto 0);
           newInst_1 : in STD_LOGIC; --used to reset age counters 
           newInst_2 : in STD_LOGIC;
           chain_ALU_1 : out STD_LOGIC_VECTOR(1 downto 0); --mux select for ALU Lane 1 source: 00: from regfile. 01 from ALU Lane 2. 10 from memory bank 1. 11 from mem bank 2. 
           chain_ALU_2 : out STD_LOGIC_VECTOR(1 downto 0); --mux select for ALU Lane 2 source: 00: from regfile. 01 from ALU Lane 2. 10 from memory bank 1. 11 from mem bank 2.
           chain_MEM_1 : out STD_LOGIC;--mux select for MEM Lane 2 source: 00 from regfile. 01 from ALU Lane 1. 10 from ALU Lane 2. 11 is reserved
           chain_MEM_2 : out STD_LOGIC); --mux select for MEM Lane 2 source: 00 from regfile. 01 from ALU Lane 1. 10 from ALU Lane 2. 11 is reserved 
end Chaining_controller;

architecture Chaining_controller_arch of Chaining_controller is

begin


end Chaining_controller_arch;
