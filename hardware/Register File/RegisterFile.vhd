library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RegisterFile is
    generic (
           NB_LANES: integer:=2; --Number of lanes
           READ_PORTS_PER_LANE: integer :=2; --Number of read ports per lane
           REG_NUM: integer:= 5; -- log (number of registers)
           REGS_PER_BANK: integer:= 4; --log(number of registers in each bank) It is REG_NUM-1 in our case since we have 2 banks
           ELEN: integer:=1024;
           lgELEN: integer:=10;
           XLEN:integer:=32; --Register width
           VLEN:integer:=1024; --number of bits in register
           lgVLEN:integer:=5
           );
    Port ( clk : in STD_LOGIC;
           newInst: in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
           mask_bit: out STD_LOGIC;
           OutPort: out STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*ELEN)-1 downto 0);
           RegSel: in STD_LOGIC_VECTOR((READ_PORTS_PER_LANE*NB_LANES*REGS_PER_BANK)-1 downto 0); 
           WriteEn : in STD_LOGIC_VECTOR(NB_LANES-1 downto 0);
           WriteData : in STD_LOGIC_VECTOR (NB_LANES*ELEN-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (NB_LANES*REGS_PER_BANK-1 downto 0);
           sew: in STD_LOGIC_VECTOR (3*NB_LANES-1 downto 0);
           vlmul: in STD_LOGIC_VECTOR(3*NB_LANES-1 downto 0);
           vl: in STD_LOGIC_VECTOR(NB_LANES*XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0);
           r_offset : in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0); 
           w_offset : in STD_LOGIC_VECTOR(NB_LANES*lgVLEN-1 downto 0); 
           mask_reg: out STD_LOGIC_VECTOR(VLEN-1 downto 0)                        
           );
end RegisterFile;

architecture RegFile_arch of RegisterFile is
    
    component Bank1 is
    generic (
           -- log(Number of Vector Registers)
           RegNum: integer:= 5; 
           ELEN: integer:=1024;
           lgELEN: integer:=10;
           XLEN:integer:=32; --Register width
           VLEN:integer:=1024;
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
end component;

component Bank is

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
           RegSel1 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           RegSel2 : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           WriteEn : in STD_LOGIC;
           WriteData : in STD_LOGIC_VECTOR (ELEN-1 downto 0);
           WriteDest : in STD_LOGIC_VECTOR (RegNum-2 downto 0);
           sew: in STD_LOGIC_VECTOR (2 downto 0);
           vlmul: in STD_LOGIC_VECTOR(2 downto 0);
           vl: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           vstart: in STD_LOGIC_VECTOR(lgVLEN-1 downto 0);
           r_offset : in STD_LOGIC_VECTOR(lgVLEN-1 downto 0);
           w_offset : in STD_LOGIC_VECTOR(lgVLEN-1 downto 0)        
           );
end component;   
    --Bank A used for registers 16 to 31 and Bank B used for registers 0 to 15
--    signal RegSelA1, RegSelA2, RegSelB1, RegSelB2, WriteDestA, WriteDestB: STD_LOGIC_VECTOR (REG_NUM-2 downto 0);
    --constant RSA1: integer := 3; constant RSA2: integer := 2;
    --constant RSB1: integer := 1; constant RSB2: integer := 0;
    --constant WDA: integer:=1; constant WDB: integer:=0;
begin
     BankA: Bank1 GENERIC MAP(REG_NUM, ELEN, lgELEN, XLEN, VLEN,lgVLEN)
                  PORT MAP(clk, newInst(0), OutPort(ELEN-1 downto 0 ), OutPort(2*ELEN-1 downto ELEN),
                  mask_bit, RegSel(REGS_PER_BANK-1 downto 0),RegSel(2*REGS_PER_BANK-1 downto REGS_PER_BANK), WriteEn(0), 
                  WriteData(ELEN-1 downto 0), WriteDest(REGS_PER_BANK-1 downto 0), 
                  sew(2 downto 0), 
                  vlmul(2 downto 0),
                  vl(XLEN-1 downto 0), 
                  vstart(lgVLEN-1 downto 0),
                  mask_reg,
                  r_offset(lgVLEN-1 downto 0),
                  w_offset(lgVLEN-1 downto 0)
                  );  
    
    BANK_GEN:for i in 1 to NB_LANES-1 generate
        Banks: Bank GENERIC MAP(REG_NUM, ELEN, lgELEN, XLEN, VLEN,lgVLEN)
                    PORT MAP(clk, newInst(i), 
                    OutPort((READ_PORTS_PER_LANE*i+1)*ELEN -1 downto READ_PORTS_PER_LANE*i*ELEN),
                    OutPort((READ_PORTS_PER_LANE*i+2)*ELEN -1 downto (READ_PORTS_PER_LANE*i+1)*ELEN),
                    RegSel((READ_PORTS_PER_LANE*i+1)*REGS_PER_BANK-1 downto READ_PORTS_PER_LANE*i*REGS_PER_BANK), 
                    RegSel((READ_PORTS_PER_LANE*i+2)*REGS_PER_BANK-1 downto (READ_PORTS_PER_LANE*i+1)*REGS_PER_BANK),
                    WriteEn(i), 
                    WriteData((i+1)*ELEN-1 downto i*ELEN),
                    WriteDest((i+1)*REGS_PER_BANK-1 downto i*REGS_PER_BANK), 
                    sew((i+1)*3-1 downto i*3),
                    vlmul((i+1)*3-1 downto i*3),
                    vl((i+1)*XLEN-1 downto i*XLEN), 
                    vstart((i+1)*lgVLEN-1 downto i*lgVLEN),
                    r_offset((i+1)*lgVLEN-1 downto i*lgVLEN),
                    w_offset((i+1)*lgVLEN-1 downto i*lgVLEN)
                    );   
    
    
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
