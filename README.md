# 🖥️ Artix-7 Mandelbrot Engine
### **Hardware Mandelbrot Renderer on Artix-7 with AXI4 DDR3 and VGA Output**

<p align="center">
  <img src="docs/result.jpg" alt="Mandelbrot Set on VGA Display" width="700"/>
</p>

---

## 🚀 Project Overview

This project implements a **fully hardware Mandelbrot set renderer** on a Digilent Arty A7-35T FPGA board. Every pixel of a 640×480 image is computed, stored in DDR3 memory, and displayed on a VGA monitor.

**The challenge:** Coordinate two independent clock domains (83.33 MHz compute/AXI and 25 MHz VGA), configure and integrate the MIG 7 Series DDR3 controller, manage AXI4 burst transactions to DDR3, and implement a ping-pong line buffer for display, all while meeting timing closure on an Artix-7.

---

## ⚡ Key Features

- **Fixed-Point Q4.28 Mandelbrot Engine** : Custom pipelined iterator running at 83.33 MHz
- **AXI4 Write** : 640×480 pixels written to DDR3 via AXI4
- **AXI4 Burst Read** : 5 × 128-beat bursts per line, loading one full line into the BRAM in advance of the VGA scan
- **Ping-Pong Double Buffering** : 1280-byte dual-clock BRAM synchronized across two clock domains 
- **VGA 640×480 @ 60 Hz** : Standard timing generator with RGB444 output and a custom color palette mapping iteration counts to a blue-to-white gradient
- **Clock Domain Crossing** : Explicit CDC management between 83.33 MHz (AXI/compute) and 25 MHz (VGA) 

---

## 🛠 Technology Stack

| Category | Details |
|---|---|
| **Target board** | Digilent Arty A7-35T (Xilinx Artix-7 XC7A35T) |
| **Design tool** | Vivado 2023.1 |
| **HDL** | VHDL |
| **Memory** | DDR3 256 MB |
| **Display** | VGA 640×480 @ 60 Hz, RGB444 |
| **Clocks** | 83.33 MHz (AXI/compute), 25 MHz (VGA), 166.67 MHz (MIG sys_clk), 200 MHz (MIG clk_ref) |
| **Interconnect** | AXI4 (burst read, write), AXI Interconnect |
| **Xilinx IPs** | MIG 7 Series, Clocking Wizard, AXI Interconnect, Processor System Reset |

---

## 🏗 Architecture

The system is organized as a Vivado Block Design connecting custom RTL modules:
<p align="center">
  <img src="docs/design_mandelbrot.jpg" alt="Vivado Block Design" width="850"/>
</p>

### Data Flow

<p align="center">
  <img src="docs/manddrawio.png" alt="System Data Flow" width="850"/>
</p>



### Custom RTL Modules

| Module | Clock | Description |
|---|---|---|
| `mandelbrot_iter` | 83.33 MHz | Q4.28 fixed-point iterator, 2-cycle pipeline latency |
| `mandelbrot_sequencer` | 83.33 MHz | Drives iterator until escape or MAX_ITER=255 |
| `mandelbrot_master` | 83.33 MHz | Scans 640×480, writes each pixel to DDR3 via AXI4 |
| `mandelbrot_master_wrapper` | 83.33 MHz | VHDL-93 wrapper for Vivado BD compatibility |
| `vga_axi_reader` | 83.33 MHz | Reads DDR3 via AXI4 burst, writes to line BRAM |
| `vga_axi_reader_wrapper` | 83.33 MHz | VHDL-93 wrapper for Vivado BD compatibility |
| `line_buffer_bram` | dual-clock | 1280-byte ping-pong buffer, inferred as RAMB18 |
| `mandelbrot_palette` | combinatorial | Iteration count → RGB444 color LUT |
| `vga_controller` | 25 MHz | VGA timing, sync signals, ping-pong management |

---

## 🚦 Quick Start

### Prerequisites
- Vivado 2023.1
- Digilent Arty A7-35T 

### Steps

1. **Clone the repository**

2. **Open Vivado 2023.1 → Tcl Console**

3. **Recreate the project**
```tcl
   cd [path/to/mandelbrot-vga]
   source scripts/create_project.tcl
```

4. **Generate Bitstream**
   - Flow Navigator → **Generate Bitstream**
   - Synthesis and Implementation run automatically

5. **Program the board**
   - Open Hardware Manager → Program Device
   - Select the generated `.bit` file

6. **Run**
   - Connect a VGA monitor
   - Press **BTN0** to reset the board
   - Press **BTN1** (`start_image`) to launch computation
   - When the **done LED** lights up, the Mandelbrot set is displayed on the monitor

---

## 🧪 Testbenches

| Testbench | Description |
|---|---|
| `tb_mandelbrot_iter` | Validates Q4.28 fixed-point arithmetic — 5 test cases with assertions |
| `tb_mandelbrot_sequencer` | Validates escape and MAX\_ITER behavior |
| `tb_mandelbrot_master` | Validates AXI4 write FSM — synchronous and desynchronized handshake modes |
| `tb_vga_axi_reader` | Validates AXI4 burst read and BRAM write — 2 ping-pong modes |
| `tb_mandelbrot_top` | Full system simulation with Micron DDR3 behavioral model |

> ⚠️ **`tb_mandelbrot_top` note**: This testbench simulates the complete system including DDR3 calibration and full image computation. DDR3 calibration alone takes approximately **123 µs** of simulated time — observing `done_image_o` would require simulating the entire 640×480 pixel computation which is not practical due to CPU simulation time. However the testbench is provided for anyone who wants to observe the DDR3 initialization sequence and early system behavior. Set simulation runtime to at least **2 ms** in Vivado Simulation Settings to observe `init_calib_complete`.

---

## 📂 Repository Structure
```text
mandelbrot-vga/
├── README.md
├── scripts/
│   ├── create_project.tcl          # One-command project restoration
│   └── mandebrot_vga_top.tcl       # Block design recreation (MIG config embedded)
├── hdl/
│   ├── mandelbrot_iter/            # Q4.28 Mandelbrot iterator
│   ├── mandelbrot_sequencer/       # Per-pixel iteration controller
│   ├── mandelbrot_master/          # AXI4 write master + VHDL-93 wrapper
│   ├── vga_controller/             # VGA timing + ping-pong
│   ├── vga_axi_reader/             # AXI4 burst read + VHDL-93 wrapper
│   ├── line_buffer_bram/           # Dual-clock ping-pong BRAM
│   └── mandelbrot_palette/         # RGB444 color LUT
├── sim/
│   ├── tb_mandelbrot_iter.vhd
│   ├── tb_mandelbrot_sequencer.vhd
│   ├── tb_mandelbrot_master.vhd
│   ├── tb_vga_axi_reader.vhd
│   ├── tb_mandelbrot_top.vhd       # Full system + DDR3 model
│   ├── ddr3_model.sv               # Micron DDR3 behavioral model
│   ├── ddr3_model_parameters.vh
│   └── wiredly.v
├── constraints/
│   └── arty_ddr3.xdc               # Pin mapping + timing constraints
├── ip/
│   └── clk_wiz_0/
│       └── clk_wiz_0.xci           # Clocking Wizard 
└── docs/
    ├── result.jpg                   # VGA output photo
    └── block_design.png             # Vivado Block Design capture
```

---

## 👤 Author

**Johan EL HAJJ DIB** — [LinkedIn](https://www.linkedin.com/in/)