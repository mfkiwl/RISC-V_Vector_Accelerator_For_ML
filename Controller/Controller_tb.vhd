library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Controller_tb is
--  Port ( );
end Controller_tb;

architecture Behavioral of Controller_tb is

constant        XLEN:integer:=32; --Register width
constant        ELEN:integer:=32; --Maximum element width
constant        VLEN:integer:=32;
constant        SEW_MAX:integer:=32;
constant        lgSEW_MAX:integer:=5;
constant        VLMAX: integer :=32;
constant        logVLMAX: integer := 5;

component Controller is

    generic (
        XLEN:integer:=32; --Register width
        ELEN:integer:=32; --Maximum element width
        VLEN:integer:=32;
        SEW_MAX: integer:=32;
        lgSEW_MAX: integer:=5;
        VLMAX: integer :=32;
        logVLMAX: integer := 5
    );
    
    Port (
    ------------------------------------------------  
    ------------------------------------------------  
    -- INPUTS
    clk_in:in STD_LOGIC;
    busy: in STD_LOGIC; 
    newInst: in STD_LOGIC;   
    ------------------------------------------------  
    vect_inst : in STD_LOGIC_VECTOR (31 downto 0);
    
    CSR_Addr: in STD_LOGIC_VECTOR ( 11 downto 0);   -- reg address of the CSR                 -- 11 is based on spec sheet
    CSR_WD: in STD_LOGIC_VECTOR (XLEN-1 downto 0); 
    CSR_WEN: in STD_LOGIC;
    CSR_REN: in STD_LOGIC;  
    rs1_data: in STD_LOGIC_VECTOR( XLEN-1 downto 0);  
    rs2_data: in STD_LOGIC_VECTOR(XLEN-1 downto 0); 
    ------------------------------------------------   
    ------------------------------------------------      
    -- OUTPUTS  
    rd_data: out STD_LOGIC_VECTOR (VLMAX-1 downto 0);    
    WriteEn : out STD_LOGIC; -- enables write to the reg file
    SrcB : out STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate
                                                -- 00 = vector reg
                                                -- 01 = scalar reg
                                                -- 10 = immediate
                                                -- 00 = ??
    MemWrite : out STD_LOGIC;                -- enables write to memory
    MemRead: out STD_LOGIC;                  -- enables read from memory
    WBSrc : out STD_LOGIC;                    -- selects if wrbsc is from ALU or mem 
                                                -- 0 = ALU
                                                -- 1 = Mem    
    CSR_out: out STD_LOGIC_VECTOR (XLEN-1 downto 0);
    ---- 1) vtype fields:
    vill: out STD_LOGIC;
    vediv:out STD_LOGIC_VECTOR (1 downto 0);
    vlmul: out STD_LOGIC_VECTOR(1 downto 0);  
    sew: out STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
    vstart: out STD_LOGIC_VECTOR(XLEN-1 downto 0);
    vl: out STD_LOGIC_VECTOR(XLEN-1 downto 0);      
    ------------------------------------------------------------------------
    funct6 : out STD_LOGIC_VECTOR (5 downto 0);
    nf : out STD_LOGIC_VECTOR (2 downto 0);
    mop : out STD_LOGIC_VECTOR (2 downto 0);
    vm : out STD_LOGIC;
    vs2_rs2 : out STD_LOGIC_VECTOR (4 downto 0);
    rs1 : out STD_LOGIC_VECTOR (4 downto 0);
    funct3_width : out STD_LOGIC_VECTOR (2 downto 0);
    vd_vs3 : out STD_LOGIC_VECTOR (4 downto 0);
    mv: out STD_LOGIC;   
    extension: out STD_LOGIC;        -- goes to memory
                                        -- 0 if zero extended
                                        -- 1 if sign extended    
    addrmode: out STD_LOGIC_VECTOR(1 downto 0); -- goes to memory lane
                                                          -- 00 if unit stride    
                                                          -- 01 if strided
                                                          -- 10 if indexed (unordered in case of a store)
                                                          -- 11 if indexed (ordered in case of a store)
    memwidth: out STD_LOGIC_VECTOR(lgSEW_MAX downto 0); -- goes to memory 
                                                                 -- number of bits/transfer    
    NI_1: out STD_LOGIC;
    NI_2: out STD_LOGIC                                              
    );
end component;


