# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

# test.py — cocotb tests for tt_um_brazo_digital
#
# Pin map (see tb.v for full reference):
#   ui_in[0] = noisy_btn_x_cw     uo_out[0] = step_x
#   ui_in[1] = noisy_btn_x_ccw    uo_out[1] = dir_x
#   ui_in[2] = noisy_btn_y_cw     uo_out[2] = step_y
#   ui_in[3] = noisy_btn_y_ccw    uo_out[3] = dir_y
#   ui_in[4] = noisy_dip_grip     uo_out[4] = step_grip
#   ui_in[5] = noisy_sw_limit     uo_out[5] = dir_grip
#
# SPEED_DIV = 6250 cycles per half-step → full step = 12500 cycles
# Debounce STABLE_TIME = 1,000,000 cycles (20 ms at 50 MHz)
# To keep simulation fast we drive inputs for > STABLE_TIME + margin.

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

# ── Pin bit positions ────────────────────────────────────────────────────────
BTN_X_CW  = 0
BTN_X_CCW = 1
BTN_Y_CW  = 2
BTN_Y_CCW = 3
DIP_GRIP  = 4
SW_LIMIT  = 5

STEP_X    = 0
DIR_X     = 1
STEP_Y    = 2
DIR_Y     = 3
STEP_GRIP = 4
DIR_GRIP  = 5

# Cycles needed to clear the debouncer + step generation margin
DEBOUNCE  = 1_000_000
STEP_DIV  = 6_250        # half-step period of nema_controller
STEP_WAIT = STEP_DIV * 5 + 1000 # wait for a couple of full pulses


# ── Helper: standard TT reset ────────────────────────────────────────────────
async def tt_reset(dut):
    dut.ena.value    = 1
    dut.ui_in.value  = 0
    dut.uio_in.value = 0
    dut.rst_n.value  = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value  = 1
    await RisingEdge(dut.clk)


def bit(val, pos):
    """Extract a single bit from a cocotb value."""
    return (int(val) >> pos) & 1


# ════════════════════════════════════════════════════════════════════════════
# Test 1 – Reset: all outputs low after reset
# ════════════════════════════════════════════════════════════════════════════
@cocotb.test()
async def test_01_reset(dut):
    """All outputs must be 0 immediately after reset with no inputs asserted."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await tt_reset(dut)

    assert dut.uo_out.value == 0, \
        f"uo_out should be 0 after reset, got {dut.uo_out.value}"
    dut._log.info("PASS: reset → uo_out = 0x00")


# ════════════════════════════════════════════════════════════════════════════
# Test 2 – X-axis clockwise: dir_x=1, step_x oscillates
# ════════════════════════════════════════════════════════════════════════════
@cocotb.test()
async def test_02_x_axis_cw(dut):
    """btn_x_cw held: after debounce, dir_x must be 1 and step_x must toggle."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await tt_reset(dut)

    # Hold button longer than debounce window
    dut.ui_in.value = (1 << BTN_X_CW)
    await ClockCycles(dut.clk, DEBOUNCE + 100)

    assert bit(dut.uo_out.value, DIR_X) == 1, \
        f"dir_x should be 1 for CW, got {bit(dut.uo_out.value, DIR_X)}"

    # Check step_x toggles
    s0 = bit(dut.uo_out.value, STEP_X)
    await ClockCycles(dut.clk, STEP_WAIT)
    s1 = bit(dut.uo_out.value, STEP_X)
    assert s0 != s1, "step_x did not toggle during X CW motion"

    # Y and gripper must stay idle
    assert bit(dut.uo_out.value, STEP_Y)    == 0, "step_y must be 0"
    assert bit(dut.uo_out.value, STEP_GRIP) == 0, "step_grip must be 0"

    dut._log.info("PASS: X CW → dir_x=1, step_x toggles")


# ════════════════════════════════════════════════════════════════════════════
# Test 3 – X-axis counter-clockwise: dir_x=0, step_x oscillates
# ════════════════════════════════════════════════════════════════════════════
@cocotb.test()
async def test_03_x_axis_ccw(dut):
    """btn_x_ccw held: dir_x must be 0 and step_x must toggle."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await tt_reset(dut)

    dut.ui_in.value = (1 << BTN_X_CCW)
    await ClockCycles(dut.clk, DEBOUNCE + 100)

    assert bit(dut.uo_out.value, DIR_X) == 0, \
        f"dir_x should be 0 for CCW, got {bit(dut.uo_out.value, DIR_X)}"

    s0 = bit(dut.uo_out.value, STEP_X)
    await ClockCycles(dut.clk, STEP_WAIT)
    s1 = bit(dut.uo_out.value, STEP_X)
    assert s0 != s1, "step_x did not toggle during X CCW motion"

    dut._log.info("PASS: X CCW → dir_x=0, step_x toggles")


# ════════════════════════════════════════════════════════════════════════════
# Test 4 – Y-axis clockwise
# ════════════════════════════════════════════════════════════════════════════
@cocotb.test()
async def test_04_y_axis_cw(dut):
    """btn_y_cw held: dir_y=1, step_y toggles, X and gripper stay idle."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await tt_reset(dut)

    dut.ui_in.value = (1 << BTN_Y_CW)
    await ClockCycles(dut.clk, DEBOUNCE + 100)

    assert bit(dut.uo_out.value, DIR_Y) == 1, "dir_y should be 1"

    s0 = bit(dut.uo_out.value, STEP_Y)
    await ClockCycles(dut.clk, STEP_WAIT)
    s1 = bit(dut.uo_out.value, STEP_Y)
    assert s0 != s1, "step_y did not toggle"

    assert bit(dut.uo_out.value, STEP_X)    == 0, "step_x must be 0"
    assert bit(dut.uo_out.value, STEP_GRIP) == 0, "step_grip must be 0"

    dut._log.info("PASS: Y CW → dir_y=1, step_y toggles")


