open_project NM32_top_temp/NM32_top_temp.xpr
remove_files [get_files ahb_arbiter.sv]
add_files -norecurse {AHB/ahb_arbiter_simplified.v AHB/ahb_decoder_simplified.v AHB/ahb_decoder_arbiter_top.v}
update_compile_order -fileset sources_1
launch_simulation
run 48 ms
exit
