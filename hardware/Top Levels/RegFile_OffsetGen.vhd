library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity RegFile_OffsetGen is
    generic (
           NB_LANES: integer:=2; --Number of lanes
           READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
           REG_NUM: integer:= 5; -- log (number of registers)
           REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks
           ELEN: integer:=1024;
           lgELEN: integer:=10;
           XLEN:integer:=32; --Register width
           VLEN:integer:=1024; --number of bits in register
           lgVLEN:integer:=5
    );
    Port (
            i_clk : in std_logic;
            newInst: in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
            sew: in std_logic_vector (3*NB_LANES-1 downto 0);
            vm: in STD_LOGIC;
            vstart: in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);
            vlmul: in STD_LOGIC_VECTOR(3*NB_LANES-1 downto 0);             
            o_done : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0); 
            mask_bit: out STD_LOGIC;
            OutPort: out STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*ELEN)-1 downto 0);
            RegSel: in STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
            WriteEn : in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
            WriteData : in STD_LOGIC_VECTOR (NB_LANES*ELEN-1 downto 0);
            WriteDest : in STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
            w_offset_in : in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);--offset coming from the pipeline
            w_offset_out : out STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0); --offset going to pipeline
            vl: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0)
  );
end RegFile_OffsetGen;

architecture Behavioral of RegFile_OffsetGen is
component OffsetGen is
  generic (
    VLEN: natural range 32 to 8192 := 32; -- vector register length in bits; must be a power of two.
    lgVLEN : natural range 5 to 13 := 5; -- log2(VLEN)
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

component RegisterFile is
    generic (
           NB_LANES: integer:=2; --Number of lanes
           READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
           REG_NUM: integer:= 5; -- log (number of registers)
           REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks
           ELEN: integer:=1024;
           lgELEN: integer:=10;
           XLEN:integer:=32; --Register width
           VLEN:integer:=1024; --number of bits in register
           lgVLEN:integer:=5
           );
    Port ( clk : in STD_LOGIC;
           newInst: in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
           mask_bit: out STD_LOGIC;
           OutPort: out STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*ELEN)-1 downto 0);
           RegSel: in STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
           WriteEn : in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
           WriteData : in STD_LOGIC_VECTOR (NB_LANES*ELEN-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
           sew: in STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);
           vlmul: in STD_LOGIC_VECTOR(3*NB_LANES-1 downto 0); 
           vl: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);
           r_offset : in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0); 
           w_offset : in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0); 
           mask_reg: out STD_LOGIC_VECTOR(VLEN-1 downto 0)                        
           );
end component;

signal r_offset_sig: STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);
--signal w_offset_sig: STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);
signal mask_reg_sig: STD_LOGIC_VECTOR(VLEN-1 downto 0);

begin
RegFile: RegisterFile GENERIC MAP(NB_LANES,READ_PORTS_PER_LANE,REG_NUM,REGS_PER_BANK,ELEN,lgELEN,XLEN,VLEN,lgVLEN)
                      PORT MAP(
                      clk=>i_clk,
                      newInst=>newInst,
                      mask_bit=>mask_bit,
                      OutPort=>OutPort,
                      RegSel=>RegSel,
                      WriteEn=>WriteEn,
                      WriteData=>WriteData,
                      WriteDest=>WriteDest,
                      sew=>sew,
                      vlmul=>vlmul,
                      vl=>vl,
                      vstart=>vstart,
                      r_offset=>r_offset_sig,
                      w_offset=>w_offset_in,
                      mask_reg=>mask_reg_sig
                      );


OffsetGen_GEN:for i in 0 to NB_LANES-1 generate
    OffsetGens: OffsetGen GENERIC MAP(
                        VLEN=>VLEN,
                        lgVLEN=>lgVLEN,
                        XLEN=>XLEN)
                        PORT MAP(i_clk,
                        newInst(i),
                        mask_reg_sig,
                        sew((i+1)*3-1 downto i*3),
                        vlmul((i+1)*3-1 downto i*3),
                        vl((i+1)*XLEN-1 downto i*XLEN),
                        vstart((i+1)*lgVLEN-1 downto i*lgVLEN),
                        vm,
                        r_offset_sig((i+1)*lgVLEN-1 downto i*lgVLEN),
                        o_done(i));                 
end generate OffsetGen_GEN;
w_offset_out<=r_offset_sig; --offset going to pipeline takes the same value as the read offset
end Behavioral;
