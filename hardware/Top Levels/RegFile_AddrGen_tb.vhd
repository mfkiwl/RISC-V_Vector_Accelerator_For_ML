library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegFile_AddrGen_tb is
--  Port ( );
end RegFile_AddrGen_tb;

architecture Behavioral of RegFile_AddrGen_tb is
component RegFile_AddrGen is
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
end component;

constant  SEW_MAX : natural range 1 to 1024 := 32;
constant  lgSEW_MAX : natural range 1 to 10 := 5;
constant  XLEN:integer:=32;
constant  VLEN:integer:=32; --number of bits in register 
constant  VLMAX: integer :=32;
constant  RegNum: integer:= 5;
signal    i_clk : std_logic;
signal    newInst:  STD_LOGIC;
signal    sew:  std_logic_vector (lgSEW_MAX-1 downto 0);
signal    vm:  STD_LOGIC;
signal    vstart:  STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal    o_done_1 :  std_logic; 
signal    o_done_2 :  std_logic;
signal    mask_bit:  STD_LOGIC;
signal    out1 :  STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal    out2 :  STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal    out3 :  STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal    out4 :  STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal    RegSel1 :  STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal    RegSel2 :  STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal    RegSel3 :  STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal    RegSel4 :  STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal    WriteEn1 :  STD_LOGIC;
signal    WriteEn2 :  STD_LOGIC;
signal    WriteData1 :  STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal    WriteDest1 :  STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal    WriteData2 :  STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal    WriteDest2 :  STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal    vl: STD_LOGIC_VECTOR(XLEN-1 downto 0); 

begin

UUT: RegFile_AddrGen GENERIC MAP(SEW_MAX,lgSEW_MAX,VLEN,XLEN,VLMAX,RegNum)
                     PORT MAP(i_clk,newInst,sew,vm,vstart,
                      o_done_1,o_done_2,mask_bit,
                      out1,out2,out3,out4,
                      RegSel1,RegSel2,RegSel3,RegSel4,
                      WriteEn1,WriteEn2,
                      WriteData1,WriteDest1,
                      WriteData2,WriteDest2,
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
        newInst<='0'; sew <= "01000"; vl <= x"00000004"; vstart <= x"00000000"; 
        WriteEn1<='1'; WriteData1<= x"00000004"; WriteDest1<="00000";
        WriteEn2<='1'; WriteData2<= x"00000008"; WriteDest2<="10000";
        RegSel1<="00000"; RegSel2<="00001"; RegSel3<= "10000"; RegSel4<= "10001";
        wait for 10ns; newInst<='1'; wait for 5ns; newInst<= '0'; wait for 5ns;
        WriteData1<= x"00000005"; WriteData2 <= x"00000009"; wait for 10ns;
        WriteData1<= x"00000006"; WriteData2 <= x"0000000A"; wait for 10ns;
        WriteData1<= x"00000007"; WriteData2 <= x"0000000B"; wait for 30ns;
        WriteEn1<= '0'; WriteEn2<= '0';
        newInst<='1'; wait for 5ns; newInst<= '0'; wait for 5ns;
        wait;
    
    end process;                      

end Behavioral;
