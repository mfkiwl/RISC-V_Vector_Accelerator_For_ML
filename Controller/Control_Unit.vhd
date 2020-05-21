library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--The Control Unit decides the control signals based on the opcode
entity Control_Unit is

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
           
           --Clock, Busy and newInst Signals INPUT:
           clk_in:in STD_LOGIC;
           busy: in STD_LOGIC; --might not need it currently. Needed for later improvements
           newInst: in STD_LOGIC; --signals that a new instruction came. Might be set internally based on the instruction changing.
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
           cu_mop : in STD_LOGIC_VECTOR (2 downto 0);  
           cu_bit31: in STD_LOGIC; --used for vsetvl and vsetvli instructions
           cu_zimm: in STD_LOGIC_VECTOR(10 downto 0);
           --------------------------------------------
           -- vset Related Signals:
           cu_rs1_data: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
           cu_rs2_data: in STD_LOGIC_VECTOR(XLEN-1 downto 0);
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
           cu_WBSrc : out STD_LOGIC;-- selects if wrbsc is from ALU or mem 
                                     -- 0 = ALU
                                     -- 1 = Mem
           cu_extension: out STD_LOGIC; -- goes to memory
                                        -- 0 if zero extended
                                        -- 1 if sign extended    
           cu_addrmode: out STD_LOGIC_VECTOR(1 downto 0); -- goes to memory lane
                                                          -- 00 if unit stride    
                                                          -- 01 if strided
                                                          -- 10 if indexed (unordered in case of a store)
                                                          -- 11 if indexed (ordered in case of a store)
           cu_memwidth: out STD_LOGIC_VECTOR(lgSEW_MAX downto 0); -- goes to memory 
                                                                 -- number of bits/transfer   
           cu_NI_1: out STD_LOGIC; --new instruction on Lane 1
           cu_NI_2: out STD_LOGIC --new instruction on Lane 2
           --------------------------------------------
           );
end Control_Unit;


architecture CU_arch of Control_Unit is

function minimum(X: in std_logic_vector ;Y: in std_logic_vector) return std_logic_vector is
begin
    if (X>Y) then
        return Y;
    else return X;
    end if;
end minimum;

--ALU opcode  : 1010111  
--Load opcode : 0000111  
--Store opcode: 0100111 
-- funct3 = 111 is reserved for vsetvl and vsetvli instructions
    type registers is array(0 to 5) of std_logic_vector(XLEN-1 downto 0); 
    -- 0  vstart 0x008
    -- 1  vxsat  0x009
    -- 2  vxrm   0x00A
    -- 3  vl     0xC20
    -- 4  vtype  0xC21
    -- 5  vlenb  0xC22
    signal CSR : registers;
    signal vtype,vlenb,vstart,vl,vxrm,vxsat: STD_LOGIC_VECTOR(XLEN-1 downto 0 );--CSR output signals for readability
    
    --newInst logic:
    signal counter: STD_LOGIC:='0'; --Lane1: reset if counter is 0.(might need to flip 0 and 1); Lane2: reset if counter is 1
    type myState is (S_1, S_2);
    signal state, next_state: myState;
    
