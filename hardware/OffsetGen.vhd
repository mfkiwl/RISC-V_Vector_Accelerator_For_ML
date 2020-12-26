library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OffsetGen is
  generic (
    VLEN: natural range 32 to 8192 := 32; -- vector register length in bits; must be a power of two.
    lgVLEN : natural range 5 to 13 := 5; -- log2(VLEN)
    SLEN: natural range 32 to 8192:= 32; --striping distance
    XLEN: natural range 8 to 64 := 32 -- scalar register length in bits
  );
  port (
    i_clk : in std_logic;
    i_load : in std_logic; -- should be asserted for one clock cycle aka newInst
    i_mask : in std_logic_vector (VLEN-1 downto 0);
    i_vsew : in std_logic_vector (2 downto 0); -- vtype CSR [4:2]
    i_vlmul : in std_logic_vector (2 downto 0); -- vtype CSR [5,1:0]
    i_vl : in std_logic_vector (XLEN-1 downto 0); -- number of vector elements to be processed.
    i_vstart: in std_logic_vector (lgVLEN-1 downto 0); -- vstart CSR [log2VLEN-1:0]
    i_vm: in STD_LOGIC; -- vector instruction vm mask field (inst[25]). Masking disabled = 1. Masking enabled = 0.
    o_offset : out std_logic_vector (lgVLEN-1 downto 0); -- index of next vector element to be processed.
    o_done : out std_logic
  );
end OffsetGen;

architecture Behavioral of OffsetGen is
  signal current_mask : std_logic_vector (VLEN-1 downto 0);
  signal SEW : natural range 8 to 1024;
  signal VLMAX : natural range 1 to 8192; -- maximum number of vector elements that can be processed for a given SEW and LMUL.
  signal MLEN : natural range 1 to 8192; -- mask element length, in bits.
  signal FIRST_ELEMENT : natural range 0 to VLEN-1; -- index of first element to be processed.
  signal NUM_ELEMENTS : natural range 0 to VLEN; -- number of elements to be processed.
begin
  -- Set first element index.
  FIRST_ELEMENT <= to_integer(unsigned(i_vstart));
  -- Set number of elements to process.
  NUM_ELEMENTS <= VLMAX when (to_integer(unsigned(i_vl)) > VLMAX) else to_integer(unsigned(i_vl));

  -- Initialize and process current_mask.
  process (i_clk) is
    variable mask : std_logic_vector (VLEN-1 downto 0);
   begin
     if (rising_edge(i_clk)) then
       if (i_load = '1') then
        if (NUM_ELEMENTS = 0) then
          mask := (others => '0'); -- No elements to process.
        elsif (i_vm = '0') then
          mask := i_mask;         -- Masking enabled
        else
          mask := (others => '1');  -- Masking disabled
        end if;
       else
        if (NUM_ELEMENTS /= 0) then
          for i in FIRST_ELEMENT to NUM_ELEMENTS-1 loop
            if (mask(i*MLEN) = '1') then
              mask(i*MLEN) := '0';
              exit;
            end if;
          end loop;
         end if;
       end if;
     end if;
     current_mask <= mask;
   end process;

  -- Set o_offset 
  process (current_mask) is
    begin
      o_offset <= (others=>'0');
      if (NUM_ELEMENTS /= 0) then
        for i in FIRST_ELEMENT to NUM_ELEMENTS-1 loop
          if (current_mask(i*MLEN) = '1') then
            o_offset <= std_logic_vector(to_unsigned(i, o_offset'length));
            exit;
          end if;
        end loop;
      end if;
    end process;
  
     --Assert the o_done signal when the current_mask is equal to zero.
    process (current_mask) is
    begin
      o_done <= '1';
      if (NUM_ELEMENTS /= 0) then
        for i in FIRST_ELEMENT to NUM_ELEMENTS-1 loop
          if (current_mask(i*MLEN) = '1') then
            o_done <= '0';
            exit;
          end if;
        end loop;
      end if;
    end process;

  -- Set SEW
  with i_vsew select 
    SEW <= 8 when "000",
           16 when "001",
           32 when "010",
           64 when "011",
           128 when "100",
           256 when "101",
           512 when "110",
           1024 when "111",
           XLEN when others;

  -- Set VLMAX
  with i_vlmul select
    VLMAX <= VLEN/SEW when "000", -- LMUL = 1
             2*VLEN/SEW when "001", -- LMUL = 2
             4*VLEN/SEW when "010", -- LMUL = 4
             8*VLEN/SEW when "011", -- LMUL = 8
             VLEN/(SEW*8) when "101", -- LMUL = 1/8
             VLEN/(SEW*4) when "110", -- LMUL = 1/4
             VLEN/(SEW*2) when "111", -- LMUL = 1/2
             VLEN/SEW when others;

  -- Set MLEN
  process(i_vlmul) begin
    if (SLEN< VLEN) then --TODO: double check this case
        case(i_vlmul) is
            when "000"=> MLEN<= SEW; -- LMUL = 1  
            when "001"=> MLEN<= SEW/2; -- LMUL = 2  
            when "010"=> MLEN<= SEW/4; -- LMUL = 4  
            when "011"=> MLEN<= SEW/8; -- LMUL = 8  
            when "101"=> MLEN<= SEW*8; -- LMUL = 1/8
            when "110"=> MLEN<= SEW*4; -- LMUL = 1/4
            when "111"=> MLEN<= SEW*2; -- LMUL = 1/2
            when others=>MLEN<= 1;
        end case;
     else
        MLEN<=1;
    end if;
  end process;
    
end Behavioral;
