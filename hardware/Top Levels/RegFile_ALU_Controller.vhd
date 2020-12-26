
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegFile_ALU_Controller is
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
end RegFile_ALU_Controller;

architecture Behavioral of RegFile_ALU_Controller is

component Controller is
    generic (
        NB_LANES:integer:=2;
        lgNB_LANES:integer:=1;
        READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
        REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks          
        XLEN:integer:=32; --Register width
        VLEN:integer:=1024;
        ELEN: integer:=1024;
        lgELEN: integer:=10;
        lgVLEN:integer:=5
    );
    
    Port (
    ------------------------------------------------  
    ------------------------------------------------  
    -- INPUTS
    clk_in:in STD_LOGIC;
    busy: in STD_LOGIC; 
    rst: in STD_LOGIC;
    incoming_inst: in STD_LOGIC;   
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
    rd_data: out STD_LOGIC_VECTOR (XLEN-1 downto 0);  --to scalar slave register  
    WriteEn : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0); -- enables write to the reg file
    SrcB : out STD_LOGIC_VECTOR(2*NB_LANES-1 downto 0); -- selects between scalar/vector reg or immediate
                                                -- 00 = vector reg
                                                -- 01 = scalar reg
                                                -- 10 = immediate
                                                -- 11 = RESERVED
    MemWrite : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);                -- enables write to memory
    MemRead: out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);                  -- enables read from memory
    WBSrc : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);                    -- selects if wrbsc is from ALU or mem 
                                                -- 0 = ALU
                                                -- 1 = Mem    
    CSR_out: out STD_LOGIC_VECTOR (XLEN-1 downto 0);
    ---- 1) vtype fields:
    vill: out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
    vma:out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
    vta:out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
    vlmul: out STD_LOGIC_VECTOR(3*NB_LANES-1 downto 0);  
    sew: out STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);
    vstart: out STD_LOGIC_VECTOR(lgVLEN*NB_LANES-1 downto 0);
    vl: out STD_LOGIC_VECTOR(XLEN*NB_LANES-1 downto 0);      
    ------------------------------------------------------------------------
    funct6 : out STD_LOGIC_VECTOR (6*NB_LANES-1 downto 0);
    nf : out STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);
    mop: out STD_LOGIC_VECTOR (2*NB_LANES-1 downto 0);-- goes to memory lane
                                                          -- 00 if unit stride    
                                                          -- 01 reserved
                                                          -- 10 if strided 
                                                          -- 11 if indexed 
    vm : out STD_LOGIC;
    vs2_rs2 : out STD_LOGIC_VECTOR (4*NB_LANES-1 downto 0); -- 2nd vector operand
    rs1 : out STD_LOGIC_VECTOR (4*NB_LANES-1 downto 0); --1st vector operand
    RegSel: out STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); --going to RegFile_ALU
    WriteDest : out STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);--going to RegFile_ALU
    Xdata_in: in STD_LOGIC_VECTOR(XLEN-1 downto 0); --data coming from scalar register
    Xdata: out STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0); --data from scalar register, going to RegFile_ALU
    Idata: out STD_LOGIC_VECTOR(NB_LANES*5-1 downto 0); --data coming from immediate field of size 5 bits, going to RegFile_ALU
    funct3_width : out STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);
    vd_vs3 : out STD_LOGIC_VECTOR (4*NB_LANES-1 downto 0); --vector write destination  
    extension: out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);        -- goes to memory
                                                                 -- 0 if zero extended
                                                                 -- 1 if sign extended    
    memwidth: out STD_LOGIC_VECTOR(4*NB_LANES-1 downto 0);   -- goes to memory,FOLLOWS CUSTOM ENCODING: represents the exponent of the memory element width 
                                                             -- number of bits/transfer 
    newInst_out: out STD_LOGIC_VECTOR(NB_LANES-1 downto 0);                                                                                                                    
    NI_1: out STD_LOGIC;
    NI_2: out STD_LOGIC                                              
    );
end component;


component RegFile_ALU is
    generic (
           READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
           REG_NUM: integer:= 5; -- log (number of registers)
           REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks          
           NB_LANES:integer :=2;
           -- Max Vector Length (max number of elements) 
           ELEN: integer:=1024;
           lgELEN: integer:=10;
           XLEN:integer:=32; --Register width
           VLEN:integer:=1024; --number of bits in register
           lgVLEN:integer:=5
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
            sew: in STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);
            vlmul: in STD_LOGIC_VECTOR(3*NB_LANES-1 downto 0);
            vm: in STD_LOGIC;            
            vl: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
            vstart: in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);
            newInst: in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
            RegSel: in STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
            WriteDest : in STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
