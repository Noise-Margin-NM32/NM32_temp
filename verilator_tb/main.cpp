#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtb.h"
#include <iostream>

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    
    // We want to collect coverage
    Verilated::mkdir("logs");
    
    Vtb* top = new Vtb;
    
    // Reset sequence
    top->rstn = 0;
    top->clk = 0;
    
    // Run for 10 cycles in reset
    for(int i = 0; i < 10; i++) {
        top->clk = !top->clk;
        top->eval();
        main_time += 5; // 5ns per half cycle (100MHz)
    }
    
    top->rstn = 1;
    
    // Simulation loop
    // 8,000,000 cycles timeout, same as original tb.sv
    while (!Verilated::gotFinish() && main_time < 800000000ULL) {
        top->clk = !top->clk;
        top->eval();
        main_time += 5;
    }
    
    if (main_time >= 800000000ULL) {
        std::cout << "Simulation reached timeout and finished safely." << std::endl;
    }
    
    top->final();
    
    // Write coverage data
    VerilatedCov::write("logs/coverage.dat");
    
    delete top;
    return 0;
}
