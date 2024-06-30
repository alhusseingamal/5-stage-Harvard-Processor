library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX_8x1 is
    GENERIC (n : INTEGER := 8);
    Port (
        I0, I1, I2, I3, I4, I5, I6, I7 : in STD_LOGIC_VECTOR(n-1 downto 0);
        S : in STD_LOGIC_VECTOR(2 downto 0);
        F : out STD_LOGIC_VECTOR(n-1 downto 0)
    );
end MUX_8x1;

architecture Behavioral of MUX_8x1 is
begin
    process(I0, I1, I2, I3, I4, I5, I6, I7, S)
    begin
        case S is
            when "000" =>
                F <= I0;
            when "001" =>
                F <= I1;
            when "010" =>
                F <= I2;
            when "011" =>
                F <= I3;
            when "100" =>
                F <= I4;
            when "101" =>
                F <= I5;
            when "110" =>
                F <= I6;
            when "111" =>
                F <= I7;
            when others =>
                F <= I0;
        end case;
    end process;
end Behavioral;