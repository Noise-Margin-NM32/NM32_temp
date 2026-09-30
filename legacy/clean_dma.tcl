# Remove the second old missing file from the project
remove_files [get_files *dma_ahb32_reg_params.v] -quiet

# Ensure automatic compile order is back on
set_property source_mgmt_mode All [current_project]
update_compile_order -fileset sources_1

puts "========================================================="
puts "SECOND FILE DELETED. YOU ARE GOOD TO LAUNCH SIMULATION!"
puts "========================================================="
