<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a digital control system for a two-joint robotic arm with a servo-driven mini gripper, described entirely in Verilog HDL and targeting the SkyWater SKY130 130 nm process via Tiny Tapeout.

The design consists of the following functional blocks:

- **Finite State Machine (FSM):** Central controller that manages the operating states of the system — idle, joint 1 movement, joint 2 movement, gripper open, and gripper close. State transitions are triggered by the digital input commands.

- **Stepper Motor Controllers (×2):** One controller per arm joint. Each generates the four-phase step sequence required to drive a stepper motor, with configurable direction. Joint 1 and Joint 2 are controlled independently.

- **SG90 Servo PWM Driver:** Generates a 50 Hz PWM signal with a pulse width between 1 ms (0°) and 2 ms (180°) to position the SG90 servo motor that actuates the gripper. The output switches between a fully open and fully closed position based on the active command.

- **Limit Switch Interface:** Reads two digital inputs corresponding to the end-of-course buttons mounted on both sides of the arm. When either limit switch is asserted, the FSM halts servo movement in that direction, preventing mechanical overtravel and protecting the gripper hardware.

All modules are synchronous to the system clock and include a synchronous active-high reset.

## How to test

1. Apply clock and assert reset (`rst = 1`) for at least two clock cycles to initialize the FSM and all internal registers. Then deassert reset (`rst = 0`).

2. Drive the `ui_in` input pins with the desired command according to the table below:

| `ui_in` value | Action |
|---|---|
| `00000001` | Move Joint 1 — forward |
| `00000010` | Move Joint 1 — reverse |
| `00000100` | Move Joint 2 — forward |
| `00001000` | Move Joint 2 — reverse |
| `00010000` | Close gripper (servo to 0°) |
| `00100000` | Open gripper (servo to 180°) |
| `00000000` | Stop / Idle |

3. Observe the `uo_out` output pins:
   - `uo_out[3:0]` — 4-phase step output for Stepper Motor 1 (Joint 1)
   - `uo_out[7:4]` — 4-phase step output for Stepper Motor 2 (Joint 2)

4. The servo PWM signal is available on `uio_out[0]` (bidirectional pin configured as output). Connect this pin to the signal wire of the SG90 servo.

5. To test the limit switches, assert `ui_in[6]` (limit switch side A) or `ui_in[7]` (limit switch side B) while a gripper open or close command is active. The servo output should immediately stop when the corresponding limit is reached.

> **Tip:** Use a logic analyzer or oscilloscope on `uio_out[0]` to verify the PWM period (20 ms) and pulse width (1 ms for closed, 2 ms for open) of the servo signal.

## External hardware

| Component | Quantity | Connection | Notes |
|---|---|---|---|
| Stepper motor | 2 | `uo_out[3:0]` (Joint 1), `uo_out[7:4]` (Joint 2) | Requires stepper driver board (e.g. A4988, ULN2003) — do not connect motor directly to ASIC pins |
| SG90 servo motor | 1 | `uio_out[0]` (PWM signal) | Power servo from external 5 V supply; connect GND in common |
| Limit switch (end-of-course) | 2 | `ui_in[6]` (side A), `ui_in[7]` (side B) | Wire as active-high: pull down with 10 kΩ resistor, switch connects pin to VCC |
| Stepper driver board (e.g. ULN2003 or A4988) | 2 | Between `uo_out` and stepper motors | Level shifting and current amplification required |
| External 5 V power supply | 1 | Servo VCC and stepper driver VCC | Do not draw servo/motor current from the ASIC supply |