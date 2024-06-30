LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

entity InterruptUnit is
    port(
        clk : in std_logic;
        reset : in std_logic;
        interrupt : in std_logic;
        immediateOp : in std_logic;
        rtiOp : in std_logic;
        state : out std_logic_vector(1 downto 0);
        rtiPopCCR : out std_logic;
        rtiFlush : out std_logic;
        interrupt_on_imm : out std_logic
    );
end InterruptUnit;

architecture Behavioral of InterruptUnit is

-- INT FSM & Interrupt Latch signals
type int_fsm_state_type is (int_idle, int_halt, int_pushPC, int_pushCCR);
signal int_fsm_internal_state : int_fsm_state_type := int_idle;
signal int_trigger : std_logic := '0';

-- RTI FSM signals
type rti_fsm_state_type is (rti_popCCR, rti_popPC, rti_wait);
signal rti_fsm_internal_state : rti_fsm_state_type := rti_popCCR; -- popCCR state is equivalent to the idle state as well
signal rti_fsm_counter : unsigned(3 downto 0) := (others => '0');

begin
    -- If an interrupt arrives while an immediate operation is still at fetch, the immediate operation is not executed; the Opcode is zeroed out
    interrupt_on_imm <= '1' when (immediateOp = '1' and int_fsm_internal_state = int_pushPC) else '0';

    -- INT FSM & Interrupt Latch
    -- 1st Cycle: interrupt signal arrives, state: int_idle
    -- 2nd Cycle: push PC onto the stack, state: int_pushPC
    -- 3rd Cycle: push CCR onto the stack, state: int_pushCCR
    -- 4th Cycle: interrupt handler code is in the IF stage, state: int_idle
    process(clk, reset, interrupt)
    begin
        if reset = '1' then
            int_fsm_internal_state <= int_idle;
        elsif interrupt = '1' and int_fsm_internal_state /= int_halt then
            int_fsm_internal_state <= int_halt;
        elsif falling_edge(clk) then
            if (int_trigger = '1') then
                case int_fsm_internal_state is
                    when int_halt =>
                        int_fsm_internal_state <= int_pushPC;
                    when int_pushPC =>
                        int_fsm_internal_state <= int_pushCCR;
                    when int_pushCCR =>
                        int_fsm_internal_state <= int_idle;
                    when others =>
                        int_fsm_internal_state <= int_idle;
                end case;
            else
                int_fsm_internal_state <= int_idle;
            end if;
        end if;
    end process;

    int_trigger <= '1' when interrupt = '1' or (int_fsm_internal_state /= int_idle) else '0';
    state <= "10" when int_fsm_internal_state = int_pushPC else "11" when int_fsm_internal_state = int_pushCCR 
    else "01" when int_fsm_internal_state = int_halt else "00";

    -- RTI FSM
    -- Effectively, it counts to 4
    -- 0th cycle: Latching
    -- 1st cycle: popCCR
    -- 2nd cycle: popPC
    -- 3rd cycle: wait (counter = 1)
    -- 4th cycle: wait (counter = 2)
    process(clk, reset)
        begin
            if reset = '1' then
                rti_fsm_internal_state <= rti_popCCR;
            elsif falling_edge(clk) then
                if (rtiOp = '1' or rti_fsm_internal_state /= rti_popCCR) then
                    case (rti_fsm_internal_state) is
                        when rti_popCCR =>
                            rti_fsm_internal_state <= rti_popPC;
                        when rti_popPC =>
                            rti_fsm_internal_state <= rti_wait;
                        when rti_wait =>
                            if (rti_fsm_counter = 2) then
                                rti_fsm_internal_state <= rti_popCCR;
                                rti_fsm_counter <= (others => '0');
                            else
                                rti_fsm_internal_state <= rti_wait;
                                rti_fsm_counter <= rti_fsm_counter + 1;
                            end if;
                        when others =>
                            rti_fsm_internal_state <= rti_popCCR;
                    end case;
                end if;
            end if;
        end process;

        rtiPopCCR <= '1' when (rtiOp = '1' and rti_fsm_internal_state = rti_popCCR) else '0';
        rtiFlush <= '1' when rti_fsm_internal_state = rti_wait else '0';

end Behavioral;