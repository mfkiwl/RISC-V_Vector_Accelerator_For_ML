library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity RegFile_AddrGen is
    generic (
            SEW_MAX : natural range 1 to 1024 := 32;
            lgSEW_MAX: integer range 1 to 10:=5;
            VLEN:integer:=32; --number of bits in register       
            XLEN: integer:=32;
            VLMAX: integer :=32;
            RegNum: integer:= 5 
    );
    Port (
            i_clk : in std_logic;
            newInst: in STD_LOGIC;
            sew: in std_logic_vector (lgSEW_MAX-1 downto 0);
            vm: in STD_LOGIC;
            vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
            o_done_1 : out std_logic; 
            o_done_2 : out std_logic;
            mask_bit: out STD_LOGIC;
            out1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
            out2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
            out3 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
            out4 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
            RegSel1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            RegSel2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            RegSel3 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            RegSel4 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            WriteEn1 : in STD_LOGIC;
            WriteEn2 : in STD_LOGIC;
            WriteData1 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
            WriteDest1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            WriteData2 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
            WriteDest2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0)
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
           -- Max Vector Length (max number of elements) 
           VLMAX: integer :=32;
           -- log(Number of Vector Registers)
           RegNum: integer:= 5; 
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32 --number of bits in register
           );
    Port ( clk : in STD_LOGIC;
           newInst: in STD_LOGIC;
           out1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out3 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out4 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           mask_bit: out STD_LOGIC;
           RegSel1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSel2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSel3 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSel4 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           WriteEn1 : in STD_LOGIC;
           WriteEn2 : in STD_LOGIC;
           WriteData1 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           WriteData2 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           offset_1 : in STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0);  
           offset_2 : in STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0);
           mask_reg: out STD_LOGIC_VECTOR(VLEN-1 downto 0)                        
           );
end component;

signal offset_1_sig: STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0);
signal offset_2_sig: STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0);
signal mask_reg_sig: STD_LOGIC_VECTOR(VLEN-1 downto 0);
begin

RegFile: RegisterFile GENERIC MAP(VLMAX, RegNum, SEW_MAX, lgSEW_MAX, XLEN, VLEN)
                      PORT MAP (i_clk,newInst,out1,out2,out3,out4,mask_bit,
                      RegSel1,RegSel2,RegSel3,RegSel4,
                      WriteEn1,WriteEn2,
                      WriteData1,WriteDest1,
                      WriteData2,WriteDest2,
                      sew,vl,vstart,offset_1_sig,offset_2_sig,mask_reg_sig);
AddrGen1: addr_gen GENERIC MAP(SEW_MAX,lgSEW_MAX,VLEN,XLEN)
                   PORT MAP(i_clk,newInst,mask_reg_sig,sew,vstart,vm,offset_1_sig,o_done_1);
                    
AddrGen2: addr_gen GENERIC MAP(SEW_MAX, lgSEW_MAX,XLEN)                      
                   PORT MAP(i_clk,newInst,mask_reg_sig,sew,vstart,vm,offset_2_sig,o_done_2);
end Behavioral;
