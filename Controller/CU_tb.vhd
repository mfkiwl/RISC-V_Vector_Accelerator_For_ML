library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CU_tb is
--  Port ( );
end CU_tb;

architecture Behavioral of CU_tb is

constant        XLEN:integer:=32; --Register width
constant        ELEN:integer:=32; --Maximum element width
constant        VLEN:integer:=32;
constant        SEW_MAX:integer:=32;
constant        lgSEW_MAX: integer:=5;
constant        VLMAX: integer :=32;
constant        logVLMAX: integer := 5;

component Control_Unit is

    generic (
        XLEN:integer:=32; --Register width
        ELEN:integer:=32; --Maximum element width
        VLEN:integer:=32;
        SEW_MAX: integer:=32;
        lgSEW_MAX: integer:=5;
        VLMAX: integer :=32;
        logVLMAX: integer := 5
    );

    Port ( 
           --FORMAT USED: A set of inputs followed by their respective output ports:
           
           --Clock and Busy Signals INPUT:
           clk_in:in STD_LOGIC;
           busy: in STD_LOGIC;
           --------------------------------------------
           --------------------------------------------
           --Control Registers INPUT:
           CSR_Addr: in STD_LOGIC_VECTOR ( 11 downto 0);   -- reg address of the CSR
                                                           -- 11 is based on spec sheet (0xABC)
           CSR_WD: in STD_LOGIC_VECTOR (XLEN-1 downto 0);
           CSR_WEN: in STD_LOGIC; --for testing purposes to write to CSRs
           CSR_REN: in STD_LOGIC; --for testing purposes to read from CSRs
           --------------------------------------------
           --Control Registers OUTPUT:
           CSR_out: out STD_LOGIC_VECTOR (XLEN-1 downto 0);
           ---- 1) vtype fields:
           cu_vill: out STD_LOGIC;
           cu_vediv:out STD_LOGIC_VECTOR (1 downto 0);
           cu_vlmul: out STD_LOGIC_VECTOR(1 downto 0);  
           cu_sew: out STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0); 
           --- 2) vlenb fields:
           --vlenb has no fields; it is a read only register of value VLEN/8
           
           --- 3) vstart fields:
           --vstart specifies the index of the first element to be executed by an instruction
           cu_vstart: out STD_LOGIC_VECTOR(XLEN-1 downto 0);
           --- 4) vl fields:   

           cu_vl: out STD_LOGIC_VECTOR(XLEN-1 downto 0);      
           --vl has no fields; it is a read only register that holds the number of elements to be updated by an instruction
           --------------------------------------------
           --------------------------------------------
           -- Fields INPUT: (from decoder)
           cu_funct3:in STD_LOGIC_VECTOR(2 downto 0);
           cu_rs1: in STD_LOGIC_VECTOR(4 downto 0);
           cu_rs2: in STD_LOGIC_VECTOR(4 downto 0);
           cu_rd:  in STD_LOGIC_VECTOR(4 downto 0);
           cu_opcode : in STD_LOGIC_VECTOR (6 downto 0);
           cu_bit31: in STD_LOGIC; --used for vsetvl and vsetvli instructions
           --------------------------------------------
           -- vset Related Signals:
           cu_rs1_data: in STD_LOGIC_VECTOR( XLEN-1 downto 0);
           cu_rd_data: out STD_LOGIC_VECTOR (VLMAX-1 downto 0);
           --------------------------------------------
           --Control Signals OUTPUT:
           cu_WriteEn : out STD_LOGIC; -- enables write to the reg file
           cu_SrcB : out STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate
                                    -- 00 = vector reg
                                    -- 01 = scalar reg
                                    -- 10 = immediate
                                    -- 00 = ??
           cu_MemWrite : out STD_LOGIC;-- enables write to memory
           cu_MemRead: out STD_LOGIC; -- enables read from memory
           cu_WBSrc : out STD_LOGIC);-- selects if wrbsc is from ALU or mem 
                                     -- 0 = ALU
                                     -- 1 = Mem
           --------------------------------------------
end component;


