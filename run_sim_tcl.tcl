open_project NM32_top_temp/NM32_top_temp.xpr
add_files -norecurse DMA_Module/dma_controller.v
update_compile_order -fileset sources_1
launch_simulation
run 40 ms
exit
