library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegFile_ALU_tb is
end RegFile_ALU_tb;

architecture RegFile_ALU_tb_arch of RegFile_ALU_tb is

component RegFile_ALU is
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
    Port(   clk: in STD_LOGIC; 
            rst: in STD_LOGIC;
            busy: in STD_LOGIC;
            Xdata_1: in STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 1
            Xdata_2: in STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 2
            Idata_1: in STD_LOGIC_VECTOR(4 downto 0); --data coming from immediate field to Lane 1
            Idata_2: in STD_LOGIC_VECTOR(4 downto 0); --data coming from immediate field to Lane 2
            op2_src_1: in STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 for Lane 1
                                                -- 00 = vector reg
                                                -- 01 = scalar reg
                                                -- 10 = immediate
                                                -- 11 = RESERVED (unbound)
            op2_src_2: in STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 for Lane 2
            funct6_1: in STD_LOGIC_VECTOR(5 downto 0); --to know which operation
            funct6_2: in STD_LOGIC_VECTOR(5 downto 0); --to know which operation
            funct3_1: in STD_LOGIC_VECTOR(2 downto 0); --to know which operation
            funct3_2: in STD_LOGIC_VECTOR(2 downto 0); --to know which operation
            WriteEn_i_1: in STD_LOGIC; --WriteEn for Lane 1 from controller
            WriteEn_i_2: in STD_LOGIC; --WriteEn for Lane 2 from controller
            result_1: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 1 (to remove)
            result_2: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 2 (to remove) 
            ------Register File
            sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
            vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
            vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
            newInst: in STD_LOGIC;
            op1_1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
            op2_1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
            op1_2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
            op2_2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
            RegSel1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            RegSel2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            RegSel3 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            RegSel4 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            WriteDest1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
            WriteDest2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0)
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

signal  clk: STD_LOGIC; 
signal  rst: STD_LOGIC;
signal  busy: STD_LOGIC;
signal  Xdata_1: STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 1
signal  Xdata_2: STD_LOGIC_VECTOR(XLEN-1 downto 0); --data from scalar register for Lane 2
signal  Idata_1: STD_LOGIC_VECTOR(4 downto 0); --data coming from immediate field to Lane 1
signal  Idata_2: STD_LOGIC_VECTOR(4 downto 0); --data coming from immediate field to Lane 2
signal  op2_src_1: STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 for Lane 1
signal  op2_src_2: STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 for Lane 2
signal  funct6_1:  STD_LOGIC_VECTOR(5 downto 0); --to know which operation
signal  funct6_2:  STD_LOGIC_VECTOR(5 downto 0); --to know which operation
signal  funct3_1:  STD_LOGIC_VECTOR(2 downto 0); --to know which operation
signal  funct3_2:  STD_LOGIC_VECTOR(2 downto 0); --to know which operation
signal  WriteEn_i_1: STD_LOGIC; --WriteEn for Lane 1 from controller
signal  WriteEn_i_2: STD_LOGIC; --WriteEn for Lane 2 from controller
signal  result_1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 1 (to remove)
signal  result_2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); --result from Lane 2 (to remove) 
---Register File
signal  sew: STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
signal  vl: STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal  vstart: STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal  newInst: STD_LOGIC;
signal  op1_1 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
signal  op2_1 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
signal  op1_2 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
signal  op2_2 : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); --(to remove)
signal  RegSel1 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal  RegSel2 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal  RegSel3 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal  RegSel4 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal  WriteDest1 : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal  WriteDest2 : STD_LOGIC_VECTOR (RegNum-1 downto 0);

begin
    UUT: RegFile_ALU GENERIC MAP(VLMAX,RegNum,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
    PORT MAP(clk,rst,busy,
             Xdata_1, Xdata_2, Idata_1, Idata_2, 
             op2_src_1, op2_src_2, funct6_1, funct6_2, funct3_1, funct3_2, WriteEn_i_1, WriteEn_i_2,
             result_1, result_2, 
             sew, vl, vstart, newInst, op1_1, op2_1, op1_2, op2_2, RegSel1, RegSel2, RegSel3, RegSel4, WriteDest1, WriteDest2);
    
    clk_proc: process begin
        clk<='0';
        wait for 5ns;
        clk<='1'; 
        wait for 5ns;
    end process;
    
    process begin
        rst<= '1';
        newInst<='0'; sew <= "01000"; vl <= x"00000004"; vstart <= x"00000000";
        Idata_1<= "00001"; Idata_2<= "00001";
        WriteEn_i_1<='1'; Xdata_1<= x"00000004"; WriteDest1<="00000";
        WriteEn_i_2<='1'; Xdata_2<= x"00000008"; WriteDest2<="10000";
        RegSel1<="00000"; RegSel2<="00001"; RegSel3<= "10000"; RegSel4<= "10001";
        op2_src_1<= "01"; op2_src_2<= "01"; funct6_1<= "000000"; funct6_2<= "000000"; funct3_1<="000"; funct3_2<="000";   
        wait for 10ns; newInst<='1'; wait for 5ns; newInst<= '0'; wait for 5ns;
        
        wait;
    end process;

end RegFile_ALU_tb_arch;
