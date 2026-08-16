# Tell Vivado that this file is a header/include file, not a standalone module
set dma_param_file [get_files -quiet "*/DMA/dma_ahb32_ch_reg_params.v"]
if {$dma_param_file != ""} {
    set_property file_type "Verilog Header" $dma_param_file
    set_property is_global_include true $dma_param_file
}

puts "DMA parameter file fixed! You can now run launch_simulation."
