delete wave *
restart
add wave clk reset int INPUT_port_data OUTPUT_port_data exception_out
add wave i_instruction_IF_ID INSTRUCTION_IF_ID
add wave -position end sim:/GPR/R0 sim:/GPR/R1 sim:/GPR/R2 sim:/GPR/R3 sim:/GPR/R4 sim:/GPR/R5 sim:/GPR/R6 sim:/GPR/R7

radix -hexadecimal
mem load -i D:/archProject/phase3_v1/testcases/branching5.mem /processor/IC/memory_array
force -freeze sim:/processor/clk 1 0, 0 {500 ps} -r 1ns
force -freeze sim:/processor/reset 1 0
run 0.5ns
force -freeze sim:/processor/reset 0 0
run 14ns