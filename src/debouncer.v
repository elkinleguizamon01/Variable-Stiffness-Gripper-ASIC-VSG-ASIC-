// ============================================================
// Module: debouncer
// Description: Cleans up mechanical switch noise by waiting 
//              for the signal to settle before updating.
// ============================================================
module debouncer #(
    // 50 MHz clock * 20 ms debounce window = 1,000,000 cycles
    parameter STABLE_TIME = 20'd1_000_000 
)(
    input  wire clk,
    input  wire rst_n,
    input  wire noisy_in,   // Raw input straight from the physical pin
    output reg  clean_out   // Filtered, rock-solid output for our logic
);

    reg [19:0] counter;
    reg state_sync_1, state_sync_2;

    // 2-stage synchronizer to avoid metastability issues with external inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_sync_1 <= 1'b0;
            state_sync_2 <= 1'b0;
        end else begin
            state_sync_1 <= noisy_in;
            state_sync_2 <= state_sync_1;
        end
    end

    // Settle down timer logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter   <= 20'd0;
            clean_out <= 1'b0;
        end else begin
            if (state_sync_2 == clean_out) begin
                // Signal is steady and matches our current state, nothing to do
                counter <= 20'd0;
            end else begin
                // Signal changed! Start counting to make sure it's not just a glitch
                counter <= counter + 1'b1;
                if (counter >= STABLE_TIME) begin
                    // It stayed stable long enough, let's accept the new state
                    clean_out <= state_sync_2;
                    counter   <= 20'd0;
                end
            end
        end
    end
endmodule