--Signals 

 signal         clk_in: STD_LOGIC;
 signal         busy:  STD_LOGIC;
 signal         newInst: STD_LOGIC;
           --------------------------------------------
 signal         vect_inst: STD_LOGIC_VECTOR(31 downto 0);     
           --Control Registers INPUT:
 signal         CSR_Addr:  STD_LOGIC_VECTOR (11 downto 0);   -- reg address of the CSR                                                           -- 11 is based on spec sheet
 signal         CSR_WD:  STD_LOGIC_VECTOR (XLEN-1 downto 0);
 signal         CSR_WEN: STD_LOGIC;
 signal         CSR_REN: STD_LOGIC; 
            -- vset Related Signals:
 signal         rs1_data: STD_LOGIC_VECTOR(XLEN-1 downto 0);
 signal         rs2_data: STD_LOGIC_VECTOR(XLEN-1 downto 0); 
 signal         rd_data:  STD_LOGIC_VECTOR (VLMAX-1 downto 0);
           --------------------------------------------
           --------------------------------------------
           --Control Signals OUTPUT:
 signal         WriteEn :  STD_LOGIC; -- enables write to the reg file
 signal         SrcB :  STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate
                                 -- 00 = vector reg
                                 -- 01 = scalar reg
                                 -- 10 = immediate
                                 -- 00 = ??
 signal         MemWrite :  STD_LOGIC;-- enables write to memory
 signal         MemRead:  STD_LOGIC; -- enables read from memory
 signal         WBSrc :  STD_LOGIC;-- selects if wrbsc is from ALU or mem 
                                     -- 0 = ALU
                                     -- 1 = Mem
           --------------------------------------------
           
           --Control Registers OUTPUT:
 signal         CSR_out:  STD_LOGIC_VECTOR (XLEN-1 downto 0);
           ---- 1) vtype fields:
 signal         vill:  STD_LOGIC;
 signal         vediv: STD_LOGIC_VECTOR (1 downto 0);
 signal         vlmul:  STD_LOGIC_VECTOR(1 downto 0);  
 signal         sew:  STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
 -------------------------------------------------------------
 signal         vstart: STD_LOGIC_VECTOR(XLEN-1 downto 0);
 signal         vl: STD_LOGIC_VECTOR(XLEN-1 downto 0);    
 -------------------------------------------------------------  
 signal         funct6 : STD_LOGIC_VECTOR (5 downto 0);
 signal         nf :  STD_LOGIC_VECTOR (2 downto 0);
 signal         mop : STD_LOGIC_VECTOR (2 downto 0);
 signal         vm :  STD_LOGIC;
 signal         vs2_rs2 : STD_LOGIC_VECTOR (4 downto 0);
 signal         rs1 :  STD_LOGIC_VECTOR (4 downto 0);
 signal         funct3_width : STD_LOGIC_VECTOR (2 downto 0);
 signal         vd_vs3 : STD_LOGIC_VECTOR (4 downto 0);
 signal         mv: STD_LOGIC;   
 signal         extension: STD_LOGIC;        -- goes to memory
                                             -- 0 if zero extended
                                             -- 1 if sign extended    
 signal         addrmode: STD_LOGIC_VECTOR(1 downto 0); -- goes to memory lane
                                                        -- 00 if unit stride    
                                                        -- 01 if strided
                                                        -- 10 if indexed (unordered in case of a store)
                                                        -- 11 if indexed (ordered in case of a store)
 signal         memwidth: STD_LOGIC_VECTOR(lgSEW_MAX downto 0); -- goes to memory 
                                                                -- number of bits/transfer    
 signal         NI_1: STD_LOGIC;
 signal         NI_2: STD_LOGIC; 
begin

    G1: Controller
    GENERIC MAP(XLEN,ELEN,VLEN,SEW_MAX,lgSEW_MAX,VLMAX,logVLMAX)
    PORT MAP(clk_in,busy, newInst, vect_inst,
     CSR_ADDR, CSR_WD, CSR_WEN, CSR_REN,
     rs1_data, rs2_data, rd_data, WriteEn, SrcB, MemWrite, MemRead, WBSrc,
     CSR_out, vill, vediv, vlmul, sew, vstart, vl, 
     funct6, nf, mop, vm, vs2_rs2, rs1, funct3_width, vd_vs3,
     mv,extension,addrmode,memwidth,
     NI_1, NI_2);
     
    clk_proc: process begin
        clk_in<='1';
        wait for 20ns;
        clk_in<='0'; 
        wait for 20ns;
    end process;

    process begin
        busy<= '0'; CSR_REN<='0'; CSR_WEN<='0'; wait for 80ns;    
        -- Case 1: Writing and reading to the CSRs
        CSR_Addr<=x"008"; CSR_WD<=x"00000001"; CSR_WEN<='1'; wait for 80ns;
        CSR_WEN<='0'; CSR_REN<='1'; CSR_Addr<=x"008"; wait for 80ns; 
        -- Case 2: Testing an ALU instruction
        CSR_REN<='0'; vect_inst<="00000000000000000011000001010111"; 
        newInst<= '1'; wait for 10ns; newInst<='0'; wait for 110ns; newInst<='1'; wait for 10ns; newInst<='0'; --testing newInst
        wait;
    end process;

end Behavioral;
