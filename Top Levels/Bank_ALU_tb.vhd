library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity Bank_ALU_tb is
--  Port ( );
end Bank_ALU_tb;

architecture Behavioral of Bank_ALU_tb is
component Bank_ALU is
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
           reset: in STD_LOGIC;
           out1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           RegSel1 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           RegSel2 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           WriteEn : in STD_LOGIC;
           WriteData : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           funct6: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation
           busy: out STD_LOGIC;
           cs: in STD_LOGIC;
           alu_res : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0)
           );
end component;
constant        XLEN:integer:=32; --Register width
constant        ELEN:integer:=32; --Maximum element width
constant        VLEN:integer:=32;
constant        SEW_MAX:integer:=32;
constant        lgSEW_MAX:integer:=5;
constant        VLMAX: integer :=32;
constant        logVLMAX: integer := 5;
constant        RegNum: integer:= 5;

signal     clk : STD_LOGIC;
signal     newInst: STD_LOGIC;
signal     reset: STD_LOGIC;
signal     out1 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal     out2 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);

signal     RegSel1 : STD_LOGIC_VECTOR (RegNum-2 downto 0);
signal     RegSel2 : STD_LOGIC_VECTOR (RegNum-2 downto 0);

signal     WriteEn : STD_LOGIC;

signal     WriteData: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);   
signal     WriteDest : STD_LOGIC_VECTOR (RegNum-2 downto 0);

signal     sew: STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
signal     vl: STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal     vstart: STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal     funct6: STD_LOGIC_VECTOR(5 downto 0);
signal     busy: STD_LOGIC;
signal     cs: STD_LOGIC;
signal     alu_res : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
begin
    UUT: Bank_ALU GENERIC MAP(VLMAX,RegNum,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
    PORT MAP(clk,newInst,reset,out1, out2,RegSel1,RegSel2,WriteEn,WriteData,WriteDest,sew,vl,vstart,funct6, busy,cs,alu_res);
    
    clk_proc: process begin
        clk<='1';
        wait for 5ns;
        clk<='0'; 
        wait for 5ns;
    end process;
    
    process begin
        newInst<='0'; sew <= "01000"; vl <= x"00000004"; vstart <= x"00000000"; cs<='1'; reset<='0'; 
        WriteEn<='1'; WriteData<= x"00000004"; WriteDest<="0000";
        RegSel1<="0000"; RegSel2<="0001"; 
        wait for 10ns; newInst<='1'; wait for 5ns; newInst<= '0'; wait for 5ns;
        WriteData<= x"00000005"; wait for 10ns;
        WriteData<= x"00000006"; wait for 10ns;
        WriteData<= x"00000007"; wait for 30ns;
        newInst<='1'; WriteDest<="0001"; wait for 5ns; newInst<= '0'; wait for 5ns;
        WriteData<= x"00000004"; wait for 10ns;
        WriteData<= x"00000005"; wait for 10ns;
        WriteData<= x"00000006"; wait for 10ns;
        WriteData<= x"00000007"; wait for 30ns;
        newInst<='1'; funct6<= "000000";WriteDest<="0010";cs<= '0'; wait for 5ns;
        newInst<= '0';wait for 200ns;
        newInst<='1'; RegSel1<="0010";WriteEn<='0';wait for 5 ns;
        newInst<='0'; wait for 5 ns; 
        
        wait;
    end process;
end Behavioral;
