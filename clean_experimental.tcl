# Remove experimental CHERIoT files that break compilation
remove_files [get_files -quiet "*/Ibex/rtl/ibex_trvk.sv"] -quiet
remove_files [get_files -quiet "*/Ibex/rtl/ibex_cheriot_pkg.sv"] -quiet

puts "========================================================="
puts "EXPERIMENTAL FILES REMOVED. READY FOR LAUNCH_SIMULATION!"
puts "========================================================="
