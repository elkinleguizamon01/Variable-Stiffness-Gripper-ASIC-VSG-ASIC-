/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_brazo_digital (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    // Bidirectional pins unused: all configured as inputs
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Internal wires from brazo_digital_top
    wire step_x, dir_x;
    wire step_y, dir_y;
    wire step_grip, dir_grip;

    // Output assembly
    assign uo_out[0] = step_x;
    assign uo_out[1] = dir_x;
    assign uo_out[2] = step_y;
    assign uo_out[3] = dir_y;
    assign uo_out[4] = step_grip;
    assign uo_out[5] = dir_grip;
    assign uo_out[7:6] = 2'b00;  // Unused output bits tied low

    // Design instance
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
