//Module: CPU
//Function: CPU is the top design of the RISC-V processor

//Inputs:
//	clk: main clock
//	arst_n: reset 
// enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory

// Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory

module cpu(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[63:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[63:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [63:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[63:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      63:0] branch_pc,updated_pc,current_pc,jump_pc;

wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      63:0] regfile_wdata,mem_data,alu_out,
                  regfile_rdata_1,regfile_rdata_2,
                  alu_operand_2;

wire signed [63:0] immediate_extended;

//IF/ID PIPELINE SIGNALS
wire [31:0] instruction;
wire [31:0] instruction_IF_ID;
wire [63:0] current_pc_IF_ID;

// ID/EX PIPELINE SIGNALS 
wire [63:0] regfile_rdata_1_ID_EX;
wire [63:0] regfile_rdata_2_ID_EX;
wire signed [63:0] immediate_extended_ID_EX;
wire [31:0] instruction_ID_EX;
wire [63:0] current_pc_ID_EX;
// control signals
wire        branch_ID_EX, mem_read_ID_EX, mem_2_reg_ID_EX;
wire        mem_write_ID_EX, alu_src_ID_EX, reg_write_ID_EX, jump_ID_EX;
wire [1:0]  alu_op_ID_EX;

// EX/MEM PIPELINE SIGNALS 
wire [63:0] alu_out_EX_MEM;
wire [63:0] regfile_rdata_2_EX_MEM;
wire        zero_flag_EX_MEM;
wire [31:0] instruction_EX_MEM;
wire [63:0] current_pc_EX_MEM;
wire [63:0] branch_pc_EX_MEM;
wire [63:0] jump_pc_EX_MEM;
// control signals
wire        branch_EX_MEM, mem_read_EX_MEM, mem_2_reg_EX_MEM;
wire        mem_write_EX_MEM, reg_write_EX_MEM, jump_EX_MEM;

//  MEM/WB PIPELINE SIGNALS 
wire [63:0] alu_out_MEM_WB;
wire [63:0] mem_data_MEM_WB;
wire [31:0] instruction_MEM_WB;
// control signals
wire        mem_2_reg_MEM_WB, reg_write_MEM_WB;

wire [1:0]  fw_a, fw_b;
wire [63:0] alu_in_0, alu_in_1;
wire        stall;


// IF STAGE START
pc #(
   .DATA_W(64)
) program_counter (
   .clk       (clk              ),
   .arst_n    (arst_n           ),
   .branch_pc (branch_pc_EX_MEM ),
   .jump_pc   (jump_pc_EX_MEM   ),
   .zero_flag (zero_flag_EX_MEM ),
   .branch    (branch_EX_MEM    ),
   .jump      (jump_EX_MEM      ),
   .current_pc(current_pc       ),
   .enable    (enable & ~stall  ),
   .updated_pc(updated_pc       )
);

sram_BW32 #(
   .ADDR_W(9)
) instruction_memory(
   .clk      (clk        ),
   .addr     (current_pc ),
   .wen      (1'b0       ),
   .ren      (1'b1       ),
   .wdata    (32'b0      ),
   .rdata    (instruction),
   .addr_ext (addr_ext   ),
   .wen_ext  (wen_ext    ),
   .ren_ext  (ren_ext    ),
   .wdata_ext(wdata_ext  ),
   .rdata_ext(rdata_ext  )
);
// IF STAGE END

// IF_ID REG START
reg_arstn_en #(
   .DATA_W(32)
) pipe_IF_ID_instruction (
   .clk    (clk              ),
   .arst_n (arst_n           ),
   .en     (enable & ~stall  ),
   .din    (instruction      ),
   .dout   (instruction_IF_ID)
);

reg_arstn_en #(
   .DATA_W(64)
) pipe_IF_ID_pc (
   .clk    (clk              ),
   .arst_n (arst_n           ),
   .din    (current_pc       ),
   .en     (enable & ~stall  ),
   .dout   (current_pc_IF_ID )
);
// IF_ID REG END

// ID STAGE START
register_file #(
   .DATA_W(64)
) register_file(
   .clk      (clk                      ),
   .arst_n   (arst_n                   ),
   .reg_write(reg_write_MEM_WB         ),
   .raddr_1  (instruction_IF_ID[19:15] ),
   .raddr_2  (instruction_IF_ID[24:20] ),
   .waddr    (instruction_MEM_WB[11:7] ),
   .wdata    (regfile_wdata            ),
   .rdata_1  (regfile_rdata_1          ),
   .rdata_2  (regfile_rdata_2          )
);

control_unit control_unit(
   .opcode   (instruction_IF_ID[6:0]),
   .alu_op   (alu_op                ),
   .reg_dst  (reg_dst               ),
   .branch   (branch                ),
   .mem_read (mem_read              ),
   .mem_2_reg(mem_2_reg             ),
   .mem_write(mem_write             ),
   .alu_src  (alu_src               ),
   .reg_write(reg_write             ),
   .jump     (jump                  )
);

immediate_extend_unit immediate_extend_u(
   .instruction        (instruction_IF_ID  ),
   .immediate_extended (immediate_extended )
);

hazard_detection_unit hazard_u(
   .rs1_IF_ID     (instruction_IF_ID[19:15]),
   .rs2_IF_ID     (instruction_IF_ID[24:20]),
   .rd_ID_EX      (instruction_ID_EX[11:7] ),
   .mem_read_ID_EX(mem_read_ID_EX          ),
   .stall         (stall                   )
);
// ID STAGE END

// ID_EX REG START
// data registers - frozen during stall
reg_arstn_en #(
   .DATA_W(64)
) pipe_ID_EX_rdata1 (
   .clk    (clk                   ),
   .arst_n (arst_n                ),
   .din    (regfile_rdata_1       ),
   .en     (enable & ~stall       ),
   .dout   (regfile_rdata_1_ID_EX )
);
reg_arstn_en #(
   .DATA_W(64)
) pipe_ID_EX_rdata2 (
   .clk    (clk                   ),
   .arst_n (arst_n                ),
   .din    (regfile_rdata_2       ),
   .en     (enable & ~stall       ),
   .dout   (regfile_rdata_2_ID_EX )
);
reg_arstn_en #(
   .DATA_W(64)
) pipe_ID_EX_imm (
   .clk    (clk                      ),
   .arst_n (arst_n                   ),
   .din    (immediate_extended       ),
   .en     (enable & ~stall          ),
   .dout   (immediate_extended_ID_EX )
);
reg_arstn_en #(
   .DATA_W(32)
) pipe_ID_EX_instruction (
   .clk    (clk               ),
   .arst_n (arst_n            ),
   .din    (instruction_IF_ID ),
   .en     (enable & ~stall   ),
   .dout   (instruction_ID_EX )
);
reg_arstn_en #(
   .DATA_W(64)
) pipe_ID_EX_pc (
   .clk    (clk              ),
   .arst_n (arst_n           ),
   .din    (current_pc_IF_ID ),
   .en     (enable & ~stall  ),
   .dout   (current_pc_ID_EX )
);

