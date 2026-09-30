# STRICT DMA HEADER FIX

# Grab the exact file
set file_obj [get_files "/home/r_sarang/NM32_SoC/DMA/dma_ahb32_ch_reg_params.v"]

# Force it to be a header
set_property file_type "Verilog Header" $file_obj
set_property is_global_include true $file_obj
set_property used_in_synthesis false $file_obj
set_property used_in_simulation false $file_obj

# Return compile order to automatic so we don't have to deal with manual mode bugs anymore!
set_property source_mgmt_mode All [current_project]
update_compile_order -fileset sources_1

puts "========================================================="
puts "DMA FIX APPLIED SUCCESSFULLY! YOU CAN LAUNCH SIMULATION!"
puts "========================================================="
