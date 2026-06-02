/*
Autor: Fabián Chacón
Módulo: tb_top

Descripción:
Banco de pruebas superior que instancia la interfaz, el DUT, el tester
y el scoreboard. Genera reloj, archivos de trazas y conecta módulos.
*/

`timescale 1ns/1ps

module tb_top;

  // Reloj
  bit clk = 0;
  always #5 clk = ~clk; // periodo 10 ns

  // Instanciar interfaz
  tb_if intf(.clk(clk));

  // Instanciar DUT (conexión a señales de la interfaz)
  multiplier32_top dut (
    .clk(clk),
    .reset(intf.reset),
    .start(intf.start),
    .a(intf.a),
    .b(intf.b),
    .result(intf.result),
    .done(intf.done)
  );

  // Instanciar tester, scoreboard y cobertura
  tester t0();
  scoreboard sb();
  tb_coverage cov();

  initial begin
    $dumpfile("wave_tb_top.vcd");
    $dumpvars(0, tb_top);
  end

endmodule
