library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegFile_ALU is
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
end RegFile_ALU;

architecture Structural of RegFile_ALU is

component ALU_with_pipeline is
    generic(
           NB_LANES: integer:=2; --Number of lanes            
           VLMAX: integer :=32; -- Max Vector Length (max number of elements) 
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32 --number of bits in register
           );
    Port (  clk: in STD_LOGIC; 
            rst: in STD_LOGIC;
            busy: in STD_LOGIC;
            mask_in: in STD_LOGIC;
            Xdata: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0); --data from scalar register
            Vdata: in STD_LOGIC_VECTOR(2*NB_LANES*SEW_MAX-1 downto 0); --data coming from Register File, 2 since we always have 2 operands
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
            result: out STD_LOGIC_VECTOR(NB_LANES*SEW_MAX-1 downto 0) --result vector
            );
end component;

component RegFile_AddrGen is
    generic (
           NB_LANES: integer:=2; --Number of lanes
           READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
           VLMAX: integer :=32; -- Max Vector Length (max number of elements) 
           REG_NUM: integer:= 5; -- log (number of registers)
           REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32 --number of bits in register
    );
    Port (
            i_clk : in std_logic;
            newInst: in STD_LOGIC;
            sew: in std_logic_vector (lgSEW_MAX-1 downto 0);
            vm: in STD_LOGIC;
            vstart: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
            o_done : out STD_LOGIC_VECTOR(NB_LANES-1 downto 0); 
            mask_bit: out STD_LOGIC;
            OutPort: out STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*SEW_MAX)-1 downto 0);
            RegSel: in STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
            WriteEn : in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
            WriteData : in STD_LOGIC_VECTOR (NB_LANES*SEW_MAX-1 downto 0);
            WriteDest : in STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
            vl: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0)
  );
end component;

signal     s_OutPort: STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*SEW_MAX)-1 downto 0);
signal     s_WriteEn_o: STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
signal     s_result: STD_LOGIC_VECTOR(NB_LANES*SEW_MAX-1 downto 0);
signal     s_mask_bit: STD_LOGIC;
--signal     RF_wd_mux_1: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
--signal     RF_wd_mux_2: STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);

begin


RF: RegFile_AddrGen GENERIC MAP(NB_LANES,
           READ_PORTS_PER_LANE,
           VLMAX,
           REG_NUM,
           REGS_PER_BANK,
           SEW_MAX,
           lgSEW_MAX,
           XLEN,
           VLEN)
           PORT MAP(clk,
           newInst,
           sew,
           vm,
           vstart,
           o_done,
           s_mask_bit,
           s_OutPort,
           RegSel,
           s_WriteEn_o,
           s_result,
           WriteDest,
           vl);
    
ALU: ALU_with_pipeline generic map(NB_LANES,VLMAX, SEW_MAX, lgSEW_MAX, XLEN, VLEN)
                           port map(clk,rst,busy,s_mask_bit,
                                    Xdata,s_OutPort,Idata,
                                    op2_src,funct6,funct3,WriteEn_i,s_WriteEn_o,s_result);

--RF_wd_mux_1<= s_result_1 when ld_RF='0' else Xdata_1;
--RF_wd_mux_2<= s_result_2 when ld_RF='0' else Xdata_2;


 
end Structural;
