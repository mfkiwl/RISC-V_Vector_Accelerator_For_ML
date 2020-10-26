library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegisterFile is
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
    Port ( clk : in STD_LOGIC;
           newInst: in STD_LOGIC;
           mask_bit: out STD_LOGIC;
           OutPort: out STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*SEW_MAX)-1 downto 0);
           RegSel: in STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
           WriteEn : in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
           WriteData : in STD_LOGIC_VECTOR (NB_LANES*SEW_MAX-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
           sew: in STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
           vl: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
           reg_offset : in STD_LOGIC_VECTOR(NB_LANES*lgSEW_MAX-1 downto 0);  
           mask_reg: out STD_LOGIC_VECTOR(VLEN-1 downto 0)                        
           );
end RegisterFile;

architecture RegFile_arch of RegisterFile is
    
    component Bank1 is
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
end component;

component Bank is

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
           vstart: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           offset : in STD_LOGIC_VECTOR(lgSEW_MAX-1 downto 0)          
           );
end component;   
    --Bank A used for registers 16 to 31 and Bank B used for registers 0 to 15
--    signal RegSelA1, RegSelA2, RegSelB1, RegSelB2, WriteDestA, WriteDestB: STD_LOGIC_VECTOR (REG_NUM-2 downto 0);
    --constant RSA1: integer := 3; constant RSA2: integer := 2;
    --constant RSB1: integer := 1; constant RSB2: integer := 0;
    --constant WDA: integer:=1; constant WDB: integer:=0;
begin
     BankA: Bank1 GENERIC MAP(VLMAX, REG_NUM, SEW_MAX, lgSEW_MAX, XLEN, VLEN)
                  PORT MAP(clk, newInst, OutPort(SEW_MAX-1 downto 0 ), OutPort(2*SEW_MAX-1 downto SEW_MAX),
                  mask_bit, RegSel(REGS_PER_BANK-1 downto 0),RegSel(2*REGS_PER_BANK-1 downto REGS_PER_BANK), WriteEn(0), 
                  WriteData(SEW_MAX-1 downto 0), WriteDest(REGS_PER_BANK-1 downto 0), 
                  sew, vl(XLEN-1 downto 0), vstart(XLEN-1 downto 0),mask_reg,reg_offset(lgSEW_MAX-1 downto 0));  
    
    BANK_GEN:for i in 1 to NB_LANES-1 generate
        Banks: Bank GENERIC MAP(VLMAX, REG_NUM, SEW_MAX, lgSEW_MAX, XLEN, VLEN)
                    PORT MAP(clk, newInst, 
                    OutPort((READ_PORTS_PER_LANE*i+1)*SEW_MAX -1 downto READ_PORTS_PER_LANE*i*SEW_MAX),
                    OutPort((READ_PORTS_PER_LANE*i+2)*SEW_MAX -1 downto (READ_PORTS_PER_LANE*i+1)*SEW_MAX),
                    RegSel((READ_PORTS_PER_LANE*i+1)*REGS_PER_BANK-1 downto READ_PORTS_PER_LANE*i*REGS_PER_BANK), 
                    RegSel((READ_PORTS_PER_LANE*i+2)*REGS_PER_BANK-1 downto (READ_PORTS_PER_LANE*i+1)*REGS_PER_BANK),
                    WriteEn(i), 
                    WriteData((i+1)*SEW_MAX-1 downto i*SEW_MAX),
                    WriteDest((i+1)*REGS_PER_BANK-1 downto i*REGS_PER_BANK), 
                    sew,
                    vl((i+1)*XLEN-1 downto i*XLEN), 
                    vstart((i+1)*XLEN-1 downto i*XLEN),
                    reg_offset((i+1)*lgSEW_MAX-1 downto i*lgSEW_MAX));   
    
    
    end generate BANK_GEN;
--    process(RegSel1, RegSel2, RegSel3, RegSel4, WriteDest1, WriteDest2)
--    --variable RegSelFlag: STD_LOGIC_VECTOR(RegNum-2 downto 0):=(others => '0'); --one-hot encoding (RegSelA1, RegSelA2, RegSelB1, RegSelB2) to know which bank ports are busy ('1') or free ('0').
--    --variable WriteDestFlag: STD_LOGIC_VECTOR(1 downto 0):= (others => '0'); --one-hot encoding (WriteDestA, WriteDestB) 
--    begin
--        --if instruction done, reset appropriate flags
        
--        --check the MSB to know to which bank to dispatch instruction.
--        if( RegSel1(RegNum-1) = '1' ) then  --Bank A
----            if ( RegSelFlag(RSA1) = '0' ) then RegSelA1 <= RegSel1(RegNum-2 downto 0); RegSelFlag(RSA1):='1'; --assign appropriate port and flag as busy
----            elsif( ( RegSelFlag(RSA2) = '0' ) ) then RegSelA2 <= RegSel1(RegNum-2 downto 0); RegSelFlag(RSA2):='1';
----            --else --stall
----            end if;
--            RegSelA1 <= RegSel1(RegNum-2 downto 0);
--            --RegSelA2 <= RegSel1(RegNum-2 downto 0);
--        else --Bank B
----            if ( RegSelFlag(RSB1) = '0' ) then RegSelB1 <= RegSel1(RegNum-2 downto 0); RegSelFlag(RSB1):='1'; 
----            elsif( ( RegSelFlag(RSB2) = '0' ) ) then RegSelB2 <= RegSel1(RegNum-2 downto 0); RegSelFlag(RSB2):='1';
----            --else --stall
----            end if;
--            RegSelB1 <= RegSel1(RegNum-2 downto 0);
--            --RegSelB2 <= RegSel1(RegNum-2 downto 0);
--        end if;
        
