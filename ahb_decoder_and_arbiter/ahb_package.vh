//==========================================================================
// Project : NM32 "KAVACH" SoC (Noise Margin)
// File    : ahb_package.vh
// Purpose : Shared AMBA AHB encodings used by the interconnect and the
//           accelerator slave-wait wrappers.
// Notes   : Derived from the OpenCores "AHB system generator" package
//           (Federico Aglietti), trimmed to the macros this SoC uses.
//           Macros are global once included - avoid reusing these names.
//==========================================================================

`ifndef AHB_PACKAGE_VH
`define AHB_PACKAGE_VH

// ---- HBURST ----
`define INCR     3'b001     // Incrementing burst of unspecified length

// ---- HSIZE ----
`define BITS32   3'b010     // 32-bit word transfer

// ---- HTRANS ----
`define IDLE     2'b00      // No transfer
`define BUSY     2'b01      // Master inserting a wait inside a burst
`define NONSEQ   2'b10      // First (or single) beat of a transfer
`define SEQ      2'b11      // Subsequent beat of a burst

// ---- HRESP ----
`define OK_RESP     2'b00
`define ERROR_RESP  2'b01

`endif // AHB_PACKAGE_VH
