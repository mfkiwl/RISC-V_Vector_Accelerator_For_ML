library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity Controller is
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
end Controller;

architecture Controller_arch of Controller is

component Control_Unit is
    generic (
        XLEN:integer:=32; --Register width
        VLEN:integer:=1024;
        ELEN: integer:=1024;
        lgELEN: integer:=10;
        lgVLEN:integer:=5

    );

    Port ( 
           --FORMAT USED: A set of inputs followed by their respective output ports:
           
           --Clock, Busy and newInst Signals INPUT:
           clk_in:in STD_LOGIC;
           busy: in STD_LOGIC; --might not need it currently. Needed for later improvements
           newInst: in STD_LOGIC; --signals that a new instruction came. Might be set internally based on the instruction changing.
           --------------------------------------------
           --------------------------------------------
           --Control Registers INPUT:
           CSR_Addr: in STD_LOGIC_VECTOR ( 11 downto 0);   -- reg address of the CSR
                                                           -- 11 is based on spec sheet (0xABC)
           CSR_WD: in STD_LOGIC_VECTOR (XLEN-1 downto 0);
           CSR_WEN: in STD_LOGIC; --for testing purposes to write to CSRs
           CSR_REN: in STD_LOGIC; --for testing purposes to read from CSRs
           --------------------------------------------
           --Control Registers OUTPUT:
           CSR_out: out STD_LOGIC_VECTOR (XLEN-1 downto 0);
           ---- 1) vtype fields:
           cu_vill: out STD_LOGIC;
           cu_vma:out STD_LOGIC;
           cu_vta:out STD_LOGIC;
           cu_vlmul: out STD_LOGIC_VECTOR(2 downto 0);  
           cu_sew: out STD_LOGIC_VECTOR (2 downto 0); 
           --- 2) vlenb fields:
           --vlenb has no fields; it is a read only register of value VLEN/8
           
           --- 3) vstart fields:
           --vstart specifies the index of the first element to be executed by an instruction
           cu_vstart: out STD_LOGIC_VECTOR(lgVLEN-1 downto 0);
           --- 4) vl fields:   

           cu_vl: out STD_LOGIC_VECTOR(XLEN-1 downto 0);      
           --vl has no fields; it is a read only register that holds the number of elements to be updated by an instruction
           --------------------------------------------
           --------------------------------------------
           -- Fields INPUT: (from decoder)
           cu_funct3:in STD_LOGIC_VECTOR(2 downto 0);
           cu_rs1: in STD_LOGIC_VECTOR(4 downto 0);
           cu_rs2: in STD_LOGIC_VECTOR(4 downto 0);
           cu_rd:  in STD_LOGIC_VECTOR(4 downto 0);
           cu_opcode : in STD_LOGIC_VECTOR (6 downto 0);
           cu_mew: in STD_LOGIC;
           cu_mop : in STD_LOGIC_VECTOR (1 downto 0);-- goes to memory lane
                                                          -- 00 if unit stride    
                                                          -- 01 reserved
                                                          -- 10 if strided 
                                                          -- 11 if indexed 
           cu_bit31: in STD_LOGIC; --used for vsetvl and vsetvli instructions
           cu_zimm: in STD_LOGIC_VECTOR(10 downto 0);
           --------------------------------------------
           -- vset Related Signals:
           cu_rs1_data: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           cu_rs2_data: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           cu_rd_data: out STD_LOGIC_VECTOR (XLEN-1 downto 0);
           --------------------------------------------
           --Control Signals OUTPUT:
           cu_WriteEn : out STD_LOGIC; -- enables write to the reg file
           cu_SrcB : out STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate
                                    -- 00 = vector reg
                                    -- 01 = scalar reg
                                    -- 10 = immediate
                                    -- 00 = ??
           cu_MemWrite : out STD_LOGIC;-- enables write to memory
           cu_MemRead: out STD_LOGIC; -- enables read from memory
           cu_WBSrc : out STD_LOGIC;-- selects if wrbsc is from ALU or mem 
                                     -- 0 = ALU
                                     -- 1 = Mem
           cu_extension: out STD_LOGIC; -- goes to memory
                                        -- 0 if zero extended
                                        -- 1 if sign extended    
           cu_memwidth: out STD_LOGIC_VECTOR(3 downto 0); -- goes to memory 
                                                                 -- number of bits/transfer   
           cu_NI_1: out STD_LOGIC; --new instruction on Lane 1
           cu_NI_2: out STD_LOGIC --new instruction on Lane 2
           --------------------------------------------
           );
