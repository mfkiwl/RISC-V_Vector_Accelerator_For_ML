library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity RegFile_AddrGen is
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
end RegFile_AddrGen;

architecture Behavioral of RegFile_AddrGen is
component addr_gen is
    generic (
           SEW_MAX : natural range 1 to 1024 := 32;
           lgSEW_MAX: integer range 1 to 10:=5;
           VLEN: integer:=32;
           XLEN: integer:=32
    );
    Port (
           i_clk : in std_logic;
           i_load : in std_logic; -- should be asserted for one clock cycle aka newInst
           i_mask : in std_logic_vector (VLEN-1 downto 0);
           sew: in std_logic_vector (lgSEW_MAX-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           vm: in STD_LOGIC;
           o_offset : out std_logic_vector (lgSEW_MAX-1 downto 0);
           o_done : out std_logic
  );
end component;

component RegisterFile is
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
    Port ( clk : in STD_LOGIC;
           newInst: in STD_LOGIC;
           mask_bit: out STD_LOGIC;
           OutPort: out STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*SEW_MAX)-1 downto 0);
           RegSel: in STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
           WriteEn : in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
           WriteData : in STD_LOGIC_VECTOR (NB_LANES*SEW_MAX-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
           reg_offset : in STD_LOGIC_VECTOR(NB_LANES*lgSEW_MAX-1 downto 0);  
           mask_reg: out STD_LOGIC_VECTOR(VLEN-1 downto 0)                        
           );
end component;

signal reg_offset_sig: STD_LOGIC_VECTOR(NB_LANES*lgSEW_MAX-1 downto 0);
signal mask_reg_sig: STD_LOGIC_VECTOR(VLEN-1 downto 0);

begin
RegFile: RegisterFile GENERIC MAP(NB_LANES,READ_PORTS_PER_LANE,VLMAX ,REG_NUM,REGS_PER_BANK,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
                      PORT MAP(i_clk,newInst,mask_bit,OutPort,RegSel,WriteEn,WriteData,WriteDest,sew,vl,vstart,reg_offset_sig,mask_reg_sig);

AddrGen_GEN:for i in 0 to NB_LANES-1 generate
    AddrGen: addr_gen GENERIC MAP(SEW_MAX,lgSEW_MAX,VLEN,XLEN)
                      PORT MAP(i_clk,newInst,mask_reg_sig,sew,
                      vstart((i+1)*XLEN-1 downto i*XLEN),
                      vm,
                      reg_offset_sig((i+1)*lgSEW_MAX-1 downto i*lgSEW_MAX),
                      o_done(i));                 
end generate AddrGen_GEN;
end Behavioral;
