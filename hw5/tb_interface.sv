/*
Autor: Fabián Chacón
Módulo: tb_interface

Descripción:
Interfaz SystemVerilog para el DUT multiplier32_top.
Contiene señales compartidas, modports para DUT/TB y tareas/funciones
para manejar el DUT exclusivamente desde el módulo de interfaz.
*/

interface tb_if(input bit clk);

  // Señales de la interfaz (concordar con multiplier32_top)
  logic reset;
  logic start;
  logic [31:0] a, b;
  logic [63:0] result;
  logic done;

  // Modports para restringir acceso desde DUT y desde TB
  modport DUT (input clk, input reset, input start, input a, input b, output result, output done);
  modport TB  (output reset, output start, output a, output b, input result, input done);

  // Task para activar/desactivar reset
  task automatic drive_reset(bit val);
    reset = val;
  endtask

  // Task para aplicar valores a los operandos
  task automatic drive_inputs(logic [31:0] A, logic [31:0] B);
    a = A;
    b = B;
  endtask

  // Task para pulsar la señal start durante un flanco de reloj
  task automatic pulse_start();
    // Mantener start activo por al menos un ciclo de reloj para evitar
    // condiciones de carrera con procesos sensibles al flanco.
    start = 1'b1;
    @(posedge clk);
    @(posedge clk);
    start = 1'b0;
  endtask

  // Función auxiliar para calcular resultado esperado (multiplicación)
  function automatic logic [63:0] calc_expected(logic [31:0] A, logic [31:0] B);
    calc_expected = A * B;
  endfunction

endinterface