end component;

component Decoder is
    Port ( d_vect_inst : in STD_LOGIC_VECTOR (31 downto 0);
           -- Instruction Fields:
           d_funct6 : out STD_LOGIC_VECTOR (5 downto 0);
           d_bit31: out STD_LOGIC; -- used for vsetvl/vsetvli instructions
           d_nf : out STD_LOGIC_VECTOR (2 downto 0);
           d_zimm: out STD_LOGIC_VECTOR(10 downto 0);
           d_mew : out STD_LOGIC;
           d_mop : out STD_LOGIC_VECTOR (1 downto 0);
           d_vm : out STD_LOGIC;
           d_vs2_rs2 : out STD_LOGIC_VECTOR (4 downto 0);
           d_rs1 : out STD_LOGIC_VECTOR (4 downto 0);
           d_funct3_width : out STD_LOGIC_VECTOR (2 downto 0);
           d_vd_vs3 : out STD_LOGIC_VECTOR (4 downto 0);
           d_opcode : out STD_LOGIC_VECTOR (6 downto 0)
           );
end component;


--Signals 
           -- Fields INPUT: (from decoder)
 signal    funct3_sig: STD_LOGIC_VECTOR(2 downto 0);
 signal    mew_sig:  STD_LOGIC; 
 signal    mop_sig: STD_LOGIC_VECTOR(1 downto 0);
 signal    nf_sig: STD_LOGIC_VECTOR(2 downto 0);
 signal    funct6_sig: STD_LOGIC_VECTOR(5 downto 0);
 signal    rs1_sig:  STD_LOGIC_VECTOR(4 downto 0);
 signal    rs2_sig:  STD_LOGIC_VECTOR(4 downto 0);
 signal    rd_sig:   STD_LOGIC_VECTOR(4 downto 0);
 signal    opcode_sig :  STD_LOGIC_VECTOR (6 downto 0);
 signal    bit31_sig:  STD_LOGIC; 
 signal    zimm_sig: STD_LOGIC_VECTOR(10 downto 0);
 signal    vill_sig: STD_LOGIC; 
 signal    vma_sig: STD_LOGIC;
 signal    vta_sig: STD_LOGIC;
 signal    vlmul_sig: STD_LOGIC_VECTOR(2 downto 0);
 signal    sew_sig: STD_LOGIC_VECTOR(2 downto 0);
 signal    vstart_sig: STD_LOGIC_VECTOR(lgVLEN-1 downto 0);
 signal    vl_sig: STD_LOGIC_VECTOR(XLEN-1 downto 0);
 signal    WriteEn_sig: STD_LOGIC;
 signal    SrcB_sig: STD_LOGIC_VECTOR(1 downto 0);
 signal    MemWrite_sig: STD_LOGIC;
 signal    MemRead_sig: STD_LOGIC;
 signal    WBSrc_sig: STD_LOGIC;
 signal    extension_sig: STD_LOGIC;
 signal    memwidth_sig: STD_LOGIC_VECTOR(3 downto 0);
 signal    lane_idx:integer:=0;
 signal    test:STD_LOGIC_VECTOR(XLEN*NB_LANES-1 downto 0);

 signal    newInst_sig:std_logic; --signal asserted by newInstGen process due to incoming vector instruction
 signal    RegSel_sig:STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0);   
 signal    Xdata_pipeline: STD_LOGIC_VECTOR(XLEN-1 downto 0);
 signal    funct3_pipeline: STD_LOGIC_VECTOR(2 downto 0);
 signal    mew_pipeline:  STD_LOGIC; 
 signal    mop_pipeline: STD_LOGIC_VECTOR(1 downto 0);
 signal    nf_pipeline: STD_LOGIC_VECTOR(2 downto 0);
 signal    funct6_pipeline: STD_LOGIC_VECTOR(5 downto 0);
 signal    rs1_pipeline:  STD_LOGIC_VECTOR(4 downto 0);
 signal    rs2_pipeline:  STD_LOGIC_VECTOR(4 downto 0);
 signal    rd_pipeline:   STD_LOGIC_VECTOR(4 downto 0);
 signal    opcode_pipeline :  STD_LOGIC_VECTOR (6 downto 0);
 signal    bit31_pipeline:  STD_LOGIC; 
 signal    zimm_pipeline: STD_LOGIC_VECTOR(10 downto 0);
 signal    vill_pipeline: STD_LOGIC; 
 signal    vma_pipeline: STD_LOGIC;
 signal    vta_pipeline: STD_LOGIC;
 signal    vlmul_pipeline: STD_LOGIC_VECTOR(2 downto 0);
 signal    sew_pipeline: STD_LOGIC_VECTOR(2 downto 0);
 signal    vstart_pipeline: STD_LOGIC_VECTOR(lgVLEN-1 downto 0);
 signal    vl_pipeline: STD_LOGIC_VECTOR(XLEN-1 downto 0);
 signal    WriteEn_pipeline: STD_LOGIC;
 signal    SrcB_pipeline: STD_LOGIC_VECTOR(1 downto 0);
 signal    MemWrite_pipeline: STD_LOGIC;
 signal    MemRead_pipeline: STD_LOGIC;
 signal    WBSrc_pipeline: STD_LOGIC;
 signal    extension_pipeline: STD_LOGIC;
 signal    memwidth_pipeline: STD_LOGIC_VECTOR(3 downto 0);
 signal    newInst_pipeline:std_logic; --signal asserted by newInstGen process due to incoming vector instruction
 signal    vm_sig: std_logic;
 signal    vm_pipeline:std_logic;
 
 type States is (RESET,TRIGGER); 
 signal    NS : States ;
 signal    CS : States ;
