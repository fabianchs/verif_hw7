/*
Autor: Fabian Chacon
Tecnologico de Costa Rica
Modulo: tb_coverage

Descripcion:
Moodulo de cobertura funcional para el banco de pruebas
Hace sniff de la interfaz del testbench, captura operandos al iniciar una
transaccion y muestrea el resultado cuando el DUT activa done.
*/

`timescale 1ns/1ps

module tb_coverage();

  logic [31:0] cov_a;
  logic [31:0] cov_b;
  logic [63:0] cov_result;
  bit          cov_done_seen;
  bit          done_d;

  covergroup cg_multiplier;
    option.per_instance = 1;
    option.name = "cg_multiplier";

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

    cross_operands: cross cp_operand_a, cp_operand_b;
  endgroup

  covergroup cg_control @(posedge tb_top.intf.clk);
    option.per_instance = 1;
    option.name = "cg_control";

    cp_reset: coverpoint tb_top.intf.reset {
      bins inactive = {1'b0};
      bins active   = {1'b1};
    }

    cp_start: coverpoint tb_top.intf.start {
      bins inactive = {1'b0};
      bins active   = {1'b1};
    }

    cp_done: coverpoint tb_top.intf.done {
      bins inactive = {1'b0};
      bins active   = {1'b1};
    }
  endgroup

  cg_multiplier multiplier_cov = new();
  cg_control control_cov = new();

  always @(posedge tb_top.intf.clk) begin
    if (tb_top.intf.reset) begin
      cov_a = 32'd0;
      cov_b = 32'd0;
      cov_result = 64'd0;
      cov_done_seen = 1'b0;
      done_d = 1'b0;
    end else begin
      if (tb_top.intf.start) begin
        cov_a = tb_top.intf.a;
        cov_b = tb_top.intf.b;
      end

      if (tb_top.intf.done && !done_d) begin
        cov_result = tb_top.intf.result;
        cov_done_seen = 1'b1;
        multiplier_cov.sample();
      end

      done_d = tb_top.intf.done;
    end
  end

  final begin
    if (cov_done_seen) begin
      $display("[COVERAGE] Multiplicador = %0.2f%%", multiplier_cov.get_inst_coverage());
      $display("[COVERAGE] Control = %0.2f%%", control_cov.get_inst_coverage());
    end else begin
      $display("[COVERAGE] No se completaron transacciones para muestrear.");
    end
  end

endmodule
