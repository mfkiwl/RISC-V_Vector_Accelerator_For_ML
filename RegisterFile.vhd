----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.03.2020 15:57:55
-- Design Name: 
-- Module Name: RegisterFile - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RegisterFile is
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
           out3 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           out4 : out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           RegSel1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSel2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSel3 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           RegSel4 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           WriteEn1 : in STD_LOGIC;
           WriteEn2 : in STD_LOGIC;
           WriteData1 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest1 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           WriteData2 : in STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
           WriteDest2 : in STD_LOGIC_VECTOR (RegNum-1 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0));
end RegisterFile;

architecture Behavioral of RegisterFile is
    
    component Bank is
    generic (
           -- Max Vector Length
           VLMAX: integer :=32;
           -- log(Number of Vector Registers)
           RegNum: integer:= 5; 
           SEW_MAX: integer:=32;
           lgSEW_MAX: integer:=5;
           XLEN:integer:=32; --Register width
           VLEN:integer:=32
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
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0) 
           );
end component;
    
    --Bank A used for registers 16 to 31 and Bank B used for registers 0 to 15
    signal RegSelA1, RegSelA2, RegSelB1, RegSelB2, WriteDestA, WriteDestB: STD_LOGIC_VECTOR (RegNum-2 downto 0);
    constant RSA1: integer := 3; constant RSA2: integer := 2;
    constant RSB1: integer := 1; constant RSB2: integer := 0;
    constant WDA: integer:=1; constant WDB: integer:=0;
begin
    process(RegSel1, RegSel2, RegSel3, RegSel4, WriteDest1, WriteDest2)
    variable RegSelFlag: STD_LOGIC_VECTOR(RegNum-2 downto 0):=(others => '0'); --one-hot encoding (RegSelA1, RegSelA2, RegSelB1, RegSelB2) to know which bank ports are busy ('1') or free ('0').
    variable WriteDestFlag: STD_LOGIC_VECTOR(1 downto 0):= (others => '0'); --one-hot encoding (WriteDestA, WriteDestB) 
    begin
        --if instruction done, reset appropriate flags
        
        --check the MSB to know to which bank to dispatch instruction.
        if( RegSel1(RegNum-1) = '1' ) then  --Bank A
            if ( RegSelFlag(RSA1) = '0' ) then RegSelA1 <= RegSel1(RegNum-2 downto 0); RegSelFlag(RSA1):='1'; --assign appropriate port and flag as busy
            elsif( ( RegSelFlag(RSA2) = '0' ) ) then RegSelA2 <= RegSel1(RegNum-2 downto 0); RegSelFlag(RSA2):='1';
            --else --stall
            end if; 
        else --Bank B
            if ( RegSelFlag(RSB1) = '0' ) then RegSelB1 <= RegSel1(RegNum-2 downto 0); RegSelFlag(RSB1):='1'; 
            elsif( ( RegSelFlag(RSB2) = '0' ) ) then RegSelB2 <= RegSel1(RegNum-2 downto 0); RegSelFlag(RSB2):='1';
            --else --stall
            end if;
        end if;
        
        if( RegSel2(RegNum-1) = '1') then
            if ( RegSelFlag(RSA1) = '0' ) then RegSelA1 <= RegSel2(RegNum-2 downto 0); RegSelFlag(RSA1):='1'; --assign appropriate port and flag as busy
            elsif( ( RegSelFlag(RSA2) = '0' ) ) then RegSelA2 <= RegSel2(RegNum-2 downto 0); RegSelFlag(RSA2):='1';
            --else --stall
            end if; 
        else --Bank B
            if ( RegSelFlag(RSB1) = '0' ) then RegSelB1 <= RegSel2(RegNum-2 downto 0); RegSelFlag(RSB1):='1'; 
            elsif( ( RegSelFlag(RSB2) = '0' ) ) then RegSelB2 <= RegSel2(RegNum-2 downto 0); RegSelFlag(RSB2):='1';
            --else --stall
            end if;
        end if;
        
        if( RegSel3(RegNum-1) = '1') then
            if ( RegSelFlag(RSA1) = '0' ) then RegSelA1 <= RegSel3(RegNum-2 downto 0); RegSelFlag(RSA1):='1'; --assign appropriate port and flag as busy
            elsif( ( RegSelFlag(RSA2) = '0' ) ) then RegSelA2 <= RegSel3(RegNum-2 downto 0); RegSelFlag(RSA2):='1';
            --else --stall
            end if; 
        else --Bank B
            if ( RegSelFlag(RSB1) = '0' ) then RegSelB1 <= RegSel3(RegNum-2 downto 0); RegSelFlag(RSB1):='1'; 
            elsif( ( RegSelFlag(RSB2) = '0' ) ) then RegSelB2 <= RegSel3(RegNum-2 downto 0); RegSelFlag(RSB2):='1';
            --else --stall
            end if;
        end if;
        
        if( RegSel4(RegNum-1) = '1') then
            if ( RegSelFlag(RSA1) = '0' ) then RegSelA1 <= RegSel4(RegNum-2 downto 0); RegSelFlag(RSA1):='1'; --assign appropriate port and flag as busy
            elsif( ( RegSelFlag(RSA2) = '0' ) ) then RegSelA2 <= RegSel4(RegNum-2 downto 0); RegSelFlag(RSA2):='1';
            --else --stall
            end if; 
        else --Bank B
            if ( RegSelFlag(RSB1) = '0' ) then RegSelB1 <= RegSel4(RegNum-2 downto 0); RegSelFlag(RSB1):='1'; 
            elsif( ( RegSelFlag(RSB2) = '0' ) ) then RegSelB2 <= RegSel4(RegNum-2 downto 0); RegSelFlag(RSB2):='1';
            --else --stall
            end if;
        end if;
        
        if( WriteDest1(RegNum-1) = '1' ) then
            if(WriteDestFlag(WDA)='0') then WriteDestA<= WriteDest1(RegNum-2 downto 0); WriteDestFlag(WDA):='1';
            --else -- stall
            end if;
        else
            if(WriteDestFlag(WDB)='0') then WriteDestB<= WriteDest1(RegNum-2 downto 0); WriteDestFlag(WDB):='1';
            --else -- stall
            end if;
        end if;
        
        if( WriteDest2(RegNum-1) = '1' ) then
            if(WriteDestFlag(WDA)='0') then WriteDestA<= WriteDest2(RegNum-2 downto 0); WriteDestFlag(WDA):='1';
            --else -- stall
            end if;
        else
            if(WriteDestFlag(WDB)='0') then WriteDestB<= WriteDest2(RegNum-2 downto 0); WriteDestFlag(WDB):='1';
            --else -- stall
            end if;
        end if;
    end process;
    
    BankA: Bank GENERIC MAP(VLMAX, RegNum, SEW_MAX, lgSEW_MAX, XLEN, VLEN)
    PORT MAP(clk, newInst, out1, out2, RegSelA1, RegSelA2, WriteEn1, WriteData1, WriteDestA, sew, vl);
    
    BankB: Bank GENERIC MAP(VLMAX, RegNum, SEW_MAX, lgSEW_MAX, XLEN, VLEN)
    PORT MAP(clk, newInst, out3, out4, RegSelB1, RegSelB2, WriteEn2, WriteData2, WriteDestB, sew, vl);
end Behavioral;
