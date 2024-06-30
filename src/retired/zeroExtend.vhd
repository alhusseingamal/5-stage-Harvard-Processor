LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;
use work.definitions.all;

entity zeroExtend is
    port(
        input_in : in std_logic_vector(15 downto 0);
        output_out : out std_logic_vector(31 downto 0)
    );
end zeroExtend;

architecture behavioral of zeroExtend is
begin
    output_out <= ("0000000000000000" & input_in);
end behavioral;

-- Zero-extend a 16-bit input to a 32-bit output