#!/bin/bash
set -e

echo "Finding Verilog source files from Vivado project..."
# Extract files from Vivado xpr, removing XML tags and substituting $PPRDIR
SOURCES=$(grep '<File Path=' ../NM32_top_temp/NM32_top_temp.xpr | grep -E '\.v"|\.sv"' | grep -v 'tb.sv' | grep -v 'old_tb.sv' | grep -v 'tb_' | sed 's/.*Path="\([^"]*\)".*/\1/' | sed 's/\$PPRDIR/..\/NM32_top_temp/g' | sed 's/\$PSRCDIR/..\/NM32_top_temp\/NM32_top_temp.srcs/g')

# Add the modified testbench
SOURCES="$SOURCES verilator_tb.sv"

# Get all unique directories from SOURCES to include
INCDIRS=$(echo "$SOURCES" | xargs -n1 dirname | sort -u | awk '{print "-I"$1}')

echo "Compiling with Verilator..."
verilator --cc --exe --coverage -Wno-fatal -Wno-lint -Wno-UNOPTFLAT -Wno-MULTIDRIVEN -Wno-ALWCOMBORDER -Wno-COMBDLY -Wno-TIMESCALEMOD --top-module tb $INCDIRS $SOURCES main.cpp -CFLAGS "-std=c++11"

echo "Building C++ executable..."
cd obj_dir
make -j$(nproc) -f Vtb.mk Vtb

echo "Running simulation for coverage..."
./Vtb

echo "Generating HTML coverage report..."
verilator_coverage --annotate logs/annotated logs/coverage.dat
echo "Coverage data generated in logs/coverage.dat"