// control signal registers - bubble inserted during stall
reg_arstn_en #(
   .DATA_W(1)
) pipe_ID_EX_branch (
   .clk    (clk              ),
   .arst_n (arst_n           ),
   .din    (branch & ~stall  ),
   .en     (enable           ),
   .dout   (branch_ID_EX     )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_ID_EX_mem_read (
   .clk    (clk                ),
   .arst_n (arst_n             ),
   .din    (mem_read & ~stall  ),
   .en     (enable             ),
   .dout   (mem_read_ID_EX     )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_ID_EX_mem_2_reg (
   .clk    (clk                 ),
   .arst_n (arst_n              ),
   .din    (mem_2_reg & ~stall  ),
   .en     (enable              ),
   .dout   (mem_2_reg_ID_EX     )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_ID_EX_mem_write (
   .clk    (clk                 ),
   .arst_n (arst_n              ),
   .din    (mem_write & ~stall  ),
   .en     (enable              ),
   .dout   (mem_write_ID_EX     )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_ID_EX_alu_src (
   .clk    (clk               ),
   .arst_n (arst_n            ),
   .din    (alu_src & ~stall  ),
   .en     (enable            ),
   .dout   (alu_src_ID_EX     )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_ID_EX_reg_write (
   .clk    (clk                 ),
   .arst_n (arst_n              ),
   .din    (reg_write & ~stall  ),
   .en     (enable              ),
   .dout   (reg_write_ID_EX     )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_ID_EX_jump (
   .clk    (clk            ),
   .arst_n (arst_n         ),
   .din    (jump & ~stall  ),
   .en     (enable         ),
   .dout   (jump_ID_EX     )
);
reg_arstn_en #(
   .DATA_W(2)
) pipe_ID_EX_alu_op (
   .clk    (clk         ),
   .arst_n (arst_n      ),
   .din    (alu_op      ),
   .en     (enable      ),
   .dout   (alu_op_ID_EX)
);
// ID_EX REG END

// EX STAGE START
alu_control alu_ctrl(
   .func7_0    (instruction_ID_EX[25]   ),
   .func7_5    (instruction_ID_EX[30]   ),
   .func3      (instruction_ID_EX[14:12]),
   .alu_op     (alu_op_ID_EX            ),
   .alu_control(alu_control             )
);

fw_unit forwarding_unit(
   .rs1_ID_EX        (instruction_ID_EX[19:15]),
   .rs2_ID_EX        (instruction_ID_EX[24:20]),
   .rd_EX_MEM        (instruction_EX_MEM[11:7]),
   .rd_MEM_WB        (instruction_MEM_WB[11:7]),
   .reg_write_EX_MEM (reg_write_EX_MEM        ),
   .reg_write_MEM_WB (reg_write_MEM_WB        ),
   .alu_src_ID_EX    (alu_src_ID_EX           ),
   .forward_A        (fw_a                    ),
   .forward_B        (fw_b                    )
);

mux_2 #(
   .DATA_W(64)
) alu_operand_mux (
   .input_a (immediate_extended_ID_EX),
   .input_b (regfile_rdata_2_ID_EX   ),
   .select_a(alu_src_ID_EX           ),
   .mux_out (alu_operand_2           )
);

mux_3 #(
   .DATA_W(64)
) fw_mux_A (
   .input_a (regfile_rdata_1_ID_EX),
   .input_b (regfile_wdata        ),
   .input_c (alu_out_EX_MEM       ),
   .select  (fw_a                 ),
   .mux_out (alu_in_0             )
);

mux_3 #(
   .DATA_W(64)
) fw_mux_B (
   .input_a (alu_operand_2  ),
   .input_b (regfile_wdata  ),
   .input_c (alu_out_EX_MEM ),
   .select  (fw_b           ),
   .mux_out (alu_in_1       )
);

alu #(
   .DATA_W(64)
) alu(
   .alu_in_0 (alu_in_0   ),
   .alu_in_1 (alu_in_1   ),
   .alu_ctrl (alu_control),
   .alu_out  (alu_out    ),
   .zero_flag(zero_flag  ),
   .overflow (           )
);

branch_unit #(
   .DATA_W(64)
) branch_unit(
   .current_pc        (current_pc_ID_EX        ),
   .immediate_extended(immediate_extended_ID_EX),
   .branch_pc         (branch_pc               ),
   .jump_pc           (jump_pc                 )
);
// EX STAGE END