--            ld_RF: in STD_LOGIC; --mux select to fill RF
            o_done : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0) 
);
end component;

signal      Xdata_sig:  STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0); --data from scalar register
signal      Idata_sig:  STD_LOGIC_VECTOR(NB_LANES*5-1 downto 0); --data coming from immediate field of size 5 bits
signal      op2_src_sig:  STD_LOGIC_VECTOR(2*NB_LANES-1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 
signal      funct6_sig:  STD_LOGIC_VECTOR(NB_LANES*6-1 downto 0); --to know which operation
signal      funct3_sig:  STD_LOGIC_VECTOR (NB_LANES*3-1 downto 0); --to know which operation
signal      WriteEn_sig:  STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn from controller  
signal      sew_sig: STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);
signal      vm_sig: STD_LOGIC;
signal      vlmul_sig: STD_LOGIC_VECTOR(3*NB_LANES-1 downto 0);            
signal      vl_sig: STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
signal      vstart_sig:  STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);
signal      RegSel_sig:  STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
signal      WriteDest_sig:  STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
signal      newInst_out_sig: STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
begin

CONT: Controller GENERIC MAP(
                 NB_LANES=>NB_LANES,
                 lgNB_LANES=>lgNB_LANES,
                 READ_PORTS_PER_LANE=>READ_PORTS_PER_LANE,
                 REGS_PER_BANK=>REGS_PER_BANK,         
                 XLEN=>XLEN,
                 VLEN=>VLEN,
                 ELEN=>ELEN,
                 lgELEN=>lgELEN,
                 lgVLEN=>lgVLEN
                 )
                 PORT MAP (
                 clk_in=>clk_in,
                 busy=>busy, 
                 rst=>rst,
                 incoming_inst=>incoming_inst,  
                 vect_inst=>vect_inst,                  
                 CSR_Addr=>CSR_Addr,
                 CSR_WD=>CSR_WD,
                 CSR_WEN=>CSR_WEN,
                 CSR_REN=>CSR_REN,
                 rs1_data=>rs1_data,  
                 rs2_data=>rs2_data,   
                 rd_data=>rd_data,
                 WriteEn=>WriteEn_sig,
                 SrcB=>op2_src_sig,
                 MemWrite=>MemWrite,
                 MemRead=>MemRead,
                 WBSrc=>WBSrc,
                 CSR_out=>CSR_out,
                 vill=>vill,
                 vma=>vma,
                 vta=>vta,
                 vlmul=>vlmul_sig, 
                 sew=>sew_sig,
                 vstart=>vstart_sig,
                 vl=>vl_sig,      
                 funct6=>funct6_sig,
                 nf=>nf,
                 mop=>mop,
                 vm=>vm_sig,
                 vs2_rs2=>vs2_rs2,
                 rs1=>rs1,
                 RegSel=>RegSel_sig,
                 WriteDest=>WriteDest_sig,
                 Xdata_in=>Xdata_in,
                 Xdata=>Xdata_sig,
                 Idata=>Idata_sig,
                 funct3_width=>funct3_sig,
                 vd_vs3=>vd_vs3 ,
                 extension=>extension, 
                 memwidth=>memwidth,
                 newInst_out=>newInst_out_sig,                                                                                                                   
                 NI_1=>NI_1,
                 NI_2=>NI_2               
                   );
                 
REG_ALU:RegFile_ALU GENERIC MAP(
                    READ_PORTS_PER_LANE,
                    REG_NUM,
                    REGS_PER_BANK,
                    NB_LANES,
                    ELEN,
                    lgELEN,
                    XLEN,
                    VLEN,
                    lgVLEN
                    )
                    PORT MAP (
                    clk=>clk_in,
                    rst=>rst,
                    busy=>busy,
                    Xdata=>Xdata_sig,
                    Idata=>Idata_sig,
                    op2_src=>op2_src_sig,
                    funct6=>funct6_sig,
                    funct3=>funct3_sig,
                    WriteEn_i=>WriteEn_sig,          
                    sew=>sew_sig,
                    vlmul=>vlmul_sig,
                    vm=>vm_sig,   
                    vl=>vl_sig,
                    vstart=>vstart_sig,
                    newInst=>newInst_out_sig,
                    RegSel=>RegSel_sig,
                    WriteDest=>WriteDest_sig,
                    o_done=>o_done
                     );                 
sew<=sew_sig;
funct3_width<=funct3_sig;
vlmul<=vlmul_sig;
end Behavioral;
