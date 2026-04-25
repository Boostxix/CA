module fw_unit(
    input wire [4:0] rs1_ID_EX,
    input wire [4:0] rs2_ID_EX,
    input wire [4:0] rd_EX_MEM,
    input wire [4:0] rd_MEM_WB,
    input wire reg_write_EX_MEM,
    input wire reg_write_MEM_WB,
    input wire alu_src_ID_EX,
    output reg [1:0] forward_A,
    output reg [1:0] forward_B
);

always @(*) begin
    if (reg_write_EX_MEM && (rd_EX_MEM != 0) && (rd_EX_MEM == rs1_ID_EX)) begin
    forward_A = 2'b10; 
    end else if (reg_write_MEM_WB && (rd_MEM_WB != 0) && (rd_MEM_WB == rs1_ID_EX) && 
                !(reg_write_EX_MEM && (rd_EX_MEM != 0) && (rd_EX_MEM == rs1_ID_EX))) begin
        forward_A = 2'b01; 
    end else begin
        forward_A = 2'b00; 
    end

    // forward_B: only forward if using register, don't forward if using immediate !! 
   if (!alu_src_ID_EX && reg_write_EX_MEM && (rd_EX_MEM != 0) && (rd_EX_MEM == rs2_ID_EX))
      forward_B = 2'b10;
   else if (!alu_src_ID_EX && reg_write_MEM_WB && (rd_MEM_WB != 0) && (rd_MEM_WB == rs2_ID_EX) &&
      !(reg_write_EX_MEM && (rd_EX_MEM != 0) && (rd_EX_MEM == rs2_ID_EX)))
      forward_B = 2'b01;
   else
      forward_B = 2'b00;
end

endmodule
