library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity ALU_with_pipeline is
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
end ALU_with_pipeline;

architecture Behavioral of ALU_with_pipeline is
    
component ALU_lane is
    generic (
           SEW_MAX: integer:=32 --max element width
           );
    Port (  operand1: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
            operand2: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0);
            funct6: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation
            funct3: in STD_LOGIC_VECTOR (2 downto 0);
            result: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0) 
            );
end component;

component MV_Block is
    generic (
           SEW_MAX: integer:=32 --max element width
           );
    Port (  vs1_data: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- data from VS1 vector register
            vs2_data: in STD_LOGIC_VECTOR(SEW_MAX-1 downto 0); -- data from VS2 vector register
            mask_in: in STD_LOGIC; --mask bit of ith element
            data_out: out STD_LOGIC_VECTOR(SEW_MAX-1 downto 0)
     );
end component;

signal s_operand2: STD_LOGIC_VECTOR(NB_LANES*SEW_MAX-1 downto 0); --Op2 vector (output from mux)

--outputs from pipeline register between RegFile and ALU
signal s_busy:  STD_LOGIC;
signal s_mask_in:  STD_LOGIC;
signal s_Xdata:  STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0); --data from scalar register
signal s_Vdata: STD_LOGIC_VECTOR(2*NB_LANES*SEW_MAX-1 downto 0); --data coming from Register File, 2 since we always have 2 operands
signal s_Idata:  STD_LOGIC_VECTOR(NB_LANES*5-1 downto 0); --data coming from immediate field of size 5 bits
signal s_op2_src:  STD_LOGIC_VECTOR(2*NB_LANES-1 downto 0); -- selects between scalar/vector reg or immediate from operand 2                                                                                                                           
signal s_funct6:  STD_LOGIC_VECTOR(NB_LANES*6-1 downto 0); --to know which operation
signal s_funct3:  STD_LOGIC_VECTOR (NB_LANES*3-1 downto 0); --to know which operation
signal s_WriteEn_i:  STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn from controller
signal s_WriteEn_o:  STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn out to Register File

--output from ALU to pipeline register between ALU and WB stage
signal s_result: STD_LOGIC_VECTOR(NB_LANES*SEW_MAX-1 downto 0); --result vector
signal a_result: STD_LOGIC_VECTOR(NB_LANES*SEW_MAX-1 downto 0); --result from ALU Lanes
signal mv_result: STD_LOGIC_VECTOR(NB_LANES*SEW_MAX-1 downto 0); --result from MV Blocks
  
begin

    pipeline_regs: process(clk, rst) 
    begin
        if(rst='1') then --reset outputs of pipeline registers
            s_busy<= '0';
            s_Xdata<=  (others=>'0');
            s_Vdata<= (others=>'0');
            s_Idata<=  (others=>'0');
            s_op2_src<=(others=>'0');
            s_funct6<= (others=>'0');
            s_funct3<= (others=>'0');    
            result<= (others=>'0');
            s_WriteEn_i<=(others=>'0');
            WriteEn_o<=(others=>'0');
            s_mask_in<='0';
        elsif(rising_edge(clk) and busy= '0' ) then 
            s_Xdata<=  Xdata;
            s_Vdata<= Vdata;
            s_Idata<=  Idata; 
            s_op2_src<=op2_src;
            s_funct6<= funct6;
            s_funct3<= funct3;
            s_WriteEn_i<=WriteEn_i;
            s_mask_in<=mask_in;
            --pipeline reg after ALU
            result<= s_result;
            WriteEn_o<=s_WriteEn_i;
        end if;          
    end process;
    
   -- ALU: ALU_unit generic map(SEW_MAX,lgSEW_MAX)
    --              port map(s_Vdata1_1, s_operand2_1, s_Vdata1_2, s_operand2_2,s_funct6_1, s_funct6_2,s_funct3_1,s_funct3_2, a_result_1, a_result_2);
    LANES_GEN:for i in 0 to NB_LANES-1 generate   
    ALU: ALU_lane generic map(SEW_MAX)
                  port map(s_Vdata((2*i+1)*SEW_MAX-1 downto 2*i*SEW_MAX), -- RegFile output is of the form [...Op2,Op1]
                  s_operand2((i+1)*SEW_MAX-1 downto i*SEW_MAX),
                  s_funct6((i+1)*6-1 downto i*6),
                  s_funct3((i+1)*3-1 downto i*3),
                  a_result((i+1)*SEW_MAX-1 downto i*SEW_MAX)
                  );
    MV: MV_Block  generic map(SEW_MAX)
                  port map(s_Vdata((2*i+1)*SEW_MAX-1 downto 2*i*SEW_MAX), -- RegFile output is of the form [...Op2,Op1]
                  s_operand2((i+1)*SEW_MAX-1 downto i*SEW_MAX),
                  s_mask_in,
                  mv_result((i+1)*SEW_MAX-1 downto i*SEW_MAX)
                  );

    end generate LANES_GEN;
    op2_mux:process(s_op2_src,Vdata,Xdata,Idata,s_funct6,a_result,mv_result) -- process to select operand2 based on s_op2_src
    begin 
       for i in 0 to NB_LANES-1 loop
            if (s_op2_src(2*i+1 downto 2*i)="00") then
                s_operand2((i+1)*SEW_MAX-1 downto i*SEW_MAX)<=Vdata((2*i+2)*SEW_MAX-1 downto (2*i+1)*SEW_MAX);
            elsif (s_op2_src(2*i+1 downto 2*i)="01") then
                s_operand2((i+1)*SEW_MAX-1 downto i*SEW_MAX)<=std_logic_vector(resize(signed(Xdata((i+1)*XLEN-1 downto i*XLEN)),SEW_MAX));--need to sign-extend because XLEN not necessarily = SEW
            elsif (s_op2_src(2*i+1 downto 2*i)="10") then
                s_operand2((i+1)*SEW_MAX-1 downto i*SEW_MAX)<= std_logic_vector(resize(signed(Idata((i+1)*5-1 downto i*5)),SEW_MAX));--need to sign-extend because imm is 5 bits
            else 
                s_operand2((i+1)*SEW_MAX-1 downto i*SEW_MAX)<=(others=>'0');
            end if;
            if (s_funct6((i+1)*6-1 downto i*6)="010111") then  
                s_result((i+1)*SEW_MAX-1 downto i*SEW_MAX)<=mv_result((i+1)*SEW_MAX-1 downto i*SEW_MAX);
            else
                s_result((i+1)*SEW_MAX-1 downto i*SEW_MAX)<=a_result((i+1)*SEW_MAX-1 downto i*SEW_MAX);    
            end if;        
        end loop;
   end process;               
end Behavioral;
