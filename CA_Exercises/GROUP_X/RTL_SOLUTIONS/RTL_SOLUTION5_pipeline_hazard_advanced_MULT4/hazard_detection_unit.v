module hazard_detection_unit(
   input  wire [4:0] rs1_IF_ID,
   input  wire [4:0] rs2_IF_ID,
   input  wire [4:0] rd_ID_EX,
   input  wire       mem_read_ID_EX,
   output reg        stall
);
   always @(*) begin
      if (mem_read_ID_EX &&
         ((rd_ID_EX == rs1_IF_ID) || (rd_ID_EX == rs2_IF_ID))) begin
         stall = 1'b1;
      end else begin
         stall = 1'b0;
      end
   end
endmodule