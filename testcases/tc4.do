delete wave *
restart
add wave clk reset
add wave INSTRUCTION_IC INSTRUCTION_OUTPUT_IF_ID
add wave Forward_STD ALU_OUT_OUTPUT_EX_MEM WRITE_BACK_DATA STD_OUTPUT_ID_EX STD_INPUT_EX_MEM
add wave src1_OUTPUT_ID_EX src2_OUTPUT_ID_EX A_ALU B_ALU F_ALU ALU_OUT_OUTPUT_EX_MEM
add wave AluSrc_OUTPUT_ID_EX
radix -hexadecimal
mem load -i D:/archProject/phase3_v1/testcases/tc4.mem /processor/IC/memory_array
force -freeze sim:/processor/clk 1 0, 0 {500 ps} -r 1ns
force -freeze sim:/processor/reset 1 0
run 0.5ns
force -freeze sim:/processor/reset 0 0
run 10ns