--        if( RegSel2(RegNum-1) = '1') then
----            if ( RegSelFlag(RSA1) = '0' ) then RegSelA1 <= RegSel2(RegNum-2 downto 0); RegSelFlag(RSA1):='1'; --assign appropriate port and flag as busy
----            elsif( ( RegSelFlag(RSA2) = '0' ) ) then RegSelA2 <= RegSel2(RegNum-2 downto 0); RegSelFlag(RSA2):='1';
----            --else --stall
----            end if; 
--            --RegSelA1 <= RegSel2(RegNum-2 downto 0);
--            RegSelA2 <= RegSel2(RegNum-2 downto 0);
--        else --Bank B
----            if ( RegSelFlag(RSB1) = '0' ) then RegSelB1 <= RegSel2(RegNum-2 downto 0); RegSelFlag(RSB1):='1'; 
----            elsif( ( RegSelFlag(RSB2) = '0' ) ) then RegSelB2 <= RegSel2(RegNum-2 downto 0); RegSelFlag(RSB2):='1';
----            --else --stall
----            end if;
--            --RegSelB1 <= RegSel2(RegNum-2 downto 0);
--            RegSelB2 <= RegSel2(RegNum-2 downto 0);
--        end if;
        
--        if( RegSel3(RegNum-1) = '1') then
----            if ( RegSelFlag(RSA1) = '0' ) then RegSelA1 <= RegSel3(RegNum-2 downto 0); RegSelFlag(RSA1):='1'; --assign appropriate port and flag as busy
----            elsif( ( RegSelFlag(RSA2) = '0' ) ) then RegSelA2 <= RegSel3(RegNum-2 downto 0); RegSelFlag(RSA2):='1';
----            --else --stall
----            end if; 
--            RegSelA1 <= RegSel3(RegNum-2 downto 0);
--            --RegSelA2 <= RegSel3(RegNum-2 downto 0);
--        else --Bank B
----            if ( RegSelFlag(RSB1) = '0' ) then RegSelB1 <= RegSel3(RegNum-2 downto 0); RegSelFlag(RSB1):='1'; 
----            elsif( ( RegSelFlag(RSB2) = '0' ) ) then RegSelB2 <= RegSel3(RegNum-2 downto 0); RegSelFlag(RSB2):='1';
----            --else --stall
----            end if;
--            RegSelB1 <= RegSel3(RegNum-2 downto 0);
--            --RegSelB2 <= RegSel3(RegNum-2 downto 0);
--        end if;
        
--        if( RegSel4(RegNum-1) = '1') then
----            if ( RegSelFlag(RSA1) = '0' ) then RegSelA1 <= RegSel4(RegNum-2 downto 0); RegSelFlag(RSA1):='1'; --assign appropriate port and flag as busy
----            elsif( ( RegSelFlag(RSA2) = '0' ) ) then RegSelA2 <= RegSel4(RegNum-2 downto 0); RegSelFlag(RSA2):='1';
----            --else --stall
----            end if; 
--            --RegSelA1 <= RegSel4(RegNum-2 downto 0);
--            RegSelA2 <= RegSel4(RegNum-2 downto 0);
--        else --Bank B
----            if ( RegSelFlag(RSB1) = '0' ) then RegSelB1 <= RegSel4(RegNum-2 downto 0); RegSelFlag(RSB1):='1'; 
----            elsif( ( RegSelFlag(RSB2) = '0' ) ) then RegSelB2 <= RegSel4(RegNum-2 downto 0); RegSelFlag(RSB2):='1';
----            --else --stall
----            end if;
--            --RegSelB1 <= RegSel4(RegNum-2 downto 0);
--            RegSelB2 <= RegSel4(RegNum-2 downto 0);
--        end if;
        
--        if( WriteDest1(RegNum-1) = '1' ) then
----            if(WriteDestFlag(WDA)='0') then WriteDestA<= WriteDest1(RegNum-2 downto 0); WriteDestFlag(WDA):='1';
----            --else -- stall
----            end if;
--            WriteDestA<= WriteDest1(RegNum-2 downto 0);
--        else
----            if(WriteDestFlag(WDB)='0') then WriteDestB<= WriteDest1(RegNum-2 downto 0); WriteDestFlag(WDB):='1';
----            --else -- stall
----            end if;
--            WriteDestB<= WriteDest1(RegNum-2 downto 0);
--        end if;
        
--        if( WriteDest2(RegNum-1) = '1' ) then
----            if(WriteDestFlag(WDA)='0') then WriteDestA<= WriteDest2(RegNum-2 downto 0); WriteDestFlag(WDA):='1';
----            --else -- stall
----            end if;
--            WriteDestA<= WriteDest2(RegNum-2 downto 0);
--        else
----            if(WriteDestFlag(WDB)='0') then WriteDestB<= WriteDest2(RegNum-2 downto 0); WriteDestFlag(WDB):='1';
----            --else -- stall
----            end if;
--            WriteDestB<= WriteDest2(RegNum-2 downto 0);
--        end if;
--    end process;
end RegFile_arch;
