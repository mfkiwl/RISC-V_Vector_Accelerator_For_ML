library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegFile_ALU_Controller_tb is
--  Port ( );
end RegFile_ALU_Controller_tb;

architecture Behavioral of RegFile_ALU_Controller_tb is

constant    NB_LANES: integer:=2; --Number of lanes
constant    READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
constant    REG_NUM: integer:= 5; -- log (number of registers)
constant    REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks
constant    ELEN: integer:=32;
constant    lgELEN: integer:=10;
constant    XLEN:integer:=32; --Register width
constant    VLEN:integer:=32; --number of bits in register
constant    lgNB_LANES:integer:=1;
constant    lgVLEN:integer:=5;

component RegFile_ALU_Controller is
  generic(
    NB_LANES: integer:=2; --Number of lanes
    READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
    REG_NUM: integer:= 5; -- log (number of registers)
    REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks
    ELEN: integer:=1024;
    lgELEN: integer:=10;
    XLEN:integer:=32; --Register width
    VLEN:integer:=1024; --number of bits in register
    lgNB_LANES:integer:=1;
    lgVLEN:integer:=5
  );
  Port ( 
    clk_in:in STD_LOGIC;
    busy: in STD_LOGIC; 
    rst: in STD_LOGIC;
    incoming_inst: in STD_LOGIC;   
    Xdata_in: in STD_LOGIC_VECTOR(XLEN-1 downto 0); --data coming from scalar register
    vect_inst : in STD_LOGIC_VECTOR (31 downto 0);
    
    CSR_Addr: in STD_LOGIC_VECTOR ( 11 downto 0);   -- reg address of the CSR                 -- 11 is based on spec sheet
    CSR_WD: in STD_LOGIC_VECTOR (XLEN-1 downto 0); 
    CSR_WEN: in STD_LOGIC;
    CSR_REN: in STD_LOGIC;  
    rs1_data: in STD_LOGIC_VECTOR( XLEN-1 downto 0);  
    rs2_data: in STD_LOGIC_VECTOR(XLEN-1 downto 0); 
    rd_data: out STD_LOGIC_VECTOR (XLEN-1 downto 0);  --to scalar slave register            
    
    MemWrite : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);                -- enables write to memory
    MemRead: out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);                  -- enables read from memory
    WBSrc : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);                    -- selects if wrbsc is from ALU or mem 
                                                -- 0 = ALU
                                                -- 1 = Mem    
    CSR_out: out STD_LOGIC_VECTOR (XLEN-1 downto 0); 
    vill: out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
    vma:out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
    vta:out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
    vlmul: out STD_LOGIC_VECTOR(3*NB_LANES-1 downto 0);
    sew: out STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);      
    nf : out STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);
    mop: out STD_LOGIC_VECTOR (2*NB_LANES-1 downto 0);-- goes to memory lane
                                                          -- 00 if unit stride    
                                                          -- 01 reserved
                                                          -- 10 if strided 
                                                          -- 11 if indexed 
    vm : out STD_LOGIC;
    vs2_rs2 : out STD_LOGIC_VECTOR (4*NB_LANES-1 downto 0); -- 2nd vector operand
    rs1 : out STD_LOGIC_VECTOR (4*NB_LANES-1 downto 0); --1st vector operand
    funct3_width : out STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);
    vd_vs3 : out STD_LOGIC_VECTOR (4*NB_LANES-1 downto 0); --vector write destination  
    extension: out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);        -- goes to memory
                                                                 -- 0 if zero extended
                                                                 -- 1 if sign extended    
    memwidth: out STD_LOGIC_VECTOR(4*NB_LANES-1 downto 0);   -- goes to memory,FOLLOWS CUSTOM ENCODING: represents the exponent of the memory element width 
                                                          -- number of bits/transfer     
    o_done : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
    NI_1: out STD_LOGIC;
    NI_2: out STD_LOGIC                                                           
  );
end component;