--Signals 

 signal         clk_in: STD_LOGIC;
 signal         busy:  STD_LOGIC;          --------------------------------------------
           --------------------------------------------   
           --Control Registers INPUT:
 signal         CSR_Addr:  STD_LOGIC_VECTOR ( 11 downto 0);   -- reg address of the CSR                                                           -- 11 is based on spec sheet
 signal         CSR_WD:  STD_LOGIC_VECTOR (XLEN-1 downto 0);
 signal         CSR_WEN: STD_LOGIC;
 signal         CSR_REN: STD_LOGIC; 
            --Control Registers OUTPUT:
 signal         CSR_out:  STD_LOGIC_VECTOR (XLEN-1 downto 0);
           ---- 1) vtype fields:
 signal         vill:  STD_LOGIC;
 signal         vediv: STD_LOGIC_VECTOR (1 downto 0);
 signal         vlmul:  STD_LOGIC_VECTOR(1 downto 0);  
 signal         sew:  STD_LOGIC_VECTOR (lgSEW_MAX-1 downto 0);
  -------------------------------------------------------------
 signal         vstart: STD_LOGIC_VECTOR(XLEN-1 downto 0);
 signal         vl: STD_LOGIC_VECTOR(XLEN-1 downto 0);  
  ----CU inputs (from decoder)
 signal         funct3:STD_LOGIC_VECTOR(2 downto 0);
 signal         rs1:STD_LOGIC_VECTOR(4 downto 0);
 signal         rs2:STD_LOGIC_VECTOR(4 downto 0);
 signal         rd: STD_LOGIC_VECTOR(4 downto 0);
 signal         opcode : STD_LOGIC_VECTOR (6 downto 0);
 signal         bit31: STD_LOGIC; --used for vsetvl and vsetvli instructions
            --------------------------------------------
            -- vset Related Signals:
 signal           rs1_data:  STD_LOGIC_VECTOR( XLEN-1 downto 0);
 signal           rd_data:  STD_LOGIC_VECTOR (VLMAX-1 downto 0);
           --------------------------------------------
           --------------------------------------------
           --Control Signals OUTPUT:
 signal           WriteEn :  STD_LOGIC; -- enables write to the reg file
 signal           SrcB :  STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate
                                   -- 00 = vector reg
                                   -- 01 = scalar reg
                                   -- 10 = immediate
                                   -- 00 = ??
 signal           MemWrite :  STD_LOGIC;-- enables write to memory
 signal           MemRead:  STD_LOGIC; -- enables read from memory
 signal           WBSrc :  STD_LOGIC;-- selects if wrbsc is from ALU or mem 
                                     -- 0 = ALU
                                     -- 1 = Mem

begin

    G1: Control_Unit
    GENERIC MAP(XLEN,ELEN,VLEN,SEW_MAX,lgSEW_MAX,VLMAX,logVLMAX)
    PORT MAP(clk_in,busy,
     CSR_ADDR, CSR_WD, CSR_WEN, CSR_REN,
     CSR_out, vill, vediv, vlmul, sew, vstart, vl, 
     funct3, rs1, rs2, rd, opcode, bit31,
     rs1_data, rd_data, WriteEn, SrcB, MemWrite, MemRead, WBSrc);
    --Inputs: 
    --clk_in, busy, CSR_Addr, CSR_WD, cu_funct3, cu_rs1, cu_rs2, cu_rd,cu_opcode,
    clk_proc: process begin
        clk_in<='1';
        wait for 20ns;
        clk_in<='0'; 
        wait for 20ns;
    end process;

    process begin
        
        busy<= '0'; CSR_REN<='0'; CSR_WEN<='0'; wait for 80ns;    
        -- Case 1: Writing and reading to the CSRs
        CSR_Addr<=x"008"; CSR_WD<=x"00000001"; CSR_WEN<='1'; wait for 80ns;
        CSR_WEN<='0'; CSR_REN<='1'; CSR_Addr<=x"008"; wait for 40ns; CSR_REN<='0';
        -- Case 2: Testing an ALU instruction
        wait for 40ns; funct3<= "011"; rs1<= "00000"; rs2 <= "00000"; rd<= "00000"; opcode<="1010111"; bit31<='0'; wait for 40ns; 
        funct3<= "111"; rs1<= "00001"; bit31<='1'; rs1_data<= x"00000021"; 
        wait;
    end process;

end Behavioral;

