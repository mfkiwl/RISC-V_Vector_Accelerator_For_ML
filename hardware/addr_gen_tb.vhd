library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity addr_gen_tb is
--  Port ( );
end addr_gen_tb;

architecture Structural of addr_gen_tb is
component addr_gen is
  generic (
    SEW_MAX : natural range 1 to 1024 := 32;
    lgSEW_MAX : natural range 1 to 10 := 5;
    XLEN: integer:=32
  );
  port (
    i_clk : in std_logic;
    i_load : in std_logic; -- should be asserted for one clock cycle.
    i_mask : in std_logic_vector (SEW_MAX-1 downto 0);
    sew: in std_logic_vector (lgSEW_MAX-1 downto 0);
    vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
    vm: in STD_LOGIC;
    o_offset : out std_logic_vector (lgSEW_MAX-1 downto 0);
    o_done : out std_logic
  );
end component;

constant  SEW_MAX : natural range 1 to 1024 := 32;
constant  lgSEW_MAX : natural range 1 to 10 := 5;
constant  XLEN:integer:=32;
signal    i_clk : std_logic;
signal    i_load : std_logic; -- should be asserted for one clock cycle.
signal    i_mask : std_logic_vector (SEW_MAX-1 downto 0);
signal    o_offset : std_logic_vector (lgSEW_MAX-1 downto 0);
signal    o_done : std_logic;
signal    sew:  std_logic_vector (lgSEW_MAX-1 downto 0);
signal    vstart:  STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal    vm:  STD_LOGIC;

begin
UUT: addr_gen generic map(SEW_MAX,lgSEW_MAX,XLEN)
              port map(i_clk,i_load,i_mask,sew,vstart,vm,o_offset,o_done);
    clk_proc: process begin
        i_clk<='0';
        wait for 5ns;
        i_clk<='1'; 
        wait for 5ns;
    end process;              
process begin

i_load<='0';i_mask<=x"ABCDEF10"; sew<="01000";vstart<=x"00000000";vm<='1';wait for 5 ns; 
i_load<='1'; wait for 5 ns;i_load<='0';wait for 35ns;
i_mask<=x"ABCCEF10";vstart<=x"00000000";vm<='0';
i_load<='1'; wait for 5 ns;i_load<='0';
wait;
end process;              

end Structural;
