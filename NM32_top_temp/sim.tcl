# Run the testbench until it calls $finish (all frames done, trap, watchdog
# or the 800 ms timeout). Run from inside NM32_top_temp/:
#   vivado -mode batch -source sim.tcl
open_project NM32_top_temp.xpr
launch_simulation
run all
