library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.definitions.all;

entity ProgramCounter is
port(
    clk : in std_logic;
    reset: in std_logic := '0';
    enable: in std_logic := '1';
    INT_STATE : in std_logic_vector(1 downto 0);
    RET_RTI_SIGNAL : in std_logic;
    RET_RTI_ADDRESS : in std_logic_vector(PC_BIT_COUNT - 1 downto 0);
    EXCEPTION_SIGNAL : in std_logic;
    EXCEPTION_HANDLED : in std_logic;
    EXCEPTION_RETURN_ADDRESS : in std_logic_vector(PC_BIT_COUNT - 1 downto 0);
    COUNT_IN : in std_logic_vector(PC_BIT_COUNT - 1 downto 0) := (others => '0');
    COUNT_OUT: out std_logic_vector(PC_BIT_COUNT - 1 downto 0) := (others => '0')
);
end entity;

architecture behavioral of ProgramCounter is
begin

process(clk, enable, reset) is
    begin
        if(reset = '1') then
            COUNT_OUT <= (others => '0');
        end if;
        if (falling_edge(clk) and enable = '1') then
            if (EXCEPTION_SIGNAL = '1') then
                COUNT_OUT <= EXCEPTION_HANDLER_ADDRESS;                   -- Exception Handler Address Hardcoded; see definitions.vhd
            elsif (EXCEPTION_HANDLED = '1') then
                COUNT_OUT <= EXCEPTION_RETURN_ADDRESS;
            elsif (RET_RTI_SIGNAL = '1') then
                COUNT_OUT <= RET_RTI_ADDRESS;
            else
                COUNT_OUT <= COUNT_IN;
            end if;
        end if;
    end process;

end architecture;


