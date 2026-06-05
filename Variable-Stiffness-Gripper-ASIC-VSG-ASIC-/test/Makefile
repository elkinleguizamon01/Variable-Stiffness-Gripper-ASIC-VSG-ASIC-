# Makefile — test/Makefile
# Tiny Tapeout Project Test Configuration

SIM           ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR        = $(PWD)/../src

# Source files - ALL .v files needed
PROJECT_SOURCES = project.v \
                  brazo_digital_top.v \
                  debouncer.v \
                  nema_controller.v \
                  gripper_stepper_controller.v

# RTL simulation (default)
ifneq ($(GATES),yes)
	SIM_BUILD        = sim_build/rtl
	VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))
else
	# Gate-level simulation (post-synthesis)
	SIM_BUILD        = sim_build/gl
	COMPILE_ARGS    += -DGL_TEST
	COMPILE_ARGS    += -DFUNCTIONAL
	COMPILE_ARGS    += -DUSE_POWER_PINS
	COMPILE_ARGS    += -DSIM
	COMPILE_ARGS    += -DUNIT_DELAY=\#1
	VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
	VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
	VERILOG_SOURCES += $(PWD)/gate_level_netlist.v
endif

COMPILE_ARGS    += -I$(SRC_DIR)
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL         = tb
COCOTB_TEST_MODULES = test

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: clean-all
clean-all: clean
	rm -rf sim_build/ results.xml tb.fst

.PHONY: show-sources
show-sources:
	@echo "RTL Sources:"
	@$(foreach src,$(PROJECT_SOURCES),echo "  - $(SRC_DIR)/$(src)";)