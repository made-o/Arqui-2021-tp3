`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.01.2025 23:19:25
// Design Name: 
// Module Name: tb_uart_if_init
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


module tb_uart_if_init();
reg i_clk;
reg i_reset;

reg i_inicializando;
reg i_enable;
reg i_halt = 0;
reg i_stall;

reg [32-1:0] i_jump_address;  //! Dirección de salto en caso de branch/jump
wire [32-1:0] o_instruction;
wire [32-1:0] o_data_send_tx;
reg i_jump_select;

wire [5-1:0] i_addr_tx;

reg [4:0] i_reg_lectura1;
reg [4:0] i_reg_lectura2;

reg [4:0] i_regWrite_addr;
reg [31:0] i_dato_a_escribir;

reg i_WriteEnable;

wire [31:0] pc;
wire [31:0] o_data1;
wire [31:0] o_data2;
wire [7:0] o_data;

//tx:
wire [31:0] data_to_send;
//wire [4:0] o_data_add;

wire [4:0] reg_lectura1_inner;
wire [4:0] reg_lectura2_inner;
wire [4:0] regWrite_addr_inner;
wire [31:0] dato_a_escribir_inner;

wire oEnable_inner;
wire WriteEnable_inner;
wire exec_mode;
wire step;

wire o_rx_done_tick , i_tx_done, o_tx_done;
wire o_tx;
wire o_tx_uart;
reg tx_start_simulacion; // Es usado en el transmisor de la simulacion y no del mips

reg start = 0, tx_done;
wire tx_start;
reg [31:0] data_transfer = 32'b0;

wire [8-1:0] tx_data;

reg [4:0] contador;
integer const;
integer index_mem = 0;
integer index_bit_8 = 0;
integer lengh_mem = 7;

reg [32-1:0] memoriaTransferida [6:0];

I_Fetch u_I_Fetch (
    .i_clk (i_clk),         //! Clock
    .i_reset (i_reset),       //! Reset
    .i_enable (i_enable),      //! Enable
    .i_halt (i_halt),        //! Señal para detener el PC
    .i_stall (i_stall),       //! Señal para pausar el PC
    .i_inicializando (i_inicializando),
    .i_jump_address (i_jump_address),  //! Dirección de salto en caso de branch/jump
    .i_jump_select (i_jump_select), //! Selección de salto (branch/jump select)
    
    .i_addr_tx(i_addr_tx), // Direccion de la memoria que se quiere enviar por uart
    
    .i_WriteEnable (WriteEnable_inner),
    .i_addr_carga (regWrite_addr_inner),
    .i_data_carga (dato_a_escribir_inner),
    
    .i_exec_mode(exec_mode),
    .i_step(step),
    
    .o_instruction (o_instruction), //! Instrucción de la memoria de instrucciones
    .o_data_send_tx(o_data_send_tx),
    .o_halt_signal (o_halt_signal),
    .o_pc (pc)
    /* 
    .i_clk (i_clk),
    .i_reset (i_reset),
    .i_enable (i_enable),
            
    .i_reg_lectura1 (reg_lectura1_inner), 
    .i_reg_lectura2 (reg_lectura2_inner), 
    .i_regWrite_addr (regWrite_addr_inner),
    .i_dato_a_escribir (dato_a_escribir_inner),
    
    .i_WriteEnable (WriteEnable_inner),
    
    .o_data1 (o_data1),
    .o_data2 (o_data2)
    */
);

interface_rx u_interface_rx (

    .i_clk (i_clk),
    .i_reset (i_reset),
            
    .i_rx_data (o_data), 
    .i_rx_done (o_rx_done_tick),
        
    .o_carga_flag (WriteEnable_inner), 
    .o_addr_carga (regWrite_addr_inner),   
    .o_data_carga (dato_a_escribir_inner), 
    .o_exec_mode (exec_mode),
    .o_step (step)
    
);

interface_tx u_interfaz_tx
(
    .i_clk(i_clk), 
    .i_reset(i_reset), 
    
    .i_pc(pc),
    
    .instruccion(o_data_send_tx),
     
    .i_memoria(data_memory),
    .i_ciclos(ciclos),
     
    .i_halt(i_halt),
    
    .i_tx_done(o_tx_done),
     
    .i_exec_mode(exec_mode), 
    .i_step(step),
    
    .o_tx_start(tx_start), 
    .o_data_to_send(data_to_send),
    .o_data_add (i_addr_tx), 
    .o_done(done)
);

receiver u_receiver(

    .i_clock (i_clk),
    .i_reset (i_reset),
    
    .i_s_tick (s_tick),
    .i_rx (o_tx),
    
    .o_rx_done_tick (o_rx_done_tick),
    .o_data (o_data)
);

  transmitter #(.D_BIT(8))
uut_uart_tx (
    .i_clock    (i_clk),
    .i_reset    (i_reset),
    .i_s_tick   (s_tick),
    .i_tx_start (tx_start_simulacion),
    .i_data     (tx_data),
    .o_tx       (o_tx),
    .o_tx_done  (i_tx_done)

);

  transmitter #(.D_BIT(8))
uut_uart_tx_uart (
    .i_clock    (i_clk),
    .i_reset    (i_reset),
    .i_s_tick   (s_tick),
    .i_tx_start (tx_start),
    .i_data     (data_to_send),
    .o_tx       (o_tx_uart),
    .o_tx_done  (o_tx_done)

);

baudrate_generator #(.N(10), .M(652))
 uut_baud_gen (
       .i_clk(i_clk),
       .i_reset(i_reset),
       .o_flag_max_tick(s_tick)
);

initial begin
   //inicializo entradas:

    i_reset = 1;
    i_inicializando = 1;
    i_enable = 0;
    i_clk = 0;
    i_halt = 0;
    i_stall = 0;
    
    i_jump_address = 32'b0;
    i_jump_select = 0; // Selecciona el siguiente pc al incrementado
    
    memoriaTransferida[0] = 32'b0000_0000_0000_0000_0000_0000_0000_1000; //8
    memoriaTransferida[1] = 32'b0000_0000_0000_0000_0000_0000_1000_1000; //88
    memoriaTransferida[2] = 32'b0000_0000_0000_0000_0000_1000_0000_1000; //808
    memoriaTransferida[3] = 32'b0000_0000_0000_0000_1000_0000_0000_1000; //8008
    memoriaTransferida[4] = 32'b1111_1111_1111_1111_1111_1111_1111_1111;
    memoriaTransferida[5] = 32'b0000_0000_0000_0000_0000_0000_0000_0001;
    memoriaTransferida[6] = 32'b0000_0000_0000_0000_0000_0000_0000_0001;
    #1000
    i_reset = 0;
    i_enable = 1;
    start = 1;
    #100
    start = 0;
   /* 
    #92000000
    tx_start_simulacion = 1'b1;
    #2000000
    tx_start_simulacion = 1'b0;
    #92000000
    tx_start_simulacion = 1'b1;
    #2000000
    tx_start_simulacion = 1'b0;
    */
    /*
    #100
    
    i_WriteEnable = 1;
    
    i_reg_lectura1 = 5'b00000; //leo el registro 0, espero 0
    i_reg_lectura2 = 5'b00001; //leo el registro 1, espero 10000
    i_regWrite_addr = 5'b00001;
    i_dato_a_escribir = 32'b00000000000000000000000000010000;

     [USF-XSim-62] 'elaborate' step failed with error(s). Please check the Tcl console output or 'C:/Users/nadie/prueba/prueba.sim/sim_1/behav/xsim/elaborate.log' file for more information.

    #100

    i_WriteEnable = 1;
    
    i_reg_lectura1 = 5'b00000; //
    i_reg_lectura2 = 5'b00001; //leo el registro 1, espero 10000
    i_regWrite_addr = 5'b00010;
    i_dato_a_escribir = 32'b00000000000000000000000000010000;
    
    
    #100

    i_WriteEnable = 0;
    
    i_reg_lectura1 = 5'b00011;// leo retistro 3, espero 10000
    i_reg_lectura2 = 5'b00010; // leo retistro 2, espero 10000
    i_regWrite_addr = 5'b00011;
    i_dato_a_escribir = 32'b00000000000000000000000000010000;
    */
    #1000000000
    $finish();
          
   end
   /*
   always @(negedge i_clk)
   begin:carga
        if(tx_done || start)
        begin
            start <= 0;
            data_transfer <= memoriaTransferida[index_mem];
            tx_data <= data_transfer[(8*index_bit_8)+:8];
            index_bit_8 <= index_bit_8 + 1;
            tx_start <= 1;    
            if(index_bit_8 == 4)
            begin
                index_bit_8 <= 0;
                if(index_mem != 7)
                begin 
                    index_mem <= index_mem +1;
                    data_transfer <= memoriaTransferida[index_mem];
                    tx_data <= data_transfer[(8*index_bit_8)+:8];
                end
            end 
        end
   end*/
   //-----------------------------------------------------------------------------------------
   	//declaracion de los estados
	localparam  IDLE = 1'b0;
	localparam  REG  = 1'b1;

	reg            state_reg, next_state;
    reg            o_done;
    
	//cambios de estado
	always@(posedge i_clk) begin:check_state
		if(i_reset)
            state_reg  <= IDLE;
		else
			state_reg <= next_state;			
	end//check_state

    always@(*)begin:next
        next_state = state_reg;
        
        case(state_reg)
        IDLE: // O se hizo el step.
        begin
            data_transfer  = 32'b0001_0000_0000_0000_0000_0000_0000_0001;
            tx_start_simulacion = 1'b0;
            o_done     = 1'b0;
            
            if(start)  
                next_state = REG;
        end
        
        REG: //manda los regs uno por uno sin usar un for
        begin      
            //data = i_registros[(N_BITS_INSTR*reg_num)+:N_BITS_INSTR];
            data_transfer <= memoriaTransferida[index_mem];  
            tx_start_simulacion = 1'b1;
            
            if(tx_done)
            begin
                index_bit_8 = index_bit_8 + 1;
                tx_start_simulacion = 1'b0;
                
                if(index_bit_8 == 4)
                begin
                    index_bit_8 = 5'b0;           
                                        
                    if(index_mem == lengh_mem-2)
                    begin                        
                        next_state = IDLE;
                        index_mem = 5'b0;
                        o_done = 1;
                        i_inicializando = 0;
                    end
                    else
                        index_mem = index_mem + 1;
                end
            end
        end
        
        endcase       
    end
    
    always@(posedge i_clk)begin:tx_done_logic        
        /* aca setea el tx_done */
        if(i_tx_done == 1'b1)
            tx_done <= 1'b1;
        else
            tx_done <= 1'b0;
    end

    assign tx_data = data_transfer[(8*index_bit_8)+:8];
   /*
   always @(negedge i_clk)
   begin: test
        
        i_WriteEnable <= ~i_WriteEnable;
    
        i_reg_lectura1 <= 5'b00000; //
        i_reg_lectura2 <= 5'b00001; //leo el registro 1, espero 10000
        i_regWrite_addr <= contador;
        i_dato_a_escribir <= 32'b00000000000000000000000000010000;
        if(contador < 5'b11111)
        begin
            contador <= contador + 1;
        end
   end
   */
   
   always begin
      #10
      i_clk = ~i_clk;
   end
 
endmodule

