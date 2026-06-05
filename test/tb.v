`default_nettype none
`timescale 1ns / 1ps

// ============================================================
// tb.v — Testbench for brazo_digital_top
//
// Pin mapping (Tiny Tapeout interface):
//
//   ui_in[0] = noisy_btn_x_cw
//   ui_in[1] = noisy_btn_x_ccw
//   ui_in[2] = noisy_btn_y_cw
//   ui_in[3] = noisy_btn_y_ccw
//   ui_in[4] = noisy_dip_grip
//   ui_in[5] = noisy_sw_limit
//   ui_in[7:6] = unused (tie to 0)
//
//   uo_out[0] = step_x
//   uo_out[1] = dir_x
//   uo_out[2] = step_y
//   uo_out[3] = dir_y
//   uo_out[4] = step_grip
//   uo_out[5] = dir_grip
//   uo_out[7:6] = unused
// ============================================================
module tb ();

  // Dump waveforms to FST (open with: gtkwave tb.fst tb.gtkw)
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // ── TT standard signals ──────────────────────────────────
  reg        clk;
  reg        rst_n;
  reg        ena;
  reg  [7:0] ui_in;
  reg  [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // ── DUT instance ─────────────────────────────────────────
  tt_um_brazo_digital user_project (

`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (ena),
      .clk    (clk),
      .rst_n  (rst_n)
  );

endmodule
