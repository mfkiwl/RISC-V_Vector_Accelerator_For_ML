
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegFile_Controller is
  generic(
            XLEN:integer:=32; --Register width
            ELEN:integer:=32; --Maximum element width
            VLEN:integer:=32;
            SEW_MAX : natural range 1 to 1024 := 32;
            lgSEW_MAX: integer range 1 to 10:=5; 
            VLMAX: integer :=32;
            logVLMAX: integer := 5;
            RegNum: integer:= 5 
  );
  Port ( 
            i_clk : in std_logic;
            newInst: in STD_LOGIC;
            sew: in std_logic_vector (lgSEW_MAX-1 downto 0);
            o_done_1 : out std_logic; 
            o_done_2 : out std_logic;
            mask_bit: out STD_LOGIC;
            out1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
            out2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
            out3 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
            out4 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
            WriteData1 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
            WriteData2 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);            

            busy: in STD_LOGIC;   
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
            ------------------------------------------------------------------------
            funct6 : out STD_LOGIC_VECTOR (5 downto 0);
            nf : out STD_LOGIC_VECTOR (2 downto 0);
            mop : out STD_LOGIC_VECTOR (2 downto 0);
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
end RegFile_Controller;

architecture Behavioral of RegFile_Controller is

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

signal   sew_sig:  std_logic_vector (lgSEW_MAX-1 downto 0);
signal   vm_sig:  STD_LOGIC;
signal   vstart_sig: STD_LOGIC_VECTOR(XLEN-1 downto 0);
signal   RegSel1_sig : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal   RegSel2_sig : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal   RegSel3_sig : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal   RegSel4_sig : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal   vs2_rs2_sig :  STD_LOGIC_VECTOR (4 downto 0);
signal   vd_vs3_sig :  STD_LOGIC_VECTOR (4 downto 0);
signal   WriteEn_sig : STD_LOGIC;    
signal   WriteEn1_sig : STD_LOGIC;
signal   WriteEn2_sig : STD_LOGIC;
signal   WriteData1_sig : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal   WriteDest1_sig : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal   WriteData2_sig : STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
signal   WriteDest2_sig : STD_LOGIC_VECTOR (RegNum-1 downto 0);
signal   vl_sig:  STD_LOGIC_VECTOR(XLEN-1 downto 0);
begin

Reg_AddrGen: RegFile_AddrGen GENERIC MAP(SEW_MAX,lgSEW_MAX,VLEN,XLEN,VLMAX,RegNum)
                                 PORT MAP(i_clk,newInst,sew_sig,vm_sig,vstart_sig,o_done_1,o_done_2,mask_bit,
                                 out1,out2,out3,out4,
                                 RegSel1_sig,RegSel2_sig,RegSel3_sig,RegSel4_sig,
                                 WriteEn1_sig,WriteEn2_sig,
                                 WriteData1_sig,WriteDest1_sig,
                                 WriteData2_sig,WriteDest2_sig,
                                 vl_sig);
Cont: Controller GENERIC MAP (XLEN,ELEN,VLEN,SEW_MAX,lgSEW_MAX,VLMAX,logVLMAX)
                       PORT MAP(i_clk,busy,newInst,vect_inst,
                       CSR_Addr,CSR_WD,CSR_WEN,CSR_REN,
                       rs1_data,rs2_data,
                       rd_data,WriteEn_sig,SrcB,MemWrite,MemRead,WBSrc,CSR_out,
                       vill,vediv,vlmul,sew_sig,
                       vstart_sig,vl_sig,
                       funct6,nf,mop,vm_sig,vs2_rs2_sig,rs1,funct3_width,vd_vs3_sig,mv,extension,addrmode,memwidth,NI_1,NI_2);




end Behavioral;
