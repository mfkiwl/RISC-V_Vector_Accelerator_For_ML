library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OffsetGen_tb is
--  Port ( );
end OffsetGen_tb;

architecture Structural of OffsetGen_tb is
component OffsetGen is
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
end component;

constant    VLEN: natural range 32 to 8192 := 32; -- vector register length in bits; must be a power of two.
constant    lgVLEN : natural range 5 to 13 := 5; -- log2(VLEN)
constant    XLEN: natural range 8 to 64 := 32; -- scalar register length in bits
constant    SLEN: natural range 32 to 8192:= 32;
signal    i_clk : std_logic;
signal    i_load : std_logic; -- should be asserted for one clock cycle.
signal    i_WriteEn: std_logic;
signal    i_mask : std_logic_vector (VLEN-1 downto 0);
signal    i_vsew :  std_logic_vector (2 downto 0); -- vtype CSR [4:2]
signal    i_vlmul :  std_logic_vector (2 downto 0); -- vtype CSR [5,1:0]
signal    i_vl : std_logic_vector (XLEN-1 downto 0); -- number of vector elements to be processed.
signal    i_vstart: std_logic_vector (lgVLEN-1 downto 0); -- vstart CSR [log2VLEN-1:0]
signal    i_vm: STD_LOGIC; -- vector instruction vm mask field (inst[25]). Masking disabled = 1. Masking enabled = 0.
signal    o_offset : std_logic_vector (lgVLEN-1 downto 0); -- index of next vector element to be processed.
signal    o_done : std_logic;


begin
UUT: OffsetGen generic map(
                VLEN=>VLEN,
                lgVLEN=>lgVLEN,
                XLEN=>XLEN,
                SLEN=> SLEN)
              port map(
                i_clk=>i_clk,
                i_load=>i_load,
                i_mask=>i_mask,
                i_vsew=>i_vsew,
                i_vlmul=>i_vlmul,
                i_vl=>i_vl,
                i_vstart=>i_vstart,
                i_vm=>i_vm,
                o_offset=>o_offset,
                o_done=>o_done);
                
    clk_proc: process begin
        i_clk<='0';
        wait for 5ns;
        i_clk<='1'; 
        wait for 5ns;
    end process;    
              
    testing: process begin
    
    i_load<='0';i_mask<=x"ABCDEF10"; i_vsew<="000";i_vlmul<="000";i_vl<="00000000000000000000000000100000";i_vstart<="00000";i_vm<='1'; --Testing for unmasked instruction
    wait for 5 ns; 
    i_load<='1'; wait for 5 ns;i_load<='0';wait for 35ns;
    i_mask<=x"0000000B";i_vm<='0';
    i_load<='1'; 
    wait for 5 ns;i_load<='0';wait for 5ns;
    wait;
    end process;              

end Structural;
