library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CCR is
    port (
        clk, rst, enable: IN std_logic;
        i_ccr: IN std_logic_vector(3 downto 0);
        o_ccr: out std_logic_vector(3 downto 0)
    );
end entity CCR;

architecture ConditionCodeRegister of CCR is
    
begin
    process(clk, rst)
    begin
        if rst='1' then
            o_ccr <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                o_ccr <= i_ccr;
            end if;
        end if;
    end process;
    
end architecture ConditionCodeRegister;
