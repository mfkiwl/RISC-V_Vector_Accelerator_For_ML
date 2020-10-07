library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
entity Bank1 is

    generic (
           -- Max Vector Length (max number of elements) 
           VLMAX: integer :=32;
           -- log(Number of Vector Registers)
           RegNum: integer:= 5; 
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32 --number of bits in register
    
             );
    Port ( clk : in STD_LOGIC;
           newInst: in STD_LOGIC;
           out1 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out2 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           mask_bit: out STD_LOGIC;
           RegSel1 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           RegSel2 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           WriteEn : in STD_LOGIC;
           WriteData : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           mask_reg: out STD_LOGIC_VECTOR(VLEN-1 downto 0);
           offset : in STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0)
           );
end Bank1;

architecture Bank1_arch of Bank1 is
    type registerFile is array(0 to (2**(RegNum-1)-1)) of std_logic_vector(VLEN-1 downto 0);   
    signal registers : registerFile;
    signal sew_int: integer;
    signal vl_int: integer;
    signal offset_int: integer;
--    signal read_counter: integer range 0 to (VLEN-1); -- first bit to read from
--    signal write_counter: integer range 0 to (VLEN-1); -- first bit to write to
--    signal elements_read: integer range 0 to (VLMAX-1); -- # of elements read so far
--    signal elements_written: integer range 0 to (VLMAX-1); -- # of elements written so far
begin
    mask_reg<=registers(0);
    sew_int<= to_integer(unsigned(sew)); --convert sew to integer for reading
    vl_int<= to_integer(unsigned(vl)); --convert vl to integer
    offset_int<= to_integer(unsigned(offset));
    p1: process(clk, newInst, RegSel1, RegSel2, WriteDest, WriteData, WriteEn, registers) is
        --variable read_counter: integer range 0 to (VLEN-1); -- first bit to read from
        variable write_counter: integer range 0 to (VLEN-1); -- first bit to write to
        --variable elements_read: integer range 0 to (VLMAX-1); -- # of elements read so far
        --variable elements_written: integer range 0 to (VLMAX-1); -- # of elements written so far
    begin
        if(newInst = '1') then 
       --elements_read:=to_integer(unsigned(vstart)); 
       -- elements_written:=to_integer(unsigned(vstart)); 
       -- read_counter:=to_integer(unsigned(vstart))*sew_int; 
        write_counter:=to_integer(unsigned(vstart))*sew_int; 
        end if; --new instruction from dispatcher, reset counters

        if falling_edge(clk) then                                 
            if WriteEn = '1' then
                --Write 
                if(write_counter/sew_int < vl_int) then
                    registers(to_integer(unsigned(WriteDest)))((offset_int+sew_int-1) downto offset_int)<=WriteData(sew_int-1 downto 0);  
                    write_counter:= write_counter+sew_int;
                    --elements_written:= elements_written+1;
                end if;
            end if;
        elsif rising_edge(clk) then
            if(offset_int/sew_int < vl_int) then
                mask_bit<=registers(0)(offset_int);
                out1<= std_logic_vector(resize( signed((registers(to_integer(unsigned(RegSel1))) ((offset_int+sew_int-1) downto offset_int)) ), out1'length));
                out2<= std_logic_vector(resize( signed((registers(to_integer(unsigned(RegSel2))) ((offset_int+sew_int-1) downto offset_int)) ), out2'length));
               -- read_counter:= read_counter+sew_int;
               --elements_read:= elements_read+1;
            end if;
        end if;
    end process;
end Bank1_arch;
