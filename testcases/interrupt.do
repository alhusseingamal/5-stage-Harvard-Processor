delete wave *
restart
add wave clk reset int
add wave ADDRESS_IC INSTRUCTION_IC INSTRUCTION_OUTPUT_IF_ID i_IF_ID_PC
add wave pc_current pc_next PC_INPUT PC_IF_ID PC_ID_EX PC_EX_MEM
add wave PC_MUX2_select Opcode_CU
add wave o_interrupt_latch interrupt_fsm_state i_DM SP_address

radix -hexadecimal
mem load -i D:/archProject/phase3_v1/testcases/interrupt.mem /processor/IC/memory_array
force -freeze sim:/processor/clk 1 0, 0 {500 ps} -r 1ns
force -freeze sim:/processor/reset 1 0
force -freeze sim:/processor/int 0 0
run 0.5ns
force -freeze sim:/processor/reset 0 0
run 6ns
force -freeze sim:/processor/int 1 0
run 1ns
force -freeze sim:/processor/int 0 0
run 10ns