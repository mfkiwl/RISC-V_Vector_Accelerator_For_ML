library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
entity Bank1 is

    generic (
           -- log(Number of Vector Registers)
           RegNum: integer:= 5; 
           ELEN: integer:=1024;
           lgELEN: integer:=10;
           XLEN:integer:=32; --Register width
           VLEN:integer:=1024; --number of bits in register
           lgVLEN:integer:=5
             );
    Port ( clk : in STD_LOGIC;
           newInst: in STD_LOGIC;
           out1 : out STD_LOGIC_VECTOR (ELEN-1 downto 0);
           out2 : out STD_LOGIC_VECTOR (ELEN-1 downto 0);
           mask_bit: out STD_LOGIC;
           RegSel1 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           RegSel2 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           WriteEn : in STD_LOGIC;
           WriteData : in STD_LOGIC_VECTOR (ELEN-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           sew: in STD_LOGIC_VECTOR (2 downto 0);
           vlmul: in STD_LOGIC_VECTOR(2 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(lgVLEN-1 downto 0);
           mask_reg: out STD_LOGIC_VECTOR(VLEN-1 downto 0);
           r_offset : in STD_LOGIC_VECTOR(lgVLEN-1 downto 0);
           w_offset : in STD_LOGIC_VECTOR(lgVLEN-1 downto 0)
           );
end Bank1;

architecture Bank1_arch of Bank1 is
    type registerFile is array(0 to (2**(RegNum-1)-1)) of std_logic_vector(VLEN-1 downto 0);   
    signal registers : registerFile;
    signal sew_int: integer;
    signal vl_int: integer;
    signal w_offset_int: integer;
    signal r_offset_int: integer;
    signal VLMAX:natural;
--    signal read_counter: integer range 0 to (VLEN-1); -- first bit to read from
--    signal write_counter: integer range 0 to (VLEN-1); -- first bit to write to
--    signal elements_read: integer range 0 to (VLMAX-1); -- # of elements read so far
--    signal elements_written: integer range 0 to (VLMAX-1); -- # of elements written so far
begin

    mask_reg<=registers(0);

    with sew select 
    sew_int <= 8 when "000",
           16 when "001",
           32 when "010",
           64 when "011",
           128 when "100",
           256 when "101",
           512 when "110",
           1024 when "111",
           XLEN when others;
           
    vl_int<= to_integer(unsigned(vl)); --convert vl to integer
    w_offset_int<= to_integer(unsigned(w_offset));
    r_offset_int<= to_integer(unsigned(r_offset));
    p1: process(clk, newInst, RegSel1, RegSel2, WriteDest, WriteData, WriteEn, registers,r_offset,w_offset) is
    begin
        if rising_edge(clk) then                                            
            if WriteEn = '1' then
                --Write 
                if(w_offset_int < vl_int) then
                    registers(to_integer(unsigned(WriteDest)))((sew_int*(w_offset_int+1)-1) downto sew_int*w_offset_int)<=WriteData(sew_int-1 downto 0);  
                end if;
            end if;
        elsif falling_edge(clk) then
            if(r_offset_int < vl_int) then
                mask_bit<=registers(0)(r_offset_int);
                out1<= std_logic_vector(resize( signed((registers(to_integer(unsigned(RegSel1))) ((sew_int*(r_offset_int+1)-1) downto sew_int*r_offset_int)) ), out1'length));
                out2<= std_logic_vector(resize( signed((registers(to_integer(unsigned(RegSel2))) ((sew_int*(r_offset_int+1)-1) downto sew_int*r_offset_int)) ), out2'length));
            end if;
        end if;
    end process;
end Bank1_arch;
