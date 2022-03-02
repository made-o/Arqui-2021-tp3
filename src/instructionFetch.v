`timescale 1ns / 1ps

module instructionFetch #(
    // Parametros:
    parameter NBITS = 32
)
// Entradas y salidas:
(   input  wire i_PCWrite,
    input  wire [NBITS-1:0] i_DstSalto,
    input  wire i_PCSource,
    input  wire i_clk, i_reset,
    
    output reg o_pc_4,
    output reg [NBITS-1:0] o_instruccion

);
    reg [NBITS-1:0] pc;
    reg [NBITS-1:0] instruccion;

    ////////////////////////////////////////////////////
    always @(posedge i_clk) begin: lecturaSigInstr
        if(i_reset) begin
            pc <= {NBITS{1'b0}};
        end
        else begin
            if(i_PCWrite) begin
                if(i_PCSource) begin
                    pc <= pc+1;
                end//end_if
                else begin
                    pc <= i_DstSalto;
                end//end_else
            end//end_if
            else begin
                pc <= pc;
            end //end_else
        end//end_else
    end//end_always
    
    
    ////////////////////////////////////////////////////
    always @(negedge i_clk) begin: escrituraValoresSalida
        if(i_reset) begin
            o_pc_4 <= 1'b1;
        end
        else begin
            o_instruccion <= instruccion;
            o_pc_4 <= pc;
        end//end_else
        
        
    end//end_always
    
    ////////////////////////////////////////////////////
    instructionMemory 
    u_instr_mem (
        .i_address(pc),
        .i_clk(i_clk),
        .i_w_Enable(0),
        .i_r_Enable(1),
        .i_oEnable(1),
        
        .io_data(instruccion)
    );

endmodule
