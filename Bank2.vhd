library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
entity Bank2 is

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
           RegSel1 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           RegSel2 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           WriteEn : in STD_LOGIC;
           WriteData : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0)
           );
end Bank2;

architecture Bank2_arch of Bank2 is
    type registerFile is array(0 to (2**(RegNum-1)-1)) of std_logic_vector(VLEN-1 downto 0);   
    signal registers : registerFile;
    
    signal sew_int: integer;
    signal vl_int: integer;
begin
    sew_int<= to_integer(unsigned(sew)); --convert sew to integer for reading
    vl_int<= to_integer(unsigned(vl)); --convert vl to integer
    process(clk, newInst, RegSel1, RegSel2, WriteDest, WriteData, WriteEn) is
        variable read_counter: integer range 0 to (VLEN-1); -- first bit to read from
        variable write_counter: integer range 0 to (VLEN-1); -- first bit to write to
        variable elements_read: integer range 0 to (VLMAX-1); -- # of elements read so far
        variable elements_written: integer range 0 to (VLMAX-1); -- # of elements written so far
    begin
        if(newInst = '1') then elements_read:=to_integer(unsigned(vstart)); elements_written:=to_integer(unsigned(vstart)); read_counter:=to_integer(unsigned(vstart))*sew_int; write_counter:=to_integer(unsigned(vstart))*sew_int; end if; --new instruction from dispatcher, reset counters

        if falling_edge(clk) then                                 
            if WriteEn = '1' then
                --Write 
                if(elements_written < vl_int) then
                    registers(to_integer(unsigned(WriteDest)))((write_counter+sew_int-1) downto write_counter)<=WriteData(sew_int-1 downto 0);  
                    write_counter:= write_counter+sew_int;
                    elements_written:= elements_written+1;
                end if;
            end if;
        elsif rising_edge(clk) then
            if(elements_read < vl_int) then
                out1<= std_logic_vector(resize( signed((registers(to_integer(unsigned(RegSel1))) ((read_counter+sew_int-1) downto read_counter)) ), out1'length));
                out2<= std_logic_vector(resize( signed((registers(to_integer(unsigned(RegSel2))) ((read_counter+sew_int-1) downto read_counter)) ), out2'length));
                read_counter:= read_counter+sew_int;
                elements_read:= elements_read+1;
            end if;
        end if;
    end process;
end Bank2_arch;