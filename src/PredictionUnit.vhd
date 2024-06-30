LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

 entity PredictionUnit is
    Port(
         clk, rst: IN std_logic;
         ID_EX_JMP_TYPE : IN std_logic;
         Prediction_is_wrong : IN std_logic;
         currentprediction : INOUT std_logic
    );
 end PredictionUnit;

 Architecture Behavioral of PredictionUnit is
    signal toggle_signal : std_logic;
    begin
        toggle_signal <= ID_EX_JMP_TYPE AND Prediction_is_wrong;
        process(clk, rst)
        begin
            if rst='1' then
                currentprediction <= '0'; -- initial prediction = untaken
            elsif rising_edge(clk) then
                if toggle_signal = '1' then
                    currentprediction <= not currentprediction;
                end if;
            end if;
        end process;

   end Behavioral;