begin
    -- set CSR values (implementation-defined)
    --CSR output signals for readability
    vstart<= CSR(0);
    vxsat<= CSR(1);
    vxrm<= CSR(2);
    vl<= CSR(3);
    vtype<= CSR(4);
    vlenb<= CSR(5);
    
    cu_vstart <= CSR(0);
    cu_vl <= CSR(3);
    
    
    --Divide vtype to its respective fields        
    -- vtype fields:
    cu_vill <= vtype(31);
    --Bits 30 downto 7 are reserved
    cu_vediv<= vtype( 6 downto 5);
    -- SEW Decoding according to Table 3
    -- SEW_MAX the width of the integer in bits
    cu_sew<=  std_logic_vector(to_unsigned(2**(to_integer(unsigned(vtype( 4 downto 2)))+3),lgSEW_MAX));
    cu_vlmul<= vtype( 1 downto 0);
    
    
    --Process for CSRs
    process (clk_in)
    begin 
        CSR_out<=(others=>'0'); --prevent accidental latches
    ----------------------------------------------------------
   --Second, we manage the read and write 
        if (rising_edge(clk_in)) then 
            if(CSR_WEN='0' and busy='0' and CSR_REN='0') then CSR(0) <= (others=>'0'); end if;  --All vector instructions, including vsetvl{i}, reset the vstart CSR to zero.
            case CSR_Addr is
                when x"008" => 
                    if (CSR_WEN='1' and busy='0') then
                        CSR(0)<=CSR_WD;                      
                    else if(CSR_REN='1') then CSR_out<=vstart; end if;
                    end if;
                when x"009" => 
                    if (CSR_WEN='1' and busy='0') then
                        CSR(1)<=CSR_WD;                      
                    else  if(CSR_REN='1') then CSR_out<=vxsat; end if;
                    end if;
                when x"00A" =>
                    if (CSR_WEN='1' and busy='0') then
                        CSR(2)<=CSR_WD;                      
                    else if(CSR_REN='1') then CSR_out<=vxrm; end if;  
                    end if;             
                when x"C20" => if(CSR_REN='1') then CSR_out<=vl; end if;
                when x"C21" => if(CSR_REN='1') then CSR_out<=vtype; end if;
                when x"C22" => if(CSR_REN='1') then CSR_out<=vlenb; end if; 
                when others => if(CSR_REN='1') then CSR_out<=(others=>'0'); end if;             
            end case;       
        end if;
    end process;
    
    
    ----------------------------------------------------------
    ----------------------------------------------------------       
    --Process for Control Signals (combinational)
    process(busy, cu_opcode, cu_funct3) 
    begin
        cu_WriteEn<='0'; --prevent accidental latches
        cu_MemWrite<='0'; 
        cu_MemRead<='0';
        cu_SrcB<="00"; -- dont care
        cu_WBSrc<='0'; -- dont care                  
        if (busy='0') then
            case cu_opcode is
            --Case 1: ALU Operation
                when "1010111" => cu_WriteEn<='1';
                                  cu_MemWrite<='0';
                                  cu_WBSrc<='0';
                                  cu_MemRead<='0';
                                  
                                  case cu_funct3 is --determine srcB based on funct3 field
                                     when "011" => cu_SrcB <="10";
                                     --011 = vector-immediate
                                     when "000" | "001" | "010" =>cu_SrcB <="00";
                                     -- 000,001,010 are vector-vector operations
                                     when "100" | "101"| "110" => cu_SrcB<="01";
                                     --100,101,110 are vector-scalar operations
                                     when others => cu_WriteEn<='0';
                                                    cu_MemWrite<='0'; 
                                                    cu_MemRead<='0';
                                                    cu_SrcB<="00";
                                                    cu_WBSrc<='0'; 
                                 end case;
                                 
            --Case 2: Load Operation
                when "0000111" => cu_WriteEn<='1';
                                 cu_MemWrite<='0'; 
                                 cu_MemRead<='1';
                                 cu_SrcB<="00";
                                 cu_WBSrc<='1';
                                 if (cu_mop="000" or cu_mop="010" or cu_mop="011") then --load mop addressing
                                      cu_extension<='0'; 
                                 elsif(cu_mop="100" or cu_mop="110" or cu_mop="111") then
                                      cu_extension<='1';                                                       
                                 end if; 
                                 cu_addrmode<=cu_mop(1 downto 0);
                                 if (cu_funct3="000")then -- 8 bits/transfer
                                    cu_memwidth<="001000";
                                 elsif (cu_funct3="101")then -- 16 bits/transfer
                                    cu_memwidth<="010000";   
                                 elsif (cu_funct3="110")then -- 32 bits/transfer
                                    cu_memwidth<="100000"; 
                                 elsif (cu_funct3="111")then -- sew bits/transfer 
                                    cu_memwidth(lgSEW_MAX)<='0';
                                    cu_memwidth(lgSEW_MAX-1 downto 0)<=std_logic_vector(to_unsigned(2**(to_integer(unsigned(vtype( 4 downto 2)))+3),lgSEW_MAX));                                                                       
                                 end if;                                                                                                                                                       
             --Case 3: Store Operation
                when "0100111" => cu_WriteEn<='0';
                                 cu_MemWrite<='1';
                                 cu_MemRead<='0';
                                 cu_SrcB<="00";
                                 cu_WBSrc<='0'; 
                                 cu_addrmode<=cu_mop(1 downto 0); 
                                 if (cu_funct3="000")then -- 8 bits/transfer
                                    cu_memwidth<="001000";
                                 elsif (cu_funct3="101")then -- 16 bits/transfer
                                    cu_memwidth<="010000";   
                                 elsif (cu_funct3="110")then -- 32 bits/transfer
                                    cu_memwidth<="100000"; 
                                 elsif (cu_funct3="111")then -- sew bits/transfer 
                                    cu_memwidth(lgSEW_MAX)<='0';
                                    cu_memwidth(lgSEW_MAX-1 downto 0)<=std_logic_vector(to_unsigned(2**(to_integer(unsigned(vtype( 4 downto 2)))+3),lgSEW_MAX));                                                                       
                                 end if; 
                                 
                when others   => cu_WriteEn<='0';
                                 cu_MemWrite<='0'; 
                                 cu_MemRead<='0';
                                 cu_SrcB<="00";
                                 cu_WBSrc<='0'; 
            end case;
        end if;
    end process;
    
    --synchronous process for vsetvl and vsetvli
    process(clk_in, busy, cu_bit31, cu_rs1, cu_rs1_data, cu_opcode, cu_funct3)
    begin
        if(busy= '0' and cu_opcode="1010111" and cu_funct3="111" and rising_edge(clk_in)) then
            if (cu_rs1/="00000") then
                -- new vl is in rs1 reg; read it and write it to rd reg and vl
                cu_rd_data<=minimum(cu_rs1_data,std_logic_vector(to_unsigned(VLMAX,VLMAX)));
                CSR(3)<=minimum(cu_rs1_data,std_logic_vector(to_unsigned(VLMAX,VLMAX)));
            elsif (cu_rs1="00000" AND cu_rd /="00000") then
                -- set vl to VLMAX and write VLMAX to rd
                cu_rd_data<= std_logic_vector(to_unsigned(VLMAX,VLMAX));-- converting VLMAX integer to std_logic_vector
                CSR(3)<= std_logic_vector(to_unsigned(VLMAX,VLMAX));    -- vl takes VLMAX
            elsif (cu_rs1="00000" AND cu_rd="00000") then --change vtype without changing vl
                if (cu_bit31='1') then
                    CSR(4)<= cu_rs2_data; --vtype takes data in rs2
                else CSR(4)(6 downto 0)<= cu_zimm(6 downto 0);
                end if;
            end if; 
        end if;
    end process;
    
    --FSM for setting and desetting newInst sent to execution units
    process(clk_in) begin
        if(rising_edge(clk_in)) then 
            if(newInst='1') then --reset 
                state<= S_1; 
                counter<= counter xor '1'; --toggle counter 
            else
                state<= next_state;  
            end if;	
            
        end if;
    end process;
    
    process(counter, state) begin
        case(state) is 
            when S_1 => 
                if(counter='1') then cu_NI_1<= '1'; 
                else cu_NI_2<= '1';
                end if;
                next_state<= S_2;
            
            when S_2 => cu_NI_1<= '0'; cu_NI_2<= '0';
        end case;
    end process;
    
end CU_arch;
