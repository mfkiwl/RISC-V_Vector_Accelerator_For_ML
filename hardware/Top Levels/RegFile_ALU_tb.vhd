library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegFile_ALU_tb is
end RegFile_ALU_tb;

architecture RegFile_ALU_tb_arch of RegFile_ALU_tb is

component RegFile_ALU is
    generic (
           READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
           REG_NUM: integer:= 5; -- log (number of registers)
           REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks          
           NB_LANES:integer :=2;
           -- Max Vector Length (max number of elements) 
           VLMAX: integer :=32;
           -- log(Number of Vector Registers)
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32 --number of bits in register
           );
    Port(   clk: in STD_LOGIC; 
            rst: in STD_LOGIC;
            busy: in STD_LOGIC;
            Xdata: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0); --data from scalar register
            Idata: in STD_LOGIC_VECTOR(NB_LANES*5-1 downto 0); --data coming from immediate field of size 5 bits
            op2_src: in STD_LOGIC_VECTOR(2*NB_LANES-1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 
                                                -- 00 = vector reg
                                                -- 01 = scalar reg
                                                -- 10 = immediate
                                                -- 11 = RESERVED (unbound)
            funct6: in STD_LOGIC_VECTOR(NB_LANES*6-1 downto 0); --to know which operation
            funct3: in STD_LOGIC_VECTOR (NB_LANES*3-1 downto 0); --to know which operation
            WriteEn_i: in STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn from controller
            ------Register File            
            sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
            vm: in STD_LOGIC;            
            vl: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
            vstart: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
            newInst: in STD_LOGIC;
            RegSel: in STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
            WriteDest : in STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
--            ld_RF: in STD_LOGIC; --mux select to fill RF
            o_done : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0) 
);
end component;
constant        NB_LANES:integer :=2;
constant        READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
constant        REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks 
constant        XLEN:integer:=32; --Register width
constant        ELEN:integer:=32; --Maximum element width
constant        VLEN:integer:=32;
constant        SEW_MAX:integer:=32;
constant        lgSEW_MAX:integer:=5;
constant        VLMAX: integer :=32;
constant        logVLMAX: integer := 5;
constant        REG_NUM: integer:= 5;

signal        clk:  STD_LOGIC; 
signal        rst:  STD_LOGIC;
signal        busy:  STD_LOGIC;
signal        Xdata:  STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0); --data from scalar register
signal        Idata:  STD_LOGIC_VECTOR(NB_LANES*5-1 downto 0); --data coming from immediate field of size 5 bits
signal        op2_src:  STD_LOGIC_VECTOR(2*NB_LANES-1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 
signal        funct6:  STD_LOGIC_VECTOR(NB_LANES*6-1 downto 0); --to know which operation
signal        funct3:  STD_LOGIC_VECTOR (NB_LANES*3-1 downto 0); --to know which operation
signal        WriteEn_i:  STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn from controller          
signal        sew:  STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
signal        vm:  STD_LOGIC;            
signal        vl:  STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
signal        vstart:  STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
signal        newInst:  STD_LOGIC;
signal        RegSel:  STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
signal        WriteDest :  STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
signal        o_done : STD_LOGIC_VECTOR(NB_LANES-1 downto 0); 

begin
    UUT: RegFile_ALU GENERIC MAP(READ_PORTS_PER_LANE,REG_NUM,REGS_PER_BANK,NB_LANES,VLMAX,SEW_MAX,lgSEW_MAX,XLEN,VLEN)
                    PORT MAP(clk,rst,busy,
                             Xdata, Idata, 
                             op2_src, funct6, funct3, WriteEn_i,
                             sew,vm, vl, vstart, newInst, RegSel, WriteDest, o_done);
    
    clk_proc: process begin
        clk<='0';
        wait for 5ns;
        clk<='1'; 
        wait for 5ns;
    end process;
    
    process begin
        rst<= '1'; busy<= '0'; vm<='1';--ld_RF<= '0';
        WriteEn_i<="00"; 
        newInst<='0'; sew <= "01000"; vl <= x"0000000400000004"; vstart <= x"0000000000000000";
        Idata<= "0000100001";
        Xdata<= x"0000000800000002"; WriteDest<="00000000";
        RegSel<="0001000000010000";
        op2_src<= "0101";funct6<= "010111010111"; funct3<="000000";  
        wait for 10ns; rst<='0'; wait for 15ns; 
        newInst<='1'; wait for 2ns; WriteEn_i<="11"; Xdata<= x"0000000300000004"; wait for 3 ns;
        newInst<= '0'; wait for 7ns; Xdata<= x"0000000400000005";wait for 8ns;
        wait for 2ns; Xdata<= x"0000000500000006";wait for 8ns;
        wait for 2ns; Xdata<= x"0000000600000007";
        wait for 13ns; WriteEn_i<="00"; wait for 30ns; funct6<="000000000000"; wait for 10ns; funct6<="000000000000"; Xdata<= x"0000000600000005";
        wait for 15ns; newInst<='1'; wait for 2ns;WriteEn_i<="11";wait for 3ns;newInst<= '0'; wait for 5ns;
        wait;
    end process;

end RegFile_ALU_tb_arch;
