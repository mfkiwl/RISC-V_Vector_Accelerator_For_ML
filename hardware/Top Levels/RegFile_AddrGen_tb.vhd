library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegFile_AddrGen_tb is
--  Port ( );
end RegFile_AddrGen_tb;

architecture Behavioral of RegFile_AddrGen_tb is
component RegFile_AddrGen is
    generic (
           NB_LANES: integer:=2; --Number of lanes
           READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
           VLMAX: integer :=32; -- Max Vector Length (max number of elements) 
           REG_NUM: integer:= 5; -- log (number of registers)
           REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32 --number of bits in register
    );
    Port (
           i_clk : in std_logic;
           newInst: in STD_LOGIC;
           sew: in std_logic_vector (lgSEW_MAX-1 downto 0);
           vm: in STD_LOGIC;
           vstart: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
           o_done : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0); 
           mask_bit: out STD_LOGIC;
           OutPort: out STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*SEW_MAX)-1 downto 0);
           RegSel: in STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
           WriteEn : in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
           WriteData : in STD_LOGIC_VECTOR (NB_LANES*SEW_MAX-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
           vl: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0)
  );
end component;

constant  NB_LANES: integer:=2; --Number of lanes
constant  READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
constant  VLMAX: integer :=32; -- Max Vector Length (max number of elements) 
constant  REG_NUM: integer:= 5; -- log (number of registers)
constant  REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks
constant  SEW_MAX: integer:=32;
constant  lgSEW_MAX: integer:=5;
constant  XLEN:integer:=32; --Register width
constant  VLEN:integer:=32; --number of bits in register

signal    i_clk : std_logic;
signal    newInst: STD_LOGIC;
signal    sew: std_logic_vector (lgSEW_MAX-1 downto 0);
signal    vm: STD_LOGIC;
signal    vstart:  STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
signal    o_done : STD_LOGIC_VECTOR(NB_LANES-1 downto 0); 
signal    mask_bit: STD_LOGIC;
signal    OutPort: STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*SEW_MAX)-1 downto 0);
signal    RegSel: STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
signal    WriteEn : STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
signal    WriteData : STD_LOGIC_VECTOR (NB_LANES*SEW_MAX-1 downto 0);
signal    WriteDest : STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
signal    vl: STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);

begin

UUT: RegFile_AddrGen GENERIC MAP(NB_LANES,READ_PORTS_PER_LANE,VLMAX,REG_NUM,REGS_PER_BANK,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
                     PORT MAP(i_clk,newInst,sew,vm,vstart,
                      o_done,mask_bit,
                      OutPort,
                      RegSel,
                      WriteEn,
                      WriteData,
                      WriteDest,
                      vl
                      );
    clk_proc: process begin
        i_clk<='0';
        wait for 5ns;
        i_clk<='1'; 
        wait for 5ns;
    end process; 
    
    process begin
        vm<='1';
        newInst<='0'; sew <= "01000"; vl <= x"0000000400000004"; vstart <= x"0000000000000000"; 
        WriteEn<="11"; WriteData<= x"0000000800000004"; WriteDest<="00000000";
        RegSel<="0001000000010000";
        wait for 10ns; newInst<='1'; wait for 5ns; newInst<= '0'; wait for 5ns;
        WriteData<= x"0000000900000005"; wait for 10ns;
        WriteData<= x"0000000A00000006"; wait for 10ns;
        WriteData<= x"0000000B00000007"; wait for 30ns;
        WriteEn<= "00"; 
        newInst<='1'; wait for 5ns; newInst<= '0'; wait for 5ns;
        wait;
    
    end process;                      

end Behavioral;
