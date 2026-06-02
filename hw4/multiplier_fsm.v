/*
Autor: Fabian Chacon 201813154
Tecnologico de Costa Rica
Modulo: multiplier_fsm

Descripcion:
FSM de control para el multiplicador secuencial de 32 bits.

Las senales load, add, shift y done se generan de forma combinacional a partir
del estado actual. Esto permite que el datapath las observe en el mismo flanco
de reloj y evita desfases de un ciclo entre control y datos.
*/

module multiplier_fsm(
    input  clk,
    input  reset,
    input  start,
    input  lsb,

    output reg load,
    output reg add,
    output reg shift,
    output reg done
);

reg [5:0] count;
reg [2:0] state;
reg [2:0] next_state;

localparam IDLE  = 3'b000;
localparam CHECK = 3'b001;
localparam ADD   = 3'b010;
localparam SHIFT = 3'b011;
localparam DONE  = 3'b100;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        count <= 6'd0;
    end else begin
        state <= next_state;

        if (state == IDLE && start) begin
            count <= 6'd0;
        end else if (state == SHIFT) begin
            count <= count + 1'b1;
        end
    end
end

always @(*) begin
    load = 1'b0;
    add = 1'b0;
    shift = 1'b0;
    done = 1'b0;
    next_state = state;

    case (state)
    IDLE: begin
        if (start) begin
            load = 1'b1;
            next_state = CHECK;
        end
    end

    CHECK: begin
        if (lsb) begin
            next_state = ADD;
        end else begin
            next_state = SHIFT;
        end
    end

    ADD: begin
        add = 1'b1;
        next_state = SHIFT;
    end

    SHIFT: begin
        shift = 1'b1;
        if (count == 6'd31) begin
            next_state = DONE;
        end else begin
            next_state = CHECK;
        end
    end

    DONE: begin
        done = 1'b1;
        next_state = IDLE;
    end

    default: begin
        next_state = IDLE;
    end
    endcase
end

endmodule
