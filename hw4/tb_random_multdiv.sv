/*
Autor: Fabian Chacón 201813154
Tecnológico de Costa Rica
Módulo: tb_random_multdiv.sv

Descripción:
Testbench para el módulo multdiv32_top que combina multiplicación y división


*/

`timescale 1ns/1ps

typedef enum bit [1:0] {
    no_op = 2'b00,
    mul_op = 2'b01,
    div_op = 2'b10,
    rst_op = 2'b11
} operation_t;

// Módulo  que selecciona entre multiplicación y división 
module multdiv32_top(
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  operation_t  op,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [63:0] result,
    output logic        done
);

    // Señales internas 
    logic        start_mul;
    logic        start_div;
    logic [63:0] mul_result;
    logic [31:0] div_quotient;
    logic [31:0] div_remainder;
    logic        mul_done;
    logic        div_done;

    // Solo activa el multiplicador cuando la operación es mul_op.
    assign start_mul = (op == mul_op) ? start : 1'b0;
    // Solo activa el divisor cuando la operación es div_op.
    assign start_div = (op == div_op) ? start : 1'b0;

    multiplier32_top mult_inst(
        .clk(clk),
        .reset(reset),
        .start(start_mul),
        .a(a),
        .b(b),
        .result(mul_result),
        .done(mul_done)
    );

    divider32_top div_inst(
        .clk(clk),
        .reset(reset),
        .start(start_div),
        .dividend(a),
        .divisor(b),
        .quotient(div_quotient),
        .remainder(div_remainder),
        .done(div_done)
    );

    // Señal done activa según la operación actual
    assign done = (op == mul_op) ? mul_done :
                  (op == div_op) ? div_done : 1'b0;

    // El resultado de salida se forma con el producto o con el cociente + resto
    always_comb begin
        case (op)
            mul_op: result = mul_result;
            div_op: result = {div_quotient, div_remainder};
            default: result = 64'd0;
        endcase
    end

endmodule

module tb_random_multdiv;

    // Va del generator al driver
    typedef struct packed {
        operation_t  op;
        logic [31:0] a;
        logic [31:0] b;
        int unsigned iter;
        bit          end_of_sequence;
    } tx_t;

    // Lo que manda el monitor al scoreboard
    typedef struct packed {
        operation_t  op;
        logic [31:0] a;
        logic [31:0] b;
        logic [63:0] result;
        int unsigned iter;
        bit          end_of_sequence;
    } mon_t;

    // Señales del reloj y control
    logic        clk;
    logic        reset;
    logic        start;
    operation_t  op;
    logic [31:0] a;
    logic [31:0] b;

    // Salidas del DUT
    logic [63:0] result;
    logic        done;

    // Comunicación entre bloques
    mailbox gen2drv = new();
    mailbox mon2scb = new();

    // Control de flujo interno
    int unsigned     iter;
    int unsigned     error_count;
    int unsigned     active_iter;
    bit              transaction_active;
    bit              end_of_test;

    localparam int NUM_ITERATIONS = 64;

    // --------------------------------------------------------------------
    // Seccion de covergroups
    // --------------------------------------------------------------------
    operation_t  cov_op;
    logic [31:0] cov_a;
    logic [31:0] cov_b;
    logic [63:0] cov_result;
    bit          cov_passed;

    covergroup cg_multdiv;
        option.per_instance = 1;
        option.name = "cg_multdiv";

        cp_operation: coverpoint cov_op {
            bins nop   = {no_op};
            bins mult  = {mul_op};
            bins div   = {div_op};
            bins reset = {rst_op};
        }

        cp_operand_a: coverpoint cov_a {
            bins zero = {32'd0};
            bins low  = {[32'd1:32'd15]};
            bins mid  = {[32'd16:32'h0000_FFFF]};
            bins high = {[32'h0001_0000:32'hFFFF_FFFF]};
        }

        cp_operand_b: coverpoint cov_b {
            bins zero = {32'd0};
            bins low  = {[32'd1:32'd15]};
            bins mid  = {[32'd16:32'h0000_FFFF]};
            bins high = {[32'h0001_0000:32'hFFFF_FFFF]};
        }

        cp_result: coverpoint cov_result {
            bins zero = {64'd0};
            bins low  = {[64'd1:64'd255]};
            bins mid  = {[64'd256:64'h0000_0000_FFFF_FFFF]};
            bins high = {[64'h0000_0001_0000_0000:64'hFFFF_FFFF_FFFF_FFFF]};
        }

        cp_status: coverpoint cov_passed {
            bins pass = {1'b1};
            ignore_bins fail = {1'b0};
        }

        cross_op_a_b: cross cp_operation, cp_operand_a, cp_operand_b;
        cross_op_status: cross cp_operation, cp_status;
    endgroup

    cg_multdiv cov = new();

    // Instancia del DUT principal que combina multiplicador y divisor
    multdiv32_top dut(
        .clk(clk),
        .reset(reset),
        .start(start),
        .op(op),
        .a(a),
        .b(b),
        .result(result),
        .done(done)
    );

    // Generador de operación aleatoria
    function automatic operation_t get_operation();
        int rand_val;
        rand_val = $random;
        get_operation = operation_t'(rand_val[1:0]);
    endfunction

    // Calcula el resultado esperado según la operación seleccionada
    function automatic logic [63:0] calc_expected(
        operation_t op_i,
        logic [31:0] a_i,
        logic [31:0] b_i
    );
        case (op_i)
            mul_op: calc_expected = a_i * b_i;
            div_op: calc_expected = {a_i / b_i, a_i % b_i};
            default: calc_expected = 64'd0;
        endcase
    endfunction

    // Generador de reloj con periodo de 10 ns
    always #5 clk = ~clk;

    // Generator: crea pruebas aleatorias sin aplicar señales al DUT
    task automatic generator();
        tx_t tx;
        for (iter = 0; iter < NUM_ITERATIONS; iter++) begin
            case (iter)
                0: tx = '{op:no_op, a:32'd0, b:32'd0, iter:iter, end_of_sequence:1'b0};
                1: tx = '{op:rst_op, a:32'd0, b:32'd0, iter:iter, end_of_sequence:1'b0};
                2: tx = '{op:mul_op, a:32'd0, b:32'd7, iter:iter, end_of_sequence:1'b0};
                3: tx = '{op:mul_op, a:32'd12, b:32'd9, iter:iter, end_of_sequence:1'b0};
                4: tx = '{op:div_op, a:32'd20, b:32'd4, iter:iter, end_of_sequence:1'b0};
                5: tx = '{op:div_op, a:32'd27, b:32'd4, iter:iter, end_of_sequence:1'b0};
                6: tx = '{op:mul_op, a:32'h0001_0000, b:32'd3, iter:iter, end_of_sequence:1'b0};
                7: tx = '{op:div_op, a:32'h0001_0000, b:32'd16, iter:iter, end_of_sequence:1'b0};
                default: begin
                    tx.op = get_operation();
                    tx.a = $random;
                    tx.b = $random;
                    tx.iter = iter;
                    tx.end_of_sequence = 1'b0;
                end
            endcase

            if (tx.op == div_op && tx.b == 32'd0) begin
                tx.b = 32'd1;
            end

            gen2drv.put(tx);
            @(posedge clk);
        end

        tx = '{op:no_op, a:32'd0, b:32'd0, iter:0, end_of_sequence:1'b1};
        gen2drv.put(tx);
    endtask

    // Muestrea una transaccion completa para cobertura funcional.
    task automatic sample_coverage(
        operation_t op_i,
        logic [31:0] a_i,
        logic [31:0] b_i,
        logic [63:0] result_i,
        bit passed_i
    );
        cov_op = op_i;
        cov_a = a_i;
        cov_b = b_i;
        cov_result = result_i;
        cov_passed = passed_i;
        cov.sample();
    endtask

    // Driver: toma la prueba y controla el DUT.
    task automatic driver();
        tx_t tx;
        while (1) begin
            gen2drv.get(tx);

            if (tx.end_of_sequence) begin
                end_of_test = 1'b1;
                break;
            end

            if (tx.op == rst_op) begin
                $display("Iter %0d op=RST", tx.iter);
                start = 0;
                op = no_op;
                a = 32'd0;
                b = 32'd0;
                reset = 1;
                @(posedge clk);
                reset = 0;
                @(posedge clk);
                sample_coverage(rst_op, tx.a, tx.b, 64'd0, 1'b1);
                continue;
            end

            if (tx.op == no_op) begin
                $display("Iter %0d op=NOP", tx.iter);
                start = 0;
                op = no_op;
                a = 32'd0;
                b = 32'd0;
                @(posedge clk);
                sample_coverage(no_op, tx.a, tx.b, 64'd0, 1'b1);
                continue;
            end

            active_iter = tx.iter;
            transaction_active = 1'b1;
            op = tx.op;
            a = tx.a;
            b = tx.b;
            start = 1;
            @(posedge clk);
            start = 0;

            // Mantienee la operación estable hasta que el DUT indique done
            while (!done) begin
                @(posedge clk);
            end

            @(posedge clk);
            transaction_active = 1'b0;
            op = no_op;
            a = 32'd0;
            b = 32'd0;
        end
    endtask

    // Monitor: observa el done y manda los datos al scoreboard
    task automatic monitor();
        mon_t item;
        bit done_d;
        bit end_marker_sent;

        done_d = 1'b0;
        end_marker_sent = 1'b0;

        forever begin
            @(posedge clk);
            if (done && !done_d) begin
                item.op = op;
                item.a = a;
                item.b = b;
                item.result = result;
                item.iter = active_iter;
                item.end_of_sequence = 1'b0;
                mon2scb.put(item);
            end

            if (end_of_test && !transaction_active && !end_marker_sent) begin
                item = '{op:no_op, a:32'd0, b:32'd0, result:64'd0, iter:0, end_of_sequence:1'b1};
                mon2scb.put(item);
                end_marker_sent = 1'b1;
                break;
            end

            done_d = done;
        end
    endtask

    // Scoreboard: chequea el resultado y marca errores
    task automatic scoreboard();
        mon_t item;
        logic [63:0] expected;

        error_count = 0;

        forever begin
            mon2scb.get(item);
            if (item.end_of_sequence) begin
                break;
            end

            expected = calc_expected(item.op, item.a, item.b);
            if (item.result !== expected) begin
                $display("Iter %0d op=%0d A=%0d B=%0d esperado=%0d got=%0d",
                         item.iter, item.op, item.a, item.b, expected, item.result);
                error_count += 1;
                sample_coverage(item.op, item.a, item.b, item.result, 1'b0);
            end else begin
                $display("Iter %0d op=%0d A=%0d B=%0d result=%0d",
                         item.iter, item.op, item.a, item.b, item.result);
                sample_coverage(item.op, item.a, item.b, item.result, 1'b1);
            end
        end
    endtask

    initial begin
        // Configuración inicial de la simulación y dump de señales
        $dumpfile("wave_random_multdiv.vcd");
        $dumpvars(0, tb_random_multdiv);

        clk = 0;
        reset = 1;
        start = 0;
        op = no_op;
        a = 32'd0;
        b = 32'd0;
        iter = 0;
        error_count = 0;
        active_iter = 0;
        transaction_active = 1'b0;
        end_of_test = 1'b0;

        // Reset inicial obligatorio
        @(posedge clk);
        @(posedge clk);
        reset = 0;

        fork
            generator();
            driver();
            monitor();
            scoreboard();
        join

        // Reporte final de la prueba
        $display("RESULTADO FINAL: errores = %0d de %0d iteraciones", error_count, NUM_ITERATIONS);
        $display("COBERTURA FUNCIONAL HW4 = %0.2f%%", cov.get_inst_coverage());
        if (error_count == 0) begin
            $display("TESTBENCH: PASSED");
        end else begin
            $display("TESTBENCH: FAILED");
        end

        #20;
        $finish;
    end

endmodule
