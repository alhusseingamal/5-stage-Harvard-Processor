delete wave *
restart
add wave clk reset
add wave Predictor_toggle_signal PREDICTOR_OUTPUT
add wave INSTRUCTION_IC INSTRUCTION_OUTPUT_IF_ID
add wave EX_PC_MUX_SELECT_SIGNAL
add wave PC_BRANCHING_MUX_SELECT_1 PREDICTED_INPUT_ID_EX PC_BRANCHING_MUX_SELECT
add wave PC_OUTPUT PC_INPUT PC_INPUT_IF_ID ADDRESS_IC
add wave data_out1 NEXT_PC BU_EX_RETURNED_ADDRESS
add wave FLUSH_IF_ID PREDICTION_IS_WRONG
//add wave A_ALU B_ALU F_ALU SEL_ALU FLAGS_OUTPUT_CCR
add wave WRITE_BACK_DATA

radix -hexadecimal
mem load -i D:/archProject/phase3_v1/testcases/branching1.mem /processor/IC/memory_array
force -freeze sim:/processor/clk 1 0, 0 {500 ps} -r 1ns
force -freeze sim:/processor/reset 1 0
force -freeze sim:/processor/int 0 0
run 0.5ns
force -freeze sim:/processor/reset 0 0
run 14ns