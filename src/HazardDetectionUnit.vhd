library ieee;
use ieee.std_logic_1164.all;

entity HazardDetectionUnit is
    port (
        EX_MemRead : in std_logic;
        EX_RegWrite1 : in std_logic;
        ID_IsBranch : in std_logic;
        ID_RegRead : in std_logic;
        EX_Rd : in std_logic_vector(2 downto 0);
        ID_Rt : in std_logic_vector(2 downto 0);
        ID_Rs : in std_logic_vector(2 downto 0);
        ID_Stall : out std_logic;
        DO_NOT_PREDICT : out std_logic

        -- Does the swap instruction need any special handling? If so, then we will need those 2 signals. For now, I don't think we need them.
        -- EX_RegWrite2 : in std_logic;
        -- EX_Rt : in std_logic_vector(2 downto 0);
    );
end entity HazardDetectionUnit;

architecture behavioral of HazardDetectionUnit is

begin

ID_Stall <=
    '1' when (EX_MemRead = '1' and EX_RegWrite1 = '1') -- A load instruction that writes to a register
    and ((EX_Rd = ID_Rs) or (EX_Rd = ID_Rt)) -- The register written by the load instruction is the same as the register read by the next instruction
    else '0';
DO_NOT_PREDICT <= '1'
    when (ID_IsBranch = '1' and ID_RegRead = '1' -- A branch instruction that reads a register
    and (ID_Rs = EX_Rd)) -- The register read by the branch instruction is the same as the register written by the previous instruction
    else '0';
end behavioral;