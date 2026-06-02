/*
Autor: Fabián Chacón
Tecnológico de Costa Rica
Módulo: tester

Descripción:
Generador de vectores de prueba que utiliza las tareas de la interfaz
para aplicar entradas y pulsar `start`. Usa números aleatorios y pruebas
secuenciales. El tester no toca señales del DUT directamente.
*/
module tester();

  // Número de pruebas a ejecutar
  parameter integer NUM_TESTS = 64;

  integer i;
  reg [31:0] A;
  reg [31:0] B;

  initial begin
    // Reset inicial
    tb_top.intf.drive_reset(1);
    repeat (2) @(posedge tb_top.intf.clk);
    tb_top.intf.drive_reset(0);
    repeat (2) @(posedge tb_top.intf.clk);

      // Ejecutar pruebas aleatorias
      for (i = 0; i < NUM_TESTS; i = i + 1) begin
        case (i)
          0: begin A = 32'd0;         B = 32'd0;         end
          1: begin A = 32'd7;         B = 32'd3;         end
          2: begin A = 32'd12;        B = 32'd9;         end
          3: begin A = 32'd255;       B = 32'd2;         end
          4: begin A = 32'h0001_0000; B = 32'd4;         end
          5: begin A = 32'h0001_0000; B = 32'h0001_0000; end
          default: begin
            A = $urandom();
            B = $urandom();
          end
        endcase
        tb_top.intf.drive_inputs(A, B);
        tb_top.intf.pulse_start();
        // esperar a que el DUT indique done
        wait (tb_top.intf.done == 1'b1);
        wait (tb_top.intf.done == 1'b0);
        @(posedge tb_top.intf.clk);
      end

      $display("[TESTER] Todas las pruebas solicitadas.");
      #10 $finish;
  end

endmodule
