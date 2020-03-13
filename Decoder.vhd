library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--The decoder divides the incoming vector instructions into the respective fields (based on RISC-V vector spec)

entity Decoder is
    Port ( d_vect_inst : in STD_LOGIC_VECTOR (31 downto 0);
           -- Instruction Fields: (for ALU and memory)
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
end Decoder;


architecture Behavioral of Decoder is 
    begin
        d_funct6<=d_vect_inst(31 downto 26);
        d_bit31<=d_vect_inst(31);
        d_nf<=d_vect_inst(31 downto 29);
        d_mop<=d_vect_inst(28 downto 26);
        d_vm<=d_vect_inst(25);
        d_vs2_rs2<=d_vect_inst(24 downto 20);
        d_rs1<=d_vect_inst(19 downto 15);
        d_funct3_width<=d_vect_inst(14 downto 12);
        d_vd_vs3<=d_vect_inst(11 downto 7);
        d_opcode<=d_vect_inst(6 downto 0);

end Behavioral;
