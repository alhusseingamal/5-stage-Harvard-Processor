library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX_4x1 is
    GENERIC (n : INTEGER := 8);
    Port (
        I0, I1, I2, I3 : in STD_LOGIC_VECTOR(n-1 downto 0);
        S : in STD_LOGIC_VECTOR(1 downto 0);
        F : out STD_LOGIC_VECTOR(n-1 downto 0)
    );
end MUX_4x1;

architecture Behavioral of MUX_4x1 is
begin
    process(I0, I1, I2, I3, S)
    begin
        case S is
            when "00" =>
                F <= I0;
            when "01" =>
                F <= I1;
            when "10" =>
                F <= I2;
            when "11" =>
                F <= I3;
            when others =>
                F <= I0;
        end case;
    end process;
end Behavioral;
