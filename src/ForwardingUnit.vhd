library ieee;
use ieee.std_logic_1164.all;

entity ForwardingUnit is
    port (
        MEM_WB_RegWrite1 : in std_logic;
        EX_MEM_RegWrite1 : in std_logic;
        ID_EX_Rs : in std_logic_vector(2 downto 0);
        ID_EX_Rt : in std_logic_vector(2 downto 0);
        ID_EX_RsRead : in std_logic;
        ID_EX_RtRead : in std_logic;
        EX_MEM_Rd : in std_logic_vector(2 downto 0);
        MEM_WB_Rd : in std_logic_vector(2 downto 0);
        EX_MEM_Rt : in std_logic_vector(2 downto 0);
        MEM_WB_Rt : in std_logic_vector(2 downto 0);
        MEM_WB_RegWrite2 : in std_logic;
        EX_MEM_RegWrite2 : in std_logic;
        EX_MEM_SwapOp : in std_logic;
        MEM_WB_SwapOp : in std_logic;

        -- STD
        ID_EX_MemWrite : in std_logic;
        ID_EX_AluSrc : in std_logic;

        -- Outputs
        ForwardA : out std_logic_vector(2 downto 0);
        ForwardB : out std_logic_vector(2 downto 0);
        ForwardSTD : out std_logic_vector (1 downto 0)
    );
end entity ForwardingUnit;

architecture behavior of ForwardingUnit is

SIGNAL isSTDInstruction : std_logic;

begin

isSTDInstruction <= (ID_EX_RtRead and ID_EX_MemWrite and ID_EX_AluSrc);

-- Rs
ForwardA <= 

            -- EX/MEM.ALU_OUT
            "010" when EX_MEM_RegWrite1 = '1' and ID_EX_RsRead = '1'
                and ((EX_MEM_Rd = ID_EX_Rs and EX_MEM_SwapOp = '0')
                or (EX_MEM_Rt = ID_EX_Rs and EX_MEM_SwapOp = '1'))
                else
                        
            -- EX/MEM.Rt.DATA
            "110" when EX_MEM_SwapOp = '1' and EX_MEM_RegWrite1 = '1' and ID_EX_RsRead = '1' and EX_MEM_Rd = ID_EX_Rs
                else

            -- MEM/WB.WB_DATA
            "001" when MEM_WB_RegWrite1 = '1' and MEM_WB_Rd = ID_EX_Rs and ID_EX_RsRead = '1'
                and not (EX_MEM_RegWrite1 = '1' and EX_MEM_Rd = ID_EX_Rs) -- to prioritize the EX/MEM stage over MEM/WB stage
                else

            -- MEM/WB.ALU_OUT
            "101" when MEM_WB_SwapOp = '1' and MEM_WB_RegWrite2 = '1' and ID_EX_RsRead = '1' and MEM_WB_Rt = ID_EX_Rs
                and not (EX_MEM_RegWrite2 = '1' and EX_MEM_Rt = ID_EX_Rs) -- to prioritize the EX/MEM stage over MEM/WB stage
                else
            
            -- Default Case
            "000";

-- Rt
ForwardB <= 
            -- EX/MEM.ALU_OUT
            "010" when (EX_MEM_RegWrite1 = '1' and ID_EX_RtRead = '1'
            and ((EX_MEM_Rd = ID_EX_Rt and EX_MEM_SwapOp = '0')
            or (EX_MEM_Rt = ID_EX_Rt and EX_MEM_SwapOp = '1')))
            and not (isSTDInstruction = '1') -- to exclude STD
            else

            -- EX/MEM.Rt.DATA
            "110" when (EX_MEM_SwapOp = '1' and EX_MEM_RegWrite2 = '1' and ID_EX_RtRead = '1' and EX_MEM_Rd = ID_EX_Rt)
            and not (isSTDInstruction = '1') -- to exclude STD
            else

            -- MEM/WB.WB_DATA
            "001" when MEM_WB_RegWrite1 = '1' and MEM_WB_Rd = ID_EX_Rt and ID_EX_RtRead = '1'
            and not (isSTDInstruction = '1') -- to exclude STD
            else
            
            -- MEM/WB.ALU_OUT
            "101" when MEM_WB_SwapOp = '1' and MEM_WB_RegWrite2 = '1' and MEM_WB_Rt = ID_EX_Rt and ID_EX_RtRead = '1'
            and not (EX_MEM_RegWrite2 = '1' and EX_MEM_Rt = ID_EX_Rt)
            and not (isSTDInstruction = '1') -- to exclude STD
            else
            
            -- Default Case
            "000";

-- Store instruction (STD) forwarding

ForwardSTD <=
            -- EX/MEM.ALU_OUT
            "10" when (
            (EX_MEM_RegWrite1 = '1' and EX_MEM_Rd = ID_EX_Rt) -- to check that we are writing to the register and that the registers are matching
            and (isSTDInstruction = '1') -- to check for STD instruction
            )
            else

            -- MEM/WB.WB_DATA
            "01" when (
            (MEM_WB_RegWrite1 = '1' and MEM_WB_Rd = ID_EX_Rt)
            and (isSTDInstruction = '1') -- to check for STD instruction
            and not(EX_MEM_RegWrite1 = '1' and EX_MEM_Rd = ID_EX_Rt)) -- To prioritize the EX/MEM stage over MEM/WB stage
            else

            -- Default Case
            "00";

end architecture behavior;