// EX_MEM REG START
reg_arstn_en #(
   .DATA_W(64)
) pipe_EX_MEM_alu_out (
   .clk    (clk            ),
   .arst_n (arst_n         ),
   .din    (alu_out        ),
   .en     (enable         ),
   .dout   (alu_out_EX_MEM )
);
reg_arstn_en #(
   .DATA_W(64)
) pipe_EX_MEM_rdata2 (
   .clk    (clk                    ),
   .arst_n (arst_n                 ),
   .din    (regfile_rdata_2_ID_EX  ),
   .en     (enable                 ),
   .dout   (regfile_rdata_2_EX_MEM )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_EX_MEM_zero (
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .din    (zero_flag       ),
   .en     (enable          ),
   .dout   (zero_flag_EX_MEM)
);
reg_arstn_en #(
   .DATA_W(32)
) pipe_EX_MEM_instruction (
   .clk    (clk                ),
   .arst_n (arst_n             ),
   .din    (instruction_ID_EX  ),
   .en     (enable             ),
   .dout   (instruction_EX_MEM )
);
reg_arstn_en #(
   .DATA_W(64)
) pipe_EX_MEM_branch_pc (
   .clk    (clk              ),
   .arst_n (arst_n           ),
   .din    (branch_pc        ),
   .en     (enable           ),
   .dout   (branch_pc_EX_MEM )
);
reg_arstn_en #(
   .DATA_W(64)
) pipe_EX_MEM_jump_pc (
   .clk    (clk           ),
   .arst_n (arst_n        ),
   .din    (jump_pc       ),
   .en     (enable        ),
   .dout   (jump_pc_EX_MEM)
);