begin

Dec: Decoder PORT MAP (d_vect_inst=>vect_inst,
                       d_funct6=>funct6_sig,
                       d_bit31=>bit31_sig,
                       d_nf=>nf_sig,
                       d_zimm=>zimm_sig,
                       d_mew=>mew_sig,
                       d_mop=>mop_sig,
                       d_vm=>vm_sig,
                       d_vs2_rs2=>rs2_sig,
                       d_rs1=>rs1_sig,
                       d_funct3_width=>funct3_sig,
                       d_vd_vs3=>rd_sig,
                       d_opcode=>opcode_sig
                       );

CU:  Control_Unit 
GENERIC MAP(        
          XLEN=>XLEN,
          VLEN=>VLEN,
          ELEN=>ELEN,
          lgELEN=>lgELEN,
          lgVLEN=>lgVLEN
          )
PORT MAP (clk_in=>clk_in,
          busy=>busy,
          newInst=>newInst_sig,
          CSR_Addr=>CSR_Addr,
          CSR_WD=>CSR_WD,
          CSR_WEN=> CSR_WEN, 
          CSR_REN=>CSR_REN,
          CSR_out=>CSR_out,
          cu_vill=>vill_sig,
          cu_vma=>vma_sig,
          cu_vta=>vta_sig,
          cu_vlmul=>vlmul_sig,
          cu_sew=>sew_sig,
          cu_vstart=>vstart_sig,
          cu_vl=>vl_sig,
          cu_funct3=>funct3_sig,
          cu_rs1=>rs1_sig,
          cu_rs2=>rs2_sig,
          cu_rd=>rd_sig,
          cu_opcode=>opcode_sig,
          cu_mew=>mew_sig,
          cu_mop=>mop_sig,
          cu_bit31=>bit31_sig,
          cu_zimm=>zimm_sig,
          cu_rs1_data=> rs1_data, 
          cu_rs2_data=> rs2_data, 
          cu_rd_data=>rd_data,
          cu_WriteEn=>WriteEn_sig,
          cu_SrcB=>SrcB_sig,
          cu_MemWrite=>MemWrite_sig,
          cu_MemRead=>MemRead_sig,
          cu_WBSrc=>WBSrc_sig,
          cu_extension=>extension_sig,
          cu_memwidth=>memwidth_sig,
          cu_NI_1=> NI_1, 
          cu_NI_2=>NI_2);

  
  newInstGen:process (incoming_inst,clk_in)
    variable NI_set: std_logic:='0';
  begin

    if rising_edge (clk_in) then
        if NI_set='1' then 
            newInst_sig<='0';
            NI_set:= '0';
        end if;
        if rising_edge(incoming_inst) and NI_set='0' then
            newInst_sig<='1';
            NI_set:='1';
        end if; 
    end if;

end process;
--newInst_sig<='1' when state='1' else
--   '0' when state='0';


PIPELINE:process(clk_in,Xdata_in,newInst_sig,vstart_sig,vl_sig)
begin
    if (rising_edge(clk_in)) then
        Xdata_pipeline<=Xdata_in;
        vl_pipeline<=vl_sig;
        --newInst_out(lane_idx)<= newInst_sig;
        newInst_pipeline<=newInst_sig;
        vstart_pipeline<=vstart_sig;
        vm_pipeline<=vm_sig;
        rd_pipeline<= rd_sig;
    end if;
