// ============================================================
// Module: tt_um_brazo_digital
// Description: Tiny Tapeout wrapper for brazo_digital_top.
//
// Translates the standard TT port interface (ui_in, uo_out, etc.)
// into the named signals that brazo_digital_top expects.
//
// Pin mapping:
//
//  INPUTS  ui_in[7:0]
//    [0]  noisy_btn_x_cw   – X-axis clockwise button
//    [1]  noisy_btn_x_ccw  – X-axis counter-clockwise button
//    [2]  noisy_btn_y_cw   – Y-axis clockwise button
//    [3]  noisy_btn_y_ccw  – Y-axis counter-clockwise button
//    [4]  noisy_dip_grip   – Gripper enable DIP switch
//    [5]  noisy_sw_limit   – Gripper stiffness limit switch
//    [7:6] unused (ignored)
//
//  OUTPUTS uo_out[7:0]
//    [0]  step_x    – X-axis STEP pulse to DRV8825
//    [1]  dir_x     – X-axis DIR signal
//    [2]  step_y    – Y-axis STEP pulse
//    [3]  dir_y     – Y-axis DIR signal
//    [4]  step_grip – Gripper STEP pulse
//    [5]  dir_grip  – Gripper DIR signal
//    [7:6] tied to 0
//
//  BIDIRECTIONAL uio[7:0]
//    Not used — all set as inputs (uio_oe = 0)
// ============================================================

`default_nettype none

module tt_um_brazo_digital (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: input path  (unused)
    output wire [7:0] uio_out,  // IOs: output path (unused)
    output wire [7:0] uio_oe,   // IOs: enable path (0 = input)
    input  wire       ena,      // High when this design is selected
    input  wire       clk,      // 50 MHz clock from PIN_R8
    input  wire       rst_n     // Active-low reset
);

    // ── Bidir pins unused: all configured as inputs ───────────────────────
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // ── Internal wires from brazo_digital_top ─────────────────────────────
    wire step_x, dir_x;
    wire step_y, dir_y;
    wire step_grip, dir_grip;

    // ── Output assembly ───────────────────────────────────────────────────
    assign uo_out[0] = step_x;
    assign uo_out[1] = dir_x;
    assign uo_out[2] = step_y;
    assign uo_out[3] = dir_y;
    assign uo_out[4] = step_grip;
    assign uo_out[5] = dir_grip;
    assign uo_out[7:6] = 2'b00;  // Unused output bits tied low

    // ── Design instance ───────────────────────────────────────────────────
    brazo_digital_top core (
        .clk             (clk),
        .rst_n           (rst_n),

        // Noisy physical inputs from ui_in bus
        .noisy_btn_x_cw  (ui_in[0]),
        .noisy_btn_x_ccw (ui_in[1]),
        .noisy_btn_y_cw  (ui_in[2]),
        .noisy_btn_y_ccw (ui_in[3]),
        .noisy_dip_grip  (ui_in[4]),
        .noisy_sw_limit  (ui_in[5]),

        // Motor outputs
        .step_x          (step_x),
        .dir_x           (dir_x),
        .step_y          (step_y),
        .dir_y           (dir_y),
        .step_grip       (step_grip),
        .dir_grip        (dir_grip)
    );

endmodule
