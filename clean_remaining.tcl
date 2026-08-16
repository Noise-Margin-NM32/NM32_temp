# Remove remaining experimental/optional Ibex files
remove_files [get_files -quiet "*/Ibex/rtl/ibex_lockstep.sv"] -quiet
remove_files [get_files -quiet "*/Ibex/rtl/ibex_tracer*.sv"] -quiet
remove_files [get_files -quiet "*/Ibex/rtl/ibex_register_file_latch.sv"] -quiet

puts "========================================================="
puts "ALL REMAINING OPTIONAL FILES REMOVED. READY FOR LAUNCH!"
puts "========================================================="
