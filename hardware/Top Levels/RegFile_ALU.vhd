library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegFile_ALU is
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
end RegFile_ALU;

architecture Structural of RegFile_ALU is

component ALU_with_pipeline is
    generic(
           NB_LANES: integer:=2; --Number of lanes            
           ELEN: integer:=1024;
           lgELEN: integer:=10;
           XLEN:integer:=32; --Register width
           VLEN:integer:=1024; --number of bits in register
           lgVLEN:integer:=10
           );
    Port (  clk: in STD_LOGIC; 
            rst: in STD_LOGIC;
            busy: in STD_LOGIC;
            mask_in: in STD_LOGIC;
            Xdata: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0); --data from scalar register
            Vdata: in STD_LOGIC_VECTOR(2*NB_LANES*ELEN-1 downto 0); --data coming from Register File, 2 since we always have 2 operands
            Idata: in STD_LOGIC_VECTOR(NB_LANES*5-1 downto 0); --data coming from immediate field of size 5 bits
            op2_src: in STD_LOGIC_VECTOR(2*NB_LANES-1 downto 0); -- selects between scalar/vector reg or immediate from operand 2 
                                                -- 00 = vector reg
                                                -- 01 = scalar reg
                                                -- 10 = immediate
                                                -- 11 = RESERVED (unbound)
            funct6: in STD_LOGIC_VECTOR(NB_LANES*6-1 downto 0); --to know which operation
            funct3: in STD_LOGIC_VECTOR (NB_LANES*3-1 downto 0); --to know which operation
            WriteEn_i: in STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn from controller
            WriteEn_o: out STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn out to Register File
            result: out STD_LOGIC_VECTOR(NB_LANES*ELEN-1 downto 0); --result vector
            w_offset_in : in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);--offset coming from the pipeline
            w_offset_out : out STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0) --offset going to pipeline
            );
end component;

component RegFile_OffsetGen is
    generic (
           NB_LANES: integer:=2; --Number of lanes
           READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
           REG_NUM: integer:= 5; -- log (number of registers)
           REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks
           ELEN: integer:=1024;
           lgELEN: integer:=10;
           XLEN:integer:=32; --Register width
           VLEN:integer:=1024; --number of bits in register
           lgVLEN:integer:=5
    );
    Port (
            i_clk : in std_logic;
            newInst: in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
            sew: in std_logic_vector (3*NB_LANES-1 downto 0);
            vm: in STD_LOGIC;
            vstart: in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);
            vlmul: in STD_LOGIC_VECTOR(3*NB_LANES-1 downto 0);             
            o_done : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0); 
            mask_bit: out STD_LOGIC;
            OutPort: out STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*ELEN)-1 downto 0);
            RegSel: in STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
            WriteEn : in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
            WriteData : in STD_LOGIC_VECTOR (NB_LANES*ELEN-1 downto 0);
            WriteDest : in STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
            w_offset_in : in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);--offset coming from the pipeline
            w_offset_out : out STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0); --offset going to pipeline
            vl: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0)
  );
end component;


signal     s_OutPort: STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*ELEN)-1 downto 0);
signal     s_WriteEn_o: STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
signal     s_result: STD_LOGIC_VECTOR(NB_LANES*ELEN-1 downto 0);
signal     s_mask_bit: STD_LOGIC;
signal     w_offset_in_sig :  STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);--offset coming from the pipeline
signal     w_offset_out_sig :  STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0); --offset going to pipeline
--signal     RF_wd_mux_1: STD_LOGIC_VECTOR(ELEN-1 downto 0);
--signal     RF_wd_mux_2: STD_LOGIC_VECTOR(ELEN-1 downto 0);

begin


RF: RegFile_OffsetGen GENERIC MAP(NB_LANES,
           READ_PORTS_PER_LANE,
           REG_NUM,
           REGS_PER_BANK,
           ELEN,
           lgELEN,
           XLEN,
           VLEN,
           lgVLEN)
           PORT MAP(
           clk,
           newInst,
           sew,
           vm,
           vstart,
           vlmul,
           o_done,
           s_mask_bit,
           s_OutPort,
           RegSel,
           s_WriteEn_o,
           s_result,
           WriteDest,
           w_offset_in_sig,
           w_offset_out_sig,
           vl
           );
    
ALU: ALU_with_pipeline generic map(NB_LANES,ELEN, lgELEN, XLEN, VLEN,lgVLEN)
                           port map(clk,rst,busy,s_mask_bit,
                                    Xdata,s_OutPort,Idata,
                                    op2_src,funct6,funct3,WriteEn_i,s_WriteEn_o,s_result,w_offset_out_sig,w_offset_in_sig);

--RF_wd_mux_1<= s_result_1 when ld_RF='0' else Xdata_1;
--RF_wd_mux_2<= s_result_2 when ld_RF='0' else Xdata_2;


 
end Structural;