# ════════════════════════════════════════════════════════════════════════════
# Test 5 – Conflict: both X buttons → step_x stays 0
# ════════════════════════════════════════════════════════════════════════════
@cocotb.test()
async def test_05_x_conflict(dut):
    """Both X buttons simultaneously: step_x must remain 0 (nema_controller idle)."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await tt_reset(dut)

    dut.ui_in.value = (1 << BTN_X_CW) | (1 << BTN_X_CCW)
    await ClockCycles(dut.clk, DEBOUNCE + STEP_WAIT)

    assert bit(dut.uo_out.value, STEP_X) == 0, \
        "step_x must be 0 when both X buttons are pressed"

    dut._log.info("PASS: X conflict → step_x = 0")


# ════════════════════════════════════════════════════════════════════════════
# Test 6 – Gripper closes: dip_grip=1, dir_grip=1, step_grip toggles
# ════════════════════════════════════════════════════════════════════════════
@cocotb.test()
async def test_06_gripper_closing(dut):
    """dip_grip=1: gripper must close (dir_grip=1) and step_grip must toggle."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await tt_reset(dut)

    dut.ui_in.value = (1 << DIP_GRIP)
    await ClockCycles(dut.clk, DEBOUNCE + 100)

    assert bit(dut.uo_out.value, DIR_GRIP) == 1, \
        f"dir_grip should be 1 while closing, got {bit(dut.uo_out.value, DIR_GRIP)}"

    s0 = bit(dut.uo_out.value, STEP_GRIP)
    await ClockCycles(dut.clk, STEP_WAIT)
    s1 = bit(dut.uo_out.value, STEP_GRIP)
    assert s0 != s1, "step_grip did not toggle while closing"

    dut._log.info("PASS: gripper closing → dir_grip=1, step_grip toggles")


# ════════════════════════════════════════════════════════════════════════════
# Test 7 – Gripper holds on contact: step_grip stops when sw_limit fires
# ════════════════════════════════════════════════════════════════════════════
@cocotb.test()
async def test_07_gripper_hold_on_contact(dut):
    """When sw_limit fires during closing, step_grip must freeze (HOLD state)."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await tt_reset(dut)

    # Start closing
    dut.ui_in.value = (1 << DIP_GRIP)
    await ClockCycles(dut.clk, DEBOUNCE + STEP_WAIT)

    # Trigger limit switch (hold for debounce)
    dut.ui_in.value = (1 << DIP_GRIP) | (1 << SW_LIMIT)
    await ClockCycles(dut.clk, DEBOUNCE + 100)

    # step_grip must be 0 (motor frozen in HOLD state)
    assert bit(dut.uo_out.value, STEP_GRIP) == 0, \
        "step_grip must be 0 after contact detected (HOLD state)"

    # Confirm it stays at 0 for additional cycles
    await ClockCycles(dut.clk, STEP_WAIT)
    assert bit(dut.uo_out.value, STEP_GRIP) == 0, \
        "step_grip must remain 0 while holding"

    dut._log.info("PASS: gripper HOLD → step_grip frozen at 0")


# ════════════════════════════════════════════════════════════════════════════
# Test 8 – Gripper releases: dip_grip=0 after HOLD → gripper opens
# ════════════════════════════════════════════════════════════════════════════
@cocotb.test()
async def test_08_gripper_release(dut):
    """Turning dip_grip off after HOLD must reverse dir_grip and restart stepping."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await tt_reset(dut)

    # Close and detect contact
    dut.ui_in.value = (1 << DIP_GRIP)
    await ClockCycles(dut.clk, DEBOUNCE + STEP_WAIT)
    dut.ui_in.value = (1 << DIP_GRIP) | (1 << SW_LIMIT)
    await ClockCycles(dut.clk, DEBOUNCE + 100)

    # Release dip switch → gripper should open (STATE_OPENING)
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, DEBOUNCE + 100)

    assert bit(dut.uo_out.value, DIR_GRIP) == 0, \
        "dir_grip should be 0 (opening direction) after release"

    s0 = bit(dut.uo_out.value, STEP_GRIP)
    await ClockCycles(dut.clk, STEP_WAIT)
    s1 = bit(dut.uo_out.value, STEP_GRIP)
    assert s0 != s1, "step_grip should toggle while opening"

    dut._log.info("PASS: gripper release → dir_grip=0, step_grip toggles (opening)")


# ════════════════════════════════════════════════════════════════════════════
# Test 9 – Simultaneous X + Y motion (axes are independent)
# ════════════════════════════════════════════════════════════════════════════
@cocotb.test()
async def test_09_simultaneous_xy(dut):
    """Both X-CW and Y-CW active: both axes must step independently."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await tt_reset(dut)

    dut.ui_in.value = (1 << BTN_X_CW) | (1 << BTN_Y_CW)
    await ClockCycles(dut.clk, DEBOUNCE + 100)

    assert bit(dut.uo_out.value, DIR_X) == 1, "dir_x should be 1"
    assert bit(dut.uo_out.value, DIR_Y) == 1, "dir_y should be 1"

    sx0 = bit(dut.uo_out.value, STEP_X)
    sy0 = bit(dut.uo_out.value, STEP_Y)
    await ClockCycles(dut.clk, STEP_WAIT)
    sx1 = bit(dut.uo_out.value, STEP_X)
    sy1 = bit(dut.uo_out.value, STEP_Y)

    assert sx0 != sx1, "step_x did not toggle during simultaneous XY"
    assert sy0 != sy1, "step_y did not toggle during simultaneous XY"

    dut._log.info("PASS: simultaneous X+Y → both axes step correctly")
