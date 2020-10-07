library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addr_gen is
  generic (
    SEW_MAX : natural range 1 to 1024 := 32;
    lgSEW_MAX: integer range 1 to 10:=5;
    VLEN: integer:=32;
    XLEN: integer:=32
  );
  port (
    i_clk : in std_logic;
    i_load : in std_logic; -- should be asserted for one clock cycle aka newInst
    i_mask : in std_logic_vector (VLEN-1 downto 0);
    sew: in std_logic_vector (lgSEW_MAX-1 downto 0);
    vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
    vm: in STD_LOGIC;
    o_offset : out std_logic_vector (lgSEW_MAX-1 downto 0);
    o_done : out std_logic
  );
end addr_gen;

architecture beh of addr_gen is
  signal current_mask : std_logic_vector (VLEN-1 downto 0);
  signal sew_int: integer;
  signal vstart_int:integer;
  signal masked_offset:std_logic_vector (lgSEW_MAX-1 downto 0);
  signal unmasked_offset:std_logic_vector (lgSEW_MAX-1 downto 0);

begin
  sew_int<=to_integer((unsigned(sew)));
  vstart_int<=to_integer((unsigned(vstart)));
  process (i_clk) is
   variable r_mask : std_logic_vector (VLEN-1 downto 0);
   variable i : integer range 0 to VLEN-1;
  begin
    if (rising_edge(i_clk)) then
      
      if (i_load = '1') then
        r_mask := i_mask;
        unmasked_offset<=std_logic_vector(to_unsigned(vstart_int,unmasked_offset'length));
      else
        unmasked_offset<=std_logic_vector(to_unsigned((to_integer(unsigned(unmasked_offset))+sew_int),unmasked_offset'length));
        i:=vstart_int*sew_int;
        while(i< SEW_MAX-sew_int-1) loop
          if (r_mask(i) = '1') then
            r_mask(i+sew_int-1 downto i):= (others=>'0');
            exit;
          else
            r_mask(i+sew_int-1 downto i):= (others=>'0');
            i:=i+sew_int;
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
  variable i : integer range 0 to VLEN-1;
  begin
    masked_offset <= (others=>'0');
     --i:=vstart_int*sew_int;
     for i in vstart_int*sew_int to SEW_MAX-sew_int-1 loop
      if (current_mask(i) = '1') then
        masked_offset <= std_logic_vector(to_unsigned(i, o_offset'length));
        exit;
       else
      end if;
    end loop;
  end process;
  
  -- Assert the o_done signal when the current_mask is equal to zero.
  -- TODO: Check if this will work: o_done <= current_mask = (others=>'0');
  process (current_mask) is
  begin
    o_done <= '1';
    for i in vstart_int*sew_int to SEW_MAX-1 loop
      if (current_mask(i) = '1') then
        o_done <= '0';
        exit;
      end if;
    end loop;
  end process;

o_offset<=unmasked_offset when vm = '1' else masked_offset;

end beh;
