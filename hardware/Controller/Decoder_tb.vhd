library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--The decoder divides the incoming vector instructions into the respective fields

entity Decoder_tb is
end Decoder_tb;


architecture Behavioral of Decoder_tb is

    Component Decoder is
        Port ( d_vect_inst : in STD_LOGIC_VECTOR (31 downto 0);
           -- Instruction Fields:
           d_funct6 : out STD_LOGIC_VECTOR (5 downto 0);
           d_bit31: out STD_LOGIC; -- used for vsetvl,vsetvli instructions
           d_nf : out STD_LOGIC_VECTOR (2 downto 0);
           d_mop : out STD_LOGIC_VECTOR (2 downto 0);
           d_vm : out STD_LOGIC;
           d_vs2_rs2 : out STD_LOGIC_VECTOR (4 downto 0);
           d_rs1 : out STD_LOGIC_VECTOR (4 downto 0);
           d_funct3_width : out STD_LOGIC_VECTOR (2 downto 0);
           d_vd_vs3 : out STD_LOGIC_VECTOR (4 downto 0);
           d_opcode : out STD_LOGIC_VECTOR (6 downto 0));
    end component;
    
     signal          d_vect_inst : STD_LOGIC_VECTOR (31 downto 0);
           -- Instruction Fields:
     signal          d_funct6 :  STD_LOGIC_VECTOR (5 downto 0);
     signal          d_bit31:  STD_LOGIC; -- used for vsetvl,vsetvli instructions
     signal          d_nf :  STD_LOGIC_VECTOR (2 downto 0);
     signal          d_mop :  STD_LOGIC_VECTOR (2 downto 0);
     signal          d_vm :  STD_LOGIC;
     signal          d_vs2_rs2 :  STD_LOGIC_VECTOR (4 downto 0);
     signal          d_rs1 :  STD_LOGIC_VECTOR (4 downto 0);
     signal          d_funct3_width :  STD_LOGIC_VECTOR (2 downto 0);
     signal         d_vd_vs3 :  STD_LOGIC_VECTOR (4 downto 0);
     signal          d_opcode : STD_LOGIC_VECTOR (6 downto 0);
    begin
    
UUT: Decoder port map (d_vect_inst,d_funct6,d_bit31,d_nf,d_mop,d_vm,d_vs2_rs2,d_rs1,d_funct3_width,d_vd_vs3,d_opcode);
d_vect_inst<="10101100101011000101010111111111";
end Behavioral;