reg_arstn_en #(
   .DATA_W(1)
) pipe_EX_MEM_branch (
   .clk    (clk           ),
   .arst_n (arst_n        ),
   .din    (branch_ID_EX  ),
   .en     (enable        ),
   .dout   (branch_EX_MEM )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_EX_MEM_mem_read (
   .clk    (clk             ),
   .arst_n (arst_n          ),
   .din    (mem_read_ID_EX  ),
   .en     (enable          ),
   .dout   (mem_read_EX_MEM )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_EX_MEM_mem_2_reg (
   .clk    (clk              ),
   .arst_n (arst_n           ),
   .din    (mem_2_reg_ID_EX  ),
   .en     (enable           ),
   .dout   (mem_2_reg_EX_MEM )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_EX_MEM_mem_write (
   .clk    (clk              ),
   .arst_n (arst_n           ),
   .din    (mem_write_ID_EX  ),
   .en     (enable           ),
   .dout   (mem_write_EX_MEM )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_EX_MEM_reg_write (
   .clk    (clk              ),
   .arst_n (arst_n           ),
   .din    (reg_write_ID_EX  ),
   .en     (enable           ),
   .dout   (reg_write_EX_MEM )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_EX_MEM_jump (
   .clk    (clk         ),
   .arst_n (arst_n      ),
   .din    (jump_ID_EX  ),
   .en     (enable      ),
   .dout   (jump_EX_MEM )
);
// EX_MEM REG END

// MEM STAGE START
sram_BW64 #(
   .ADDR_W(10)
) data_memory(
   .clk      (clk                    ),
   .addr     (alu_out_EX_MEM         ),
   .wen      (mem_write_EX_MEM       ),
   .ren      (mem_read_EX_MEM        ),
   .wdata    (regfile_rdata_2_EX_MEM ),
   .rdata    (mem_data               ),
   .addr_ext (addr_ext_2             ),
   .wen_ext  (wen_ext_2              ),
   .ren_ext  (ren_ext_2              ),
   .wdata_ext(wdata_ext_2            ),
   .rdata_ext(rdata_ext_2            )
);
// MEM STAGE END

// MEM_WB REG START
reg_arstn_en #(
   .DATA_W(64)
) pipe_MEM_WB_alu_out (
   .clk    (clk            ),
   .arst_n (arst_n         ),
   .din    (alu_out_EX_MEM ),
   .en     (enable         ),
   .dout   (alu_out_MEM_WB )
);
reg_arstn_en #(
   .DATA_W(64)
) pipe_MEM_WB_mem_data (
   .clk    (clk            ),
   .arst_n (arst_n         ),
   .din    (mem_data       ),
   .en     (enable         ),
   .dout   (mem_data_MEM_WB)
);
reg_arstn_en #(
   .DATA_W(32)
) pipe_MEM_WB_instruction (
   .clk    (clk                ),
   .arst_n (arst_n             ),
   .din    (instruction_EX_MEM ),
   .en     (enable             ),
   .dout   (instruction_MEM_WB )
);

reg_arstn_en #(
   .DATA_W(1)
) pipe_MEM_WB_mem_2_reg (
   .clk    (clk              ),
   .arst_n (arst_n           ),
   .din    (mem_2_reg_EX_MEM ),
   .en     (enable           ),
   .dout   (mem_2_reg_MEM_WB )
);
reg_arstn_en #(
   .DATA_W(1)
) pipe_MEM_WB_reg_write (
   .clk    (clk              ),
   .arst_n (arst_n           ),
   .din    (reg_write_EX_MEM ),
   .en     (enable           ),
   .dout   (reg_write_MEM_WB )
);
// MEM_WB REG END

// WB STAGE START
mux_2 #(
   .DATA_W(64)
) regfile_data_mux (
   .input_a (mem_data_MEM_WB  ),
   .input_b (alu_out_MEM_WB   ),
   .select_a(mem_2_reg_MEM_WB ),
   .mux_out (regfile_wdata    )
);
// WB STAGE END

endmodule