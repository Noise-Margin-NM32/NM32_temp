# Fix Vivado compile order for Ibex SystemVerilog packages

# Mark the Ibex package as a global include so Vivado parses it before all other files
set_property is_global_include true [get_files -quiet *ibex_pkg.sv]

# Also ensure all Ibex files are strictly parsed as SystemVerilog
set_property file_type SystemVerilog [get_files -quiet *ibex*.sv]

# Force Vivado to re-evaluate the compile order now that the package is global
update_compile_order -fileset sources_1

puts "Compile order fixed! You can now launch simulation."
