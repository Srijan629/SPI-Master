# SPI Master Controller

A hardware implementation of an **SPI (Serial Peripheral Interface) Master Controller** designed in synthesizable Verilog HDL and verified using Xilinx Vivado. This core enables high-speed, synchronous point-to-point data transmission between peripheral ICs.

## 🛠️ Design Architecture & Features

The module is built using a structured algorithmic Finite State Machine (FSM) tracking standard SPI Mode 0 parameters (CPOL=0, CPHA=0):

* **FSM Engine:** Implements structural states (`IDLE`, `TRANSFER`, `DONE`) ensuring clean control line handshaking and state isolation.
* **Clock Divider Core:** Divides the global high-speed system clock cleanly to deliver a stable, synchronized transmission clock line (`SCLK`).
* **Shift Matrices:** High-performance internal parallel-to-serial registers managing synchronous MSB-first output (`MOSI`) and serial-to-parallel registers acquiring slave incoming inputs (`MISO`).

## 📂 Project Structure

```text
├── RTL/
│   └── spi_master.v     # Core SPI Master Control Architecture
├── TESTBENCH/
│   └── spi_master_tb.v  # Loopback Emulation Testbench
└── WAVEFORM.png         # Simulation Timing Trace Grid
