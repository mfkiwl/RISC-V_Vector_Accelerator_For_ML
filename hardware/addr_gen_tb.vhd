library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity addr_gen_tb is
--  Port ( );
end addr_gen_tb;

architecture Structural of addr_gen_tb is
component addr_gen is
  generic (
    WORD_LEN : natural range 1 to 1024 := 32;
    LOG_WORD_LEN : natural range 1 to 10 := 5
  );
  port (
    i_clk : in std_logic;
    i_load : in std_logic; -- should be asserted for one clock cycle.
    i_mask : in std_logic_vector (WORD_LEN-1 downto 0);
    o_addr : out std_logic_vector (LOG_WORD_LEN-1 downto 0);
    o_done : out std_logic
  );
end component;

constant  WORD_LEN : natural range 1 to 1024 := 32;
constant  LOG_WORD_LEN : natural range 1 to 10 := 5;
signal    i_clk : std_logic;
signal    i_load : std_logic; -- should be asserted for one clock cycle.
signal    i_mask : std_logic_vector (WORD_LEN-1 downto 0);
signal    o_addr : std_logic_vector (LOG_WORD_LEN-1 downto 0);
signal    o_done : std_logic;

begin
UUT: addr_gen generic map(WORD_LEN,LOG_WORD_LEN)
              port map(i_clk,i_load,i_mask,o_addr,o_done);
    clk_proc: process begin
        i_clk<='0';
        wait for 5ns;
        i_clk<='1'; 
        wait for 5ns;
    end process;              
process begin

i_load<='0';i_mask<=x"ABCDEF10"; wait for 5 ns; 
i_load<='1'; wait for 5 ns;i_load<='0';
wait;
end process;              

end Structural;
