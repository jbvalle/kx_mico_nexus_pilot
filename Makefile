CC = arm-none-eabi-gcc

# Find all C source files recursively
SRC := $(shell find . -name "*.c")

# Generate object paths under _gen/obj
OBJ := $(patsubst ./%, _gen/obj/%, $(SRC:.c=.o))

# Find linker script(s)
LINKER := $(shell find . -name "*.ld")

# Architecture
MARCH = cortex-m4

# Collect all dirs for -I (so headers anywhere are visible)
INCLUDE_DIRS := $(shell find . -type d)
CFLAGS = -g -Wall -mcpu=$(MARCH) -mthumb -mfloat-abi=soft \
         $(addprefix -I,$(INCLUDE_DIRS)) \
         -ffreestanding -nostartfiles

# Linker flags
LFLAGS = -nostdlib -T $(LINKER) -Wl,-Map=_gen/main.map

# OpenOCD
OPENOCD_IF = /usr/share/openocd/scripts/interface/stlink.cfg
OPENOCD_TARGET = /usr/share/openocd/scripts/target/stm32f4x.cfg

# Target
TARGET = _gen/main.elf

# Default
all: $(OBJ) $(TARGET)

# Compile C -> O (mirror structure in _gen/obj)
_gen/obj/%.o : %.c | mkdir_obj
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c -o $@ $<

# Link
$(TARGET): $(OBJ) | mkdir_gen
	$(CC) $(CFLAGS) $(LFLAGS) -o $@ $^

# Ensure base obj dir exists
mkdir_obj:
	mkdir -p _gen/obj

mkdir_gen:
	mkdir -p _gen

mkdir_log:
	mkdir -p _log

# Flash
flash: FORCE
	openocd -f $(OPENOCD_IF) -f $(OPENOCD_TARGET) &
	gdb-multiarch $(TARGET) -x tools/flash.gdb

# Memory report
mem_report: FORCE | mkdir_log
	python tools/mem_visualizer.py -o _log/mem_layout.html _gen/main.map

# Clean
clean:
	rm -rf _gen/obj _gen/*.elf _gen/*.map log/* _gen/ _log

FORCE:

# Debugging helper
test:
	@echo "SRC: $(SRC)"
	@echo "OBJ: $(OBJ)"
	@echo "INCLUDE_DIRS: $(INCLUDE_DIRS)"

