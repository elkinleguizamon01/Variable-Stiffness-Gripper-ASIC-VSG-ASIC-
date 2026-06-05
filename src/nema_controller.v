// ============================================================
// Module: nema_controller
// Description: Direct manual control for a NEMA 17 stepper motor 
//              using two directional buttons.
// ============================================================
module nema_controller (
    input  wire clk,          // Main 50 MHz clock
    input  wire rst_n,        // Active-low system reset
    
    // Clean inputs coming straight from the debouncers
    input  wire btn_cw,       // Press to rotate Clockwise
    input  wire btn_ccw,      // Press to rotate Counter-Clockwise
    
    // External driver outputs (DRV8825 / A4988)
    output wire step_pin,     // Tells the driver when to take a step
    output reg  dir_pin       // High = CW, Low = CCW
);

    // Frequency divider: 6250 toggles give us a clean 1 kHz step pulse rate
    localparam SPEED_DIV = 16'd6_250; 

    reg [15:0] step_counter;
    reg        step_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step_counter <= 16'd0;
            step_reg     <= 1'b0;
            dir_pin      <= 1'b0;
        end else begin
            // Scenario 1: User wants to move Clockwise
            if (btn_cw && !btn_ccw) begin
                dir_pin <= 1'b1;
                if (step_counter >= SPEED_DIV) begin
                    step_counter <= 16'd0;
                    step_reg     <= ~step_reg; // Toggle to create the square wave
                end else begin
                    step_counter <= step_counter + 1'b1;
                end
            end
            // Scenario 2: User wants to move Counter-Clockwise
            else if (btn_ccw && !btn_cw) begin
                dir_pin <= 1'b0;
                if (step_counter >= SPEED_DIV) begin
                    step_counter <= 16'd0;
                    step_reg     <= ~step_reg;
                end else begin
                    step_counter <= step_counter + 1'b1;
                end
            end
            // Scenario 3: Nobody is pressing anything (or both are pressed) -> Stop moving
            else begin
                step_counter <= 16'd0;
                step_reg     <= 1'b0; // Hold line low so the motor locks securely in place
            end
        end
    end

    assign step_pin = step_reg;
endmodule