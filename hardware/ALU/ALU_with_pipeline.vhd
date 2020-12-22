library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity ALU_with_pipeline is
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
end ALU_with_pipeline;

architecture Behavioral of ALU_with_pipeline is
    
component ALU_lane is
    generic (
           ELEN: integer:=1024 --max element width
           );
    Port (  operand1: in STD_LOGIC_VECTOR(ELEN-1 downto 0);
            operand2: in STD_LOGIC_VECTOR(ELEN-1 downto 0);
            funct6: in STD_LOGIC_VECTOR (5 downto 0); --to know which operation
            funct3: in STD_LOGIC_VECTOR (2 downto 0);
            result: out STD_LOGIC_VECTOR(ELEN-1 downto 0) 
            );
end component;

component MV_Block is
    generic (
           ELEN: integer:=1024 --max element width
           );
    Port (  vs1_data: in STD_LOGIC_VECTOR(ELEN-1 downto 0); -- data from VS1 vector register
            vs2_data: in STD_LOGIC_VECTOR(ELEN-1 downto 0); -- data from VS2 vector register
            mask_in: in STD_LOGIC; --mask bit of ith element
            data_out: out STD_LOGIC_VECTOR(ELEN-1 downto 0)
     );
end component;

signal s_operand2: STD_LOGIC_VECTOR(NB_LANES*ELEN-1 downto 0); --Op2 vector (output from mux)

--outputs from pipeline register between RegFile and ALU
signal s_busy:  STD_LOGIC;
signal s_mask_in:  STD_LOGIC;
signal s_Xdata:  STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0); --data from scalar register
signal s_Vdata: STD_LOGIC_VECTOR(2*NB_LANES*ELEN-1 downto 0); --data coming from Register File, 2 since we always have 2 operands
signal s_Idata:  STD_LOGIC_VECTOR(NB_LANES*5-1 downto 0); --data coming from immediate field of size 5 bits
signal s_op2_src:  STD_LOGIC_VECTOR(2*NB_LANES-1 downto 0); -- selects between scalar/vector reg or immediate from operand 2                                                                                                                           
signal s_funct6:  STD_LOGIC_VECTOR(NB_LANES*6-1 downto 0); --to know which operation
signal s_funct3:  STD_LOGIC_VECTOR (NB_LANES*3-1 downto 0); --to know which operation
signal s_WriteEn_i:  STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn from controller
signal s_WriteEn_o:  STD_LOGIC_VECTOR(NB_LANES-1 downto 0); --WriteEn out to Register File
signal s_w_offset_in :  STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);--offset coming from the pipeline
signal s_w_offset_out :  STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0); --offset going to pipeline
--output from ALU to pipeline register between ALU and WB stage
signal s_result: STD_LOGIC_VECTOR(NB_LANES*ELEN-1 downto 0); --result vector
signal a_result: STD_LOGIC_VECTOR(NB_LANES*ELEN-1 downto 0); --result from ALU Lanes
signal mv_result: STD_LOGIC_VECTOR(NB_LANES*ELEN-1 downto 0); --result from MV Blocks
  
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
            s_w_offset_in<=(others=>'0');
            s_w_offset_out<=(others=>'0');
            w_offset_out<=(others=>'0');
            s_mask_in<='0';
        elsif(rising_edge(clk) and busy= '0') then 
            s_Xdata<=  Xdata;
            s_Vdata<= Vdata;
            s_Idata<=  Idata; 
            s_op2_src<=op2_src;
            s_funct6<= funct6;
            s_funct3<= funct3;
            s_WriteEn_i<=WriteEn_i;
            s_mask_in<=mask_in;
            s_w_offset_in<=w_offset_in;
            --pipeline reg after ALU
            result<= s_result;
            WriteEn_o<=s_WriteEn_i;
            w_offset_out<=s_w_offset_in;
        end if;          
    end process;
    
   -- ALU: ALU_unit generic map(ELEN,lgELEN)
    --              port map(s_Vdata1_1, s_operand2_1, s_Vdata1_2, s_operand2_2,s_funct6_1, s_funct6_2,s_funct3_1,s_funct3_2, a_result_1, a_result_2);
    LANES_GEN:for i in 0 to NB_LANES-1 generate   
    ALU: ALU_lane generic map(ELEN)
                  port map(s_Vdata((2*i+1)*ELEN-1 downto 2*i*ELEN), -- RegFile output is of the form [...Op2,Op1]
                  s_operand2((i+1)*ELEN-1 downto i*ELEN),
                  s_funct6((i+1)*6-1 downto i*6),
                  s_funct3((i+1)*3-1 downto i*3),
                  a_result((i+1)*ELEN-1 downto i*ELEN)
                  );
    MV: MV_Block  generic map(ELEN)
                  port map(s_Vdata((2*i+1)*ELEN-1 downto 2*i*ELEN), -- RegFile output is of the form [...Op2,Op1]
                  s_operand2((i+1)*ELEN-1 downto i*ELEN),
                  s_mask_in,
                  mv_result((i+1)*ELEN-1 downto i*ELEN)
                  );

    end generate LANES_GEN;
    op2_mux:process(s_op2_src,s_Vdata,s_Xdata,s_Idata,s_funct6,a_result,mv_result) -- process to select operand2 based on s_op2_src
    begin 
       for i in 0 to NB_LANES-1 loop
            if (s_op2_src(2*i+1 downto 2*i)="00") then
                s_operand2((i+1)*ELEN-1 downto i*ELEN)<=s_Vdata((2*i+2)*ELEN-1 downto (2*i+1)*ELEN);
            elsif (s_op2_src(2*i+1 downto 2*i)="01") then
                s_operand2((i+1)*ELEN-1 downto i*ELEN)<=std_logic_vector(resize(signed(s_Xdata((i+1)*XLEN-1 downto i*XLEN)),ELEN));--need to sign-extend because XLEN not necessarily = SEW
            elsif (s_op2_src(2*i+1 downto 2*i)="10") then
                s_operand2((i+1)*ELEN-1 downto i*ELEN)<= std_logic_vector(resize(signed(s_Idata((i+1)*5-1 downto i*5)),ELEN));--need to sign-extend because imm is 5 bits
            else 
                s_operand2((i+1)*ELEN-1 downto i*ELEN)<=(others=>'0');
            end if;
            if (s_funct6((i+1)*6-1 downto i*6)="010111") then  
                s_result((i+1)*ELEN-1 downto i*ELEN)<=mv_result((i+1)*ELEN-1 downto i*ELEN);
            else
                s_result((i+1)*ELEN-1 downto i*ELEN)<=a_result((i+1)*ELEN-1 downto i*ELEN);    
            end if;        
        end loop;
   end process;               
end Behavioral;