end process;

lane_idx<=to_integer(unsigned(rd_pipeline(4 downto 4-(lgNB_LANES-1)))); --lane_idx specifies the index of the bank/lane we are using

-- Process to pick the lane based on MSB of rd_sig. This works under the assumption that we can only read and write to the same bank
LANE_PICKER:process(clk_in,newInst_pipeline,lane_idx,vill_sig,vma_sig,vta_sig,vlmul_sig,sew_sig,vstart_sig,nf_sig,mop_sig,vl_sig,funct3_sig,funct6_sig,rs1_sig,rs2_sig,WriteEn_sig,SrcB_sig,MemWrite_sig,MemRead_sig,WBSrc_sig,extension_sig,memwidth_sig,Xdata_in) 
begin
    
--    if newInst_sig='1' then
--       newInst_out(NB_LANES-1 downto lane_idx+1)<=(others=>'0');
--       newInst_out(lane_idx)<='1';
--       newInst_out(lane_idx-1 downto 0)<=(others=>'0');
--    elsif newInst_sig='0' then
--       newInst_out<=(others=>'0');
--    end if;
        
    if(rising_edge(clk_in)) then
        newInst_out(lane_idx)<=newInst_pipeline;
        vm<=vm_sig;
        vill(lane_idx)<=vill_sig;
        vma(lane_idx)<=vma_sig;
        vta(lane_idx)<=vta_sig;
        vlmul(3*(lane_idx+1)-1 downto 3*lane_idx)<=vlmul_sig; 
        sew(3*(lane_idx+1)-1 downto 3*lane_idx)<=sew_sig;
        vstart(lgVLEN*(lane_idx+1)-1 downto lgVLEN*lane_idx)<=vstart_pipeline; 
        nf(3*(lane_idx+1)-1 downto 3*lane_idx)<=nf_sig;
        mop(2*(lane_idx+1)-1 downto 2*lane_idx)<=mop_sig;
        vl(XLEN*(lane_idx+1)-1 downto XLEN*lane_idx)<=vl_pipeline;  
        funct3_width(3*(lane_idx+1)-1 downto 3*lane_idx)<=funct3_sig; 
        
        funct6(6*(lane_idx+1)-1 downto 6*lane_idx)<=funct6_sig;    
        rs1((4-(lgNB_LANES-1))*(lane_idx+1)-1 downto (4-(lgNB_LANES-1))*lane_idx)<=rs1_sig(4-(lgNB_LANES-1)-1 downto 0);
        vs2_rs2((4-(lgNB_LANES-1))*(lane_idx+1)-1 downto (4-(lgNB_LANES-1))*lane_idx)<=rs2_sig(4-(lgNB_LANES-1)-1 downto 0);
        vd_vs3((4-(lgNB_LANES-1))*(lane_idx+1)-1 downto (4-(lgNB_LANES-1))*lane_idx)<=rd_pipeline(4-(lgNB_LANES-1)-1 downto 0); 
        
        RegSel(2*(4-(lgNB_LANES-1))*(lane_idx+1)-1 downto 2*(4-(lgNB_LANES-1))*lane_idx)<=rs2_sig(4-(lgNB_LANES-1)-1 downto 0)&rs1_sig(4-(lgNB_LANES-1)-1 downto 0);
        Xdata(XLEN*(lane_idx+1)-1 downto XLEN*lane_idx)<=Xdata_pipeline;
        WriteDest((4-(lgNB_LANES-1))*(lane_idx+1)-1 downto (4-(lgNB_LANES-1))*lane_idx)<=rd_sig(4-(lgNB_LANES-1)-1 downto 0); 
        WriteEn(lane_idx)<=WriteEn_sig;
        MemWrite(lane_idx)<=MemWrite_sig;
        SrcB(2*(lane_idx+1)-1 downto 2*lane_idx)<=SrcB_sig;
        MemRead(lane_idx)<=MemRead_sig;
        WBSrc(lane_idx)<=WBSrc_sig;
        extension(lane_idx)<=extension_sig;
        memwidth(4*(lane_idx+1)-1 downto 4*lane_idx)<=memwidth_sig;
        Idata(5*(lane_idx+1)-1 downto 5*lane_idx)<=rs1_sig;
    end if;

end process; 


end Controller_arch;
