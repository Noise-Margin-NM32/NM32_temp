# Batch-mode XSim run of the full-chip testbench.
#   Usage (from the repo root):  vivado -mode batch -source run_sim_tcl.tcl
# 40 ms covers boot (~13 ms) and the first FFT (~39 ms). Use 60 ms to see
# frame 0 finish (~51 ms) and frame 1 start. Outputs land in
#   NM32_top_temp/NM32_top_temp.sim/sim_1/behav/xsim/
# Add  set_property -name {xsim.compile.xvlog.more_options} -value {-d NM32_TRACE} -objects [get_filesets sim_1]
# before launch_simulation to enable the verbose debug traces.
open_project NM32_top_temp/NM32_top_temp.xpr
launch_simulation
run 40 ms
exit
