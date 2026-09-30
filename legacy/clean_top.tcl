# Remove ibex_top and ibex_top_tracing since we only need ibex_core
remove_files [get_files -quiet "*/Ibex/rtl/ibex_top*.sv"] -quiet

puts "========================================================="
puts "TOP WRAPPERS REMOVED. READY FOR LAUNCH_SIMULATION!"
puts "========================================================="
