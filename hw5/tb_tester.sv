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
        A = $urandom();
        B = $urandom();
        tb_top.intf.drive_inputs(A, B);
        tb_top.intf.pulse_start();
        // esperar a que el DUT indique done
        wait (tb_top.intf.done == 1'b1);
        @(posedge tb_top.intf.clk);
      end

      $display("[TESTER] Todas las pruebas solicitadas.");
      #10 $finish;
  end

endmodule
