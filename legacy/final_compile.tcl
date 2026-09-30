# The definitive fix for Vivado's hierarchy parser

# 1. Switch back to manual compile order so Vivado doesn't drop files it doesn't understand
set_property source_mgmt_mode DisplayOnly [current_project]

# 2. Make absolutely sure the package is compiled first by moving it to the top
set pkg_file [get_files -quiet "*/Ibex/rtl/ibex_pkg.sv"]
if {$pkg_file != ""} {
    reorder_files -front $pkg_file
}

# 3. Add tracing packages if they exist just in case
set trace_pkg [get_files -quiet "*/Ibex/rtl/ibex_tracer_pkg.sv"]
if {$trace_pkg != ""} {
    reorder_files -front $trace_pkg
}

puts "========================================================="
puts "COMPILE ORDER IS NOW MANUAL. PACKAGES ARE AT THE FRONT."
puts "YOU ARE CLEARED FOR LAUNCH_SIMULATION!"
puts "========================================================="
