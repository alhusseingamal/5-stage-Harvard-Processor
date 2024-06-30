LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;
use work.definitions.all;

entity signExtend is
    port(
        isUnsignedImmVal: in std_logic; 
        input_in : in std_logic_vector(15 downto 0);
        output_out : out std_logic_vector(31 downto 0)
    );
end signExtend;

architecture behavioral of signExtend is
begin
    output_out <= ("0000000000000000" & input_in) when
    input_in(15) = '0'
    or (isUnsignedImmVal = '1')
    else
    ("1111111111111111" & input_in);
end behavioral;

-- a +ve number is sign extended with zeros
-- the operand of a LDM instruction is an unsigned 16-bit number, so it is zero-extended
-- a -ve number is sign extended with ones