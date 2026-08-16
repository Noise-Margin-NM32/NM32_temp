# TCL script to update the Vivado project for the Ibex CPU Swap

set SOC_ROOT "/home/r_sarang/NM32_SoC"

# 1. Remove PicoRV32 files
remove_files [get_files *picorv32.v] -quiet
remove_files [get_files *pico_to_ahb.v] -quiet

# 2. Add the custom Ibex-to-AHB bridge
add_files -norecurse "$SOC_ROOT/NM32_top_temp/NM32_top_temp.srcs/sources_1/new/ibex_to_ahb.sv"

# 3. Add Ibex Core RTL and Dependencies
add_files [glob -nocomplain $SOC_ROOT/Ibex/rtl/*.sv]
add_files [glob -nocomplain $SOC_ROOT/Ibex/shared/rtl/*.sv]

# Add primitives (like prim_assert and prim_cipher) needed by Ibex
add_files [glob -nocomplain $SOC_ROOT/Ibex/vendor/lowrisc_ip/ip/prim/rtl/*.sv]
add_files [glob -nocomplain $SOC_ROOT/Ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/*.sv]

# 4. Set Include Directories
# Ibex needs these paths to find its .svh macros
set_property include_dirs [list \
    "$SOC_ROOT/Ibex/rtl" \
    "$SOC_ROOT/Ibex/vendor/lowrisc_ip/dv/sv/dv_utils" \
    "$SOC_ROOT/Ibex/vendor/lowrisc_ip/ip/prim/rtl" \
] [current_fileset]

# 5. Update Compile Order
update_compile_order -fileset sources_1

puts "Vivado project successfully updated for Ibex with all new RTL files!"
