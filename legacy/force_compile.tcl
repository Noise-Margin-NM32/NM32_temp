# Force manual compile order and explicitly add all Ibex files
set SOC_ROOT "/home/r_sarang/NM32_SoC"

# 1. Disable automatic compile order
set_property source_mgmt_mode DisplayOnly [current_project]

# 2. Make sure ibex_pkg is compiled BEFORE everything else
set pkg_file [get_files -quiet "$SOC_ROOT/Ibex/rtl/ibex_pkg.sv"]
if {$pkg_file != ""} {
    set_property is_global_include true $pkg_file
}

# 3. Explicitly read the files using read_verilog (bypasses GUI bugs)
puts "Forcing read of Ibex files..."
read_verilog -sv "$SOC_ROOT/Ibex/rtl/ibex_pkg.sv"
read_verilog -sv [glob -nocomplain "$SOC_ROOT/Ibex/rtl/*.sv"]
read_verilog -sv [glob -nocomplain "$SOC_ROOT/Ibex/shared/rtl/*.sv"]
read_verilog -sv [glob -nocomplain "$SOC_ROOT/Ibex/vendor/lowrisc_ip/ip/prim/rtl/*.sv"]
read_verilog -sv [glob -nocomplain "$SOC_ROOT/Ibex/vendor/lowrisc_ip/ip/prim_generic/rtl/*.sv"]

# 4. Re-apply include dirs just in case
set_property include_dirs [list \
    "$SOC_ROOT/Ibex/rtl" \
    "$SOC_ROOT/Ibex/vendor/lowrisc_ip/dv/sv/dv_utils" \
    "$SOC_ROOT/Ibex/vendor/lowrisc_ip/ip/prim/rtl" \
] [current_fileset]

puts "Manual compile order forced. Please run launch_simulation now."
