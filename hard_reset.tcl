# HARD RESET IBEX FILES IN VIVADO

set SOC_ROOT "/home/r_sarang/NM32_SoC"

# 1. Switch to Manual Compile Order FIRST so Vivado's auto-scanner doesn't drop files
set_property source_mgmt_mode DisplayOnly [current_project]

# 2. Completely remove all Ibex files from the project
remove_files [get_files -quiet *ibex*.sv] -quiet

# 3. Add them all back while in Manual Mode
add_files -norecurse [glob -nocomplain "$SOC_ROOT/Ibex/rtl/*.sv"]
add_files -norecurse [glob -nocomplain "$SOC_ROOT/Ibex/shared/rtl/*.sv"]

# 4. Explicitly tag them as SystemVerilog
set_property file_type SystemVerilog [get_files -quiet *ibex*.sv]

# 5. Make the package a global include and force it to the front
set pkg_file [get_files -quiet "*/Ibex/rtl/ibex_pkg.sv"]
if {$pkg_file != ""} {
    set_property is_global_include true $pkg_file
    reorder_files -front $pkg_file
}

puts "========================================================="
puts "IBEX FILES HARD RESET IN MANUAL MODE."
puts "YOU ARE CLEARED FOR LAUNCH_SIMULATION!"
puts "========================================================="
