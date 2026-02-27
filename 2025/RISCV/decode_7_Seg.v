`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/19/2026 01:01:03 PM
// Design Name: 
// Module Name: decode_7_Seg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module decode_7_Seg(
    input [2:0] i_estado,        // Tus 3 bits de estado
    output reg [6:0] o_segmentos // Los 7 segmentos (a-g)
);

    always @(*) begin
        case(i_estado)
            3'b000: o_segmentos = 7'b0000001; // "0" IDLE
            3'b001: o_segmentos = 7'b1001111; // "1" WAIT_CMD
            3'b010: o_segmentos = 7'b0010010; // "2" REC
            3'b011: o_segmentos = 7'b0000110; // "3" WAIT_HALT
            3'b100: o_segmentos = 7'b1001100; // "4" EXEC_STEP
            3'b101: o_segmentos = 7'b0100100; // "5" SEND
            default: o_segmentos = 7'b1111111; // Apagado
        endcase
    end
endmodule
