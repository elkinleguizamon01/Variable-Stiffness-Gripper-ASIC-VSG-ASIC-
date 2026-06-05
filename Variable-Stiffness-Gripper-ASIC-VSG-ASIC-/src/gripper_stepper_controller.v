// ============================================================
// Module: gripper_stepper_controller
// Description: Closed-loop smart gripper control. Closes until a 
//              switch detects contact, then memorizes the path 
//              to safely open back up later.
// ============================================================
module gripper_stepper_controller (
    input  wire clk,             
    input  wire n_rst,           
    input  wire dip_switch,      // Master switch: 1 = Close and grab, 0 = Release
    input  wire rigidez_switch,  // Physical limit switch: 1 = Contact/Stiffness detected
    
    output wire step_pin,        // To driver STEP pin
    output reg  dir_pin          // To driver DIR pin
);
    localparam SPEED_DIV = 16'd6_250; 
    localparam MAX_STEPS = 32'd50_000; // Hard safety stop to prevent mechanical damage

    // State machine definitions
    localparam STATE_OPEN    = 2'd0; // Home position, waiting for action
    localparam STATE_CLOSING = 2'd1; // Actively moving to grab something
    localparam STATE_HOLD    = 2'd2; // Object detected, holding position firmly
    localparam STATE_OPENING = 2'd3; // Switch turned off, returning home

    reg [1:0]  current_state;
    reg [15:0] step_timer;
    reg [31:0] current_position; // Mileage tracker for steps taken
    reg        step_reg;         

    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            current_state    <= STATE_OPEN;
            current_position <= 32'd0;
            step_timer       <= 16'd0;
            step_reg         <= 1'b0;
            dir_pin          <= 1'b0;
        end else begin
            case (current_state)
                
                // Resting at home, waiting for the user to flip the DIP switch
                STATE_OPEN: begin
                    step_reg <= 1'b0;
                    dir_pin  <= 1'b0; 
                    if (dip_switch == 1'b1) begin
                        current_state <= STATE_CLOSING;
                        dir_pin       <= 1'b1; // Set direction to close
                    end
                end

                // Moving the jaws inward
                STATE_CLOSING: begin
                    // User changed their mind mid-way, abort and back out
                    if (dip_switch == 1'b0) begin
                        current_state <= STATE_OPENING;
                        dir_pin       <= 1'b0; 
                        step_reg      <= 1'b0;
                    end
                    // We hit the object OR we reached the absolute safety boundary
                    else if (rigidez_switch == 1'b1 || current_position >= MAX_STEPS) begin
                        current_state <= STATE_HOLD;
                        step_reg      <= 1'b0; // Stop stepping to freeze position
                    end
                    // Path is clear, keep closing smoothly
                    else begin
                        if (step_timer >= SPEED_DIV) begin
                            step_timer <= 16'd0;
                            step_reg   <= ~step_reg; 
                            if (step_reg == 1'b0) begin 
                                current_position <= current_position + 1'b1; // Count steps taken
                            end
                        end else begin
                            step_timer <= step_timer + 1'b1;
                        end
                    end
                end

                // Holding the object securely using the motor's natural holding torque
                STATE_HOLD: begin
                    step_reg <= 1'b0; 
                    if (dip_switch == 1'b0) begin
                        current_state <= STATE_OPENING;
                        dir_pin       <= 1'b0; // Switch off means time to let go
                    end
                end

                // Backtracking exactly the same amount of steps we took to close
                STATE_OPENING: begin
                    // Safety check: User wants to re-grab before we finish opening
                    if (dip_switch == 1'b1) begin
                        current_state <= STATE_CLOSING;
                        dir_pin       <= 1'b1; 
                        step_reg      <= 1'b0;
                    end
                    // We are back at the exact zero starting position
                    else if (current_position == 32'd0) begin
                        current_state <= STATE_OPEN;
                        step_reg      <= 1'b0;
                    end
                    // Step backward and decrement our position tracker
                    else begin
                        if (step_timer >= SPEED_DIV) begin
                            step_timer <= 16'd0;
                            step_reg   <= ~step_reg; 
                            if (step_reg == 1'b0) begin 
                                current_position <= current_position - 1'b1;
                            end
                        end else begin
                            step_timer <= step_timer + 1'b1;
                        end
                    end
                end
                
                default: current_state <= STATE_OPEN;
            endcase
        end
    end

    assign step_pin = step_reg;
endmodule