LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

package definitions is

    -- General Constants
    constant DATA_WIDTH : integer := 32;
    constant OPCODE_WIDTH : integer := 3;
    constant FUNCT_WIDTH : integer := 3;

    -- PC Constants
    constant PC_BIT_COUNT: integer := 32;

    -- Instruction Memory Constants
    constant INSTRUCTION_WIDTH : integer := 16;
    constant IC_SIZE : integer := 4096; -- Assume for now that the instruction cache is 4KB
    constant IC_ADDRESS_WIDTH : integer := 12;

    -- Register File Constants
    constant REGISTER_ADDRESS_WIDTH : integer := 3;
    constant REGISTER_COUNT : integer := 8;

    -- Data Memory Constants
    constant DM_DATA_WIDTH : integer := 16;
    constant DM_SIZE: integer := 4096; -- 4 KB = 2^12
    constant DM_ADDRESS_WIDTH : integer := 32;

    -- Exception Handler Constants
    constant EXCEPTION_HANDLER_ADDRESS : std_logic_vector(PC_BIT_COUNT - 1 downto 0) := x"00000300";

end package definitions;
