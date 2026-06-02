/*
Autor: Fabián Chacón
Tecnológico de Costa Rica
Módulo: scoreboard

Descripción:
Compara el resultado del DUT con el valor esperado calculado por la
función de la interfaz. Registra passes y errores.
*/
module scoreboard();

  reg [63:0] expected;
  reg [31:0] a_reg, b_reg;
  reg done_d;
  integer pass_count;
  integer error_count;

  initial begin
    expected = 64'd0;
    a_reg = 32'd0;
    b_reg = 32'd0;
    done_d = 1'b0;
    pass_count = 0;
    error_count = 0;
  end

  always @(posedge tb_top.intf.clk) begin
    #1;

    if (tb_top.intf.reset) begin
      done_d = 1'b0;
    end

    // Capturar operandos cuando se pulse start
    if (tb_top.intf.start) begin
      a_reg = tb_top.intf.a;
      b_reg = tb_top.intf.b;
      expected = tb_top.intf.calc_expected(tb_top.intf.a, tb_top.intf.b);
    end

    // Cuando el DUT finalice, comparar
    if (tb_top.intf.done && !done_d) begin
      if (tb_top.intf.result !== expected) begin
        $display("[SCOREBOARD] MISMATCH: a=%0h b=%0h exp=%0h got=%0h", a_reg, b_reg, expected, tb_top.intf.result);
        error_count = error_count + 1;
      end else begin
        $display("[SCOREBOARD] PASS: a=%0h b=%0h result=%0h", a_reg, b_reg, tb_top.intf.result);
        pass_count = pass_count + 1;
      end
    end

    done_d = tb_top.intf.done;
  end

  final begin
    $display("[SCOREBOARD] Resultado final: passes=%0d errores=%0d", pass_count, error_count);
    if (error_count == 0) begin
      $display("[SCOREBOARD] TEST PASSED");
    end else begin
      $display("[SCOREBOARD] TEST FAILED");
    end
  end

endmodule
