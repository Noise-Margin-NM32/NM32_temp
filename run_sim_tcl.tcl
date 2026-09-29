open_project NM32_top_temp/NM32_top_temp.xpr
add_files -norecurse DMA_Module/dma_controller.v
add_files -norecurse Ibex/rtl/ibex_register_file_ff.sv
update_compile_order -fileset sources_1
launch_simulation
run 800 ms
exit
