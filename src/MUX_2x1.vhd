library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX_2x1 is
    GENERIC (n : INTEGER := 8);
    Port (
        I0, I1 : in STD_LOGIC_VECTOR(n-1 downto 0);
        S : in STD_LOGIC;
        F : out STD_LOGIC_VECTOR(n-1 downto 0)
    );
end MUX_2x1;

architecture Behavioral of MUX_2x1 is
begin
    process(I0, I1, S)
    begin
        if S = '0' then
            F <= I0;
        else
            F <= I1;
        end if;
    end process;
end Behavioral;
