// ============================================================
// Module: brazo_digital_top
// Description: Main hub of the project. Routes messy external inputs 
//              through debouncers and connects them to the motors.
// ============================================================
module brazo_digital_top (
    input  wire clk,            // Global 50 MHz clock
    input  wire rst_n,          // System reset button
    
    // Physical inputs coming directly from your board (Noisy!)
    input  wire noisy_btn_x_cw, // Button for X-Axis Right
    input  wire noisy_btn_x_ccw,// Button for X-Axis Left
    input  wire noisy_btn_y_cw, // Button for Y-Axis Up
    input  wire noisy_btn_y_ccw,// Button for Y-Axis Down
    input  wire noisy_dip_grip, // DIP switch to control gripper
    input  wire noisy_sw_limit, // Stiffness limit switch on the gripper
    
    // Clean, crisp outputs routed straight to your DRV8825 drivers
    output wire step_x,
    output wire dir_x,
    output wire step_y,
    output wire dir_y,
    output wire step_grip,
    output wire dir_grip
);

    // Interconnect wires to hold the cleaned-up signals
    wire clean_btn_x_cw, clean_btn_x_ccw;
    wire clean_btn_y_cw, clean_btn_y_ccw;
    wire clean_dip_grip, clean_sw_limit;

    // ===================================================
    // FILTER STAGE: Debouncing every single input line
    // ===================================================
    debouncer db_x_cw  (.clk(clk), .rst_n(rst_n), .noisy_in(noisy_btn_x_cw), .clean_out(clean_btn_x_cw));
    debouncer db_x_ccw (.clk(clk), .rst_n(rst_n), .noisy_in(noisy_btn_x_ccw),.clean_out(clean_btn_x_ccw));
    
    debouncer db_y_cw  (.clk(clk), .rst_n(rst_n), .noisy_in(noisy_btn_y_cw), .clean_out(clean_btn_y_cw));
    debouncer db_y_ccw (.clk(clk), .rst_n(rst_n), .noisy_in(noisy_btn_y_ccw),.clean_out(clean_btn_y_ccw));
    
    debouncer db_dip   (.clk(clk), .rst_n(rst_n), .noisy_in(noisy_dip_grip), .clean_out(clean_dip_grip));
    debouncer db_limit (.clk(clk), .rst_n(rst_n), .noisy_in(noisy_sw_limit), .clean_out(clean_sw_limit));

    // ===================================================
    // MOTOR CONTROL STAGE: Driving the actual hardware
    // ===================================================
    
    // X-Axis Motor Controller (NEMA 17)
    nema_controller motor_x (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_cw   (clean_btn_x_cw),
        .btn_ccw  (clean_btn_x_ccw),
        .step_pin (step_x),
        .dir_pin  (dir_x)
    );

    // Y-Axis Motor Controller (NEMA 17)
    nema_controller motor_y (
        .clk      (clk),
        .rst_n    (rst_n),
        .btn_cw   (clean_btn_y_cw),
        .btn_ccw  (clean_btn_y_ccw),
        .step_pin (step_y),
        .dir_pin  (dir_y)
    );

    // Gripper Motor Controller (Closed-loop tracking)
    gripper_stepper_controller motor_gripper (
        .clk            (clk),
        .n_rst          (rst_n),
        .dip_switch     (clean_dip_grip),
        .rigidez_switch (clean_sw_limit),
        .step_pin       (step_grip),
        .dir_pin        (dir_grip)
    );

endmodule