library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addr_gen is
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
end addr_gen;

architecture beh of addr_gen is
  signal current_mask : std_logic_vector (WORD_LEN-1 downto 0);
begin

  process (i_clk) is
   variable r_mask : std_logic_vector (WORD_LEN-1 downto 0);
  begin
    if (rising_edge(i_clk)) then
      if (i_load = '1') then
        r_mask := i_mask;
      else
        for i in 0 to WORD_LEN-1 loop
          if (r_mask(i) = '1') then
            r_mask(i) := '0';
            exit;
          end if;
        end loop; 
      end if;
    end if;
    current_mask <= r_mask;
  end process;

  -- Set o_addr to the bit position value of the current_mask's
  -- least significant asserted bit. For example, if current_mask = 0xAAAAAAAA
  -- o_addr = 1

  process (current_mask) is
  begin
    o_addr <= (others=>'0');
    for i in 0 to WORD_LEN-1 loop
      if (current_mask(i) = '1') then
        o_addr <= std_logic_vector(to_unsigned(i, o_addr'length));
        exit;
      end if;
    end loop;
  end process;

  -- Assert the o_done signal when the current_mask is equal to zero.
  -- TODO: Check if this will work: o_done <= current_mask = (others=>'0');
  process (current_mask) is
  begin
    o_done <= '1';
    for i in 0 to WORD_LEN-1 loop
      if (current_mask(i) = '1') then
        o_done <= '0';
        exit;
      end if;
    end loop;
  end process;

end beh;
