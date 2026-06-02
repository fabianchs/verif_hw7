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

  always @(posedge tb_top.intf.clk) begin
    // Capturar operandos cuando se pulse start
    if (tb_top.intf.start) begin
      a_reg <= tb_top.intf.a;
      b_reg <= tb_top.intf.b;
      expected <= tb_top.intf.calc_expected(tb_top.intf.a, tb_top.intf.b);
    end

    // Cuando el DUT finalice, comparar
    if (tb_top.intf.done) begin
      if (tb_top.intf.result !== expected) begin
        $display("[SCOREBOARD] MISMATCH: a=%0h b=%0h exp=%0h got=%0h", a_reg, b_reg, expected, tb_top.intf.result);
      end else begin
        $display("[SCOREBOARD] PASS: a=%0h b=%0h result=%0h", a_reg, b_reg, tb_top.intf.result);
      end
    end
  end

endmodule