signal    clk_in: STD_LOGIC;
signal    busy: STD_LOGIC; 
signal    rst: STD_LOGIC;
signal    incoming_inst:  STD_LOGIC;   
signal    Xdata_in: STD_LOGIC_VECTOR(XLEN-1 downto 0); --data coming from scalar register
signal    vect_inst :  STD_LOGIC_VECTOR (31 downto 0);
signal    CSR_Addr:  STD_LOGIC_VECTOR ( 11 downto 0);   -- reg address of the CSR                 -- 11 is based on spec sheet
signal    CSR_WD:  STD_LOGIC_VECTOR (XLEN-1 downto 0); 
signal    CSR_WEN:  STD_LOGIC;
signal    CSR_REN:  STD_LOGIC;  
signal    rs1_data:  STD_LOGIC_VECTOR( XLEN-1 downto 0);  
signal    rs2_data: STD_LOGIC_VECTOR(XLEN-1 downto 0); 
signal    rd_data:  STD_LOGIC_VECTOR (XLEN-1 downto 0);  --to scalar slave register            
signal    MemWrite :  STD_LOGIC_VECTOR(NB_LANES-1 downto 0);                -- enables write to memory
signal    MemRead:  STD_LOGIC_VECTOR(NB_LANES-1 downto 0);                  -- enables read from memory
signal    WBSrc :  STD_LOGIC_VECTOR(NB_LANES-1 downto 0);                    -- selects if wrbsc is from ALU or mem 
signal    CSR_out:  STD_LOGIC_VECTOR (XLEN-1 downto 0); 
signal    vill:  STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
signal    vma:STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
signal    vta: STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
signal    vlmul: STD_LOGIC_VECTOR(3*NB_LANES-1 downto 0);  
signal    sew_t:  STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);    
signal    nf :  STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);
signal    mop:  STD_LOGIC_VECTOR (2*NB_LANES-1 downto 0);-- goes to memory lane
signal    vm :  STD_LOGIC;
signal    vs2_rs2 :  STD_LOGIC_VECTOR (4*NB_LANES-1 downto 0); -- 2nd vector operand
signal    rs1 :  STD_LOGIC_VECTOR (4*NB_LANES-1 downto 0); --1st vector operand
signal    funct3_width :  STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);
signal    vd_vs3 :  STD_LOGIC_VECTOR (4*NB_LANES-1 downto 0); --vector write destination  
signal    extension: STD_LOGIC_VECTOR(NB_LANES-1 downto 0);        -- goes to memory
signal    memwidth: STD_LOGIC_VECTOR(4*NB_LANES-1 downto 0);   -- goes to memory,FOLLOWS CUSTOM ENCODING: represents the exponent of the memory element width  
signal    o_done : STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
signal    NI_1:  STD_LOGIC;
signal    NI_2:  STD_LOGIC;

begin

UUT: RegFile_ALU_Controller GENERIC MAP(
                            NB_LANES=>NB_LANES,
                            READ_PORTS_PER_LANE=>READ_PORTS_PER_LANE,           
                            REG_NUM=>REG_NUM,
                            REGS_PER_BANK=>REGS_PER_BANK,
                            ELEN=>ELEN,
                            lgELEN=>lgELEN,
                            XLEN=>XLEN,
                            VLEN=>VLEN,
                            lgNB_LANES=>lgNB_LANES,
                            lgVLEN=>lgVLEN
                            )
                            PORT MAP (
                            clk_in=>clk_in,
                            busy=>busy, 
                            rst=>rst,
                            incoming_inst=>incoming_inst, 
                            Xdata_in=>Xdata_in,
                            vect_inst=>vect_inst,
                            CSR_Addr=>CSR_Addr,
                            CSR_WD=>CSR_WD,
                            CSR_WEN=>CSR_WEN,
                            CSR_REN=>CSR_REN, 
                            rs1_data=>rs1_data,
                            rs2_data=>rs2_data, 
                            rd_data=>rd_data,          
                            MemWrite=>MemWrite,
                            MemRead=>MemRead,
                            WBSrc=>WBSrc, 
                            CSR_out=>CSR_out,
                            vill=>vill,
                            vma=>vma,
                            vta=>vta,
                            vlmul=>vlmul,
                            sew=>sew_t,  
                            nf=>nf,
                            mop=>mop,
                            vm=>vm,
                            vs2_rs2=>vs2_rs2,
                            rs1=>rs1,
                            funct3_width=>funct3_width,
                            vd_vs3=>vd_vs3,
                            extension=>extension,
                            memwidth=>memwidth,
                            o_done=>o_done,
                            NI_1=>NI_1,
                            NI_2=>NI_2                                                                                                                                                                                     
                            );
                            
    clk_proc: process begin
        clk_in<='0';
        wait for 5ns;
        clk_in<='1'; 
        wait for 5ns;
    end process;
    
    process begin                            
        incoming_inst<='0';busy<='0';rst<='0'; wait for 5 ns; rst<='1'; wait for 5ns;rst<='0';wait for 5 ns;
        --set vstart as 0
        CSR_Addr<=x"008"; CSR_WD<=x"00000000"; CSR_WEN<='1'; wait for 10ns;
        CSR_WEN<='0';
        --vsetvli configuration instruction
        incoming_inst<='1';
        vect_inst<="00000000000000000111000011010111";
        wait for 5 ns;
        incoming_inst<='0';
        wait for 15ns;
--        -- move instruction to fill v0 register
        incoming_inst<='1'; 
        Xdata_in<=x"00000001";
        vect_inst<="01011110000000000100000001010111";
        wait for 5 ns; incoming_inst<='0';  
        wait for 5ns;
        --move instruction to fill v16 register
        incoming_inst<='1'; 
        Xdata_in<=x"00000002";
        vect_inst<="01011111010010000100100001010111";
        wait for 5 ns; incoming_inst<='0'; 
        -- move instruction to fill v0 register
--        wait for 5ns;
--        incoming_inst<='1'; 
--        Xdata_in<=x"00000001";
--        vect_inst<="01011110000000000100000001010111";
--        wait for 5 ns; incoming_inst<='0';               
        wait;
    end process;
end Behavioral;
