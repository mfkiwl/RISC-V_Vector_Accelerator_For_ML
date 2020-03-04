----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/29/2020 11:22:56 AM
-- Design Name: 
-- Module Name: Top_Level - Behavioral
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

entity Controller is

    generic (
        XLEN:integer:=32; --Register width
        ELEN:integer:=32; --Maximum element width
        VLEN:integer:=32;
        SEW_MAX:integer:=5;
        VLMAX: integer :=32;
        logVLMAX: integer := 5
    );
    
    Port (
    ------------------------------------------------  
    ------------------------------------------------  
    -- INPUTS
    clk_in:in STD_LOGIC;
    busy: in STD_LOGIC;    
    ------------------------------------------------  
    vect_inst : in STD_LOGIC_VECTOR (31 downto 0);
    
    CSR_Addr: in STD_LOGIC_VECTOR ( 11 downto 0);   -- reg address of the CSR                                                         -- 11 is based on spec sheet
    CSR_WD: in STD_LOGIC_VECTOR (XLEN-1 downto 0); 
    CSR_WEN: in STD_LOGIC;
    CSR_REN: in STD_LOGIC;  
    rs1_data: in STD_LOGIC_VECTOR( XLEN-1 downto 0);   
    ------------------------------------------------   
    ------------------------------------------------      
    -- OUTPUTS  
    rd_data: out STD_LOGIC_VECTOR (VLMAX-1 downto 0);    
    WriteEn : out STD_LOGIC; -- enables write to the reg file
    SrcB : out STD_LOGIC_VECTOR(1 downto 0); -- selects between scalar/vector reg or immediate
                                                -- 00 = vector reg
                                                -- 01 = scalar reg
                                                -- 10 = immediate
                                                -- 00 = ??
    MemWrite : out STD_LOGIC;                -- enables write to memory
    MemRead: out STD_LOGIC;                  -- enables read from memory
    WBSrc : out STD_LOGIC;                    -- selects if wrbsc is from ALU or mem 
                                                -- 0 = ALU
                                                -- 1 = Mem    
    CSR_out: out STD_LOGIC_VECTOR (XLEN-1 downto 0);
    ---- 1) vtype fields:
    vill: out STD_LOGIC;
    vediv:out STD_LOGIC_VECTOR (1 downto 0);
    vlmul: out STD_LOGIC_VECTOR(1 downto 0);  
    sew: out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0);
    vstart: out STD_LOGIC_VECTOR(XLEN-1 downto 0);
    vl: out STD_LOGIC_VECTOR(XLEN-1 downto 0);      
    ------------------------------------------------------------------------
    funct6 : out STD_LOGIC_VECTOR (5 downto 0);
    nf : out STD_LOGIC_VECTOR (2 downto 0);
    mop : out STD_LOGIC_VECTOR (2 downto 0);
    vm : out STD_LOGIC;
    vs2_rs2 : out STD_LOGIC_VECTOR (4 downto 0);
    rs1 : out STD_LOGIC_VECTOR (4 downto 0);
    funct3_width : out STD_LOGIC_VECTOR (2 downto 0);
    vd_vs3 : out STD_LOGIC_VECTOR (4 downto 0)                                                 
    );
end Controller;

architecture Behavioral of Controller is

component Control_Unit is

    generic (
        XLEN:integer:=32; --Register width
        ELEN:integer:=32; --Maximum element width
        VLEN:integer:=32;
        SEW_MAX:integer:=5;
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
                                                           -- 11 is based on spec sheet
           CSR_WD: in STD_LOGIC_VECTOR (XLEN-1 downto 0);
           CSR_WEN: in STD_LOGIC;
           CSR_REN: in STD_LOGIC; 
           --------------------------------------------
           --Control Registers OUTPUT:
           CSR_out: out STD_LOGIC_VECTOR (XLEN-1 downto 0);
           ---- 1) vtype fields:
           cu_vill: out STD_LOGIC;
           cu_vediv:out STD_LOGIC_VECTOR (1 downto 0);
           cu_vlmul: out STD_LOGIC_VECTOR(1 downto 0);  
           cu_sew: out STD_LOGIC_VECTOR (SEW_MAX-1 downto 0); 
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

component Decoder is
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


--Signals 
           -- Fields INPUT: (from decoder)
 signal           funct3_sig: STD_LOGIC_VECTOR(2 downto 0);
 signal           rs1_sig:  STD_LOGIC_VECTOR(4 downto 0);
 signal           rs2_sig:  STD_LOGIC_VECTOR(4 downto 0);
 signal           rd_sig:   STD_LOGIC_VECTOR(4 downto 0);
 signal           opcode_sig :  STD_LOGIC_VECTOR (6 downto 0);
 signal           bit31_sig:  STD_LOGIC; --used for vsetvl and vsetvli instructions
           --------------------------------------------
           --------------------------------------------
begin

Dec: Decoder PORT MAP (vect_inst,funct6,bit31_sig,nf,mop,vm,rs2_sig,rs1_sig,funct3_sig,rd_sig,opcode_sig);
CU:  Control_Unit 
GENERIC MAP(XLEN,ELEN,VLEN,SEW_MAX,VLMAX,logVLMAX)
PORT MAP (clk_in,busy,CSR_Addr,CSR_WD,CSR_WEN, CSR_REN, CSR_out,vill,vediv,vlmul,sew,vstart,vl,funct3_sig,rs1_sig,rs2_sig,rd_sig,opcode_sig,bit31_sig,rs1_data,rd_data,WriteEn,SrcB,MemWrite,MemRead,WBSrc);

funct3_width<=funct3_sig;
rs1<=rs1_sig;
vs2_rs2<=rs2_sig;
vd_vs3<=rd_sig;

end Behavioral;
