# vga_axi_reader

## Description

Reads pixel data from DDR3 memory over AXI4 burst and writes it into the
line buffer BRAM for VGA display. It runs in the AXI clock domain (83.33 MHz)
and synchronizes incoming VGA signals from the VGA clock domain (25 MHz) using
a double flip-flop synchronizer. It implements a ping-pong buffering scheme
to avoid read/write conflicts on the BRAM between the VGA controller and this
module.

## Functional Specification

### Operation
```
For each visible VGA line N being displayed:
  1. Detect that VGA is displaying line N (vga_active_s1 = '1')
  2. Compute next_line = vga_y_s1 + 1
  3. If next_line not already loaded → launch 5 AXI4 bursts of 128 beats
  4. Write 640 pixels into BRAM at the buffer opposite to the one VGA is reading
  5. Return to S_IDLE and wait for next line
```

### Burst Strategy

One full line (640 pixels) is loaded using 5 consecutive AXI4 bursts of
128 beats each (128 × 4 bytes = 512 bytes per burst):

| Burst | Pixels | DDR3 offset from line_base |
|---|---|---|
| 0 | 0–127 | 0 |
| 1 | 128–255 | 128 × 4 = 512 |
| 2 | 256–383 | 256 × 4 = 1024 |
| 3 | 384–511 | 384 × 4 = 1536 |
| 4 | 512–639 | 512 × 4 = 2048 |

Each DDR3 word is 32 bits. Only the least significant byte is used
(iteration count 0–255). The upper 3 bytes are discarded.

### Ping-Pong Buffering

The BRAM holds two line buffers of 640 bytes each:
```
Buffer 0 : BRAM addresses   0 – 639
Buffer 1 : BRAM addresses 640 – 1279
```

`ping_pong_i` comes from `vga_controller` and indicates which buffer the
VGA is currently reading. This module always writes to the opposite buffer:

| ping_pong_s1 | VGA reads | AXI writer writes |
|---|---|---|
| 0 | Buffer 0 (0–639) | Buffer 1 (640–1279) |
| 1 | Buffer 1 (640–1279) | Buffer 0 (0–639) |

`ping_pong_i` is synchronized to the AXI clock domain via a double FF
synchronizer before use.

### CDC — Clock Domain Crossing

`vga_y_i`, `vga_active_i` and `ping_pong_i` all originate from the VGA
clock domain (25 MHz). They are synchronized to the AXI clock domain
(83.33 MHz) using a 2-stage flip-flop synchronizer:
```
signal_i → [FF clk_i] → signal_s0 → [FF clk_i] → signal_s1 (safe to use)
```

### FSM

| State | Description | Exit condition |
|---|---|---|
| `S_IDLE` | Waits for conditions to load next line | All conditions met → `S_SEND_ADDR` |
| `S_SEND_ADDR` | Issues AXI read address, waits for arready handshake | `arready = '1'` → `S_RECV_BURST` |
| `S_RECV_BURST` | Receives burst data, writes to BRAM. Launches next burst or ends | `rlast` + `burst_num = 4` → `S_IDLE`, else → `S_SEND_ADDR` |
| `S_ERROR` | AXI read error. Latches permanently until reset | Reset only |

### S_IDLE Launch Conditions

A new burst is launched only when all of the following are true:

| Condition | Description |
|---|---|
| `image_ready_i = '1'` | DDR3 image has been fully written by mandelbrot_master |
| `vga_active_s1 = '1'` | VGA is currently in the visible area |
| `next_line < 480` | Next line is within the valid frame |
| `next_line /= last_line` | Line has not already been loaded |
| `loading = '0'` | No burst currently in progress |

### Memory Addressing
```
line_base = DDR3_BASE + (next_line × 640 × 4)
DDR3_BASE = 0x80010000
```

## Ports

### Control & VGA Interface

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk_i` | in | 1 | AXI system clock (83.33 MHz) |
| `rst_i` | in | 1 | Asynchronous active-high reset |
| `vga_x_i` | in | 10 | Current VGA horizontal pixel (25 MHz domain) |
| `vga_y_i` | in | 10 | Current VGA vertical line (25 MHz domain) |
| `vga_active_i` | in | 1 | VGA active zone flag (25 MHz domain) |
| `ping_pong_i` | in | 1 | Current VGA buffer selector (25 MHz domain) |
| `image_ready_i` | in | 1 | High when DDR3 image is fully written |

### BRAM Interface

| Port | Direction | Width | Description |
|---|---|---|---|
| `bram_we_o` | out | 1 | BRAM write enable |
| `bram_addr_o` | out | 11 | BRAM write address (0–1279) |
| `bram_din_o` | out | 8 | BRAM write data (iteration count) |

### AXI4 Master Read

| Port | Direction | Width | Description |
|---|---|---|---|
| `m_axi_araddr` | out | 32 | Read address |
| `m_axi_arvalid` | out | 1 | Read address valid |
| `m_axi_arready` | in | 1 | Read address ready |
| `m_axi_arlen` | out | 8 | Burst length (fixed: 127 = 128 beats) |
| `m_axi_arsize` | out | 3 | Beat size (fixed: 010 = 4 bytes) |
| `m_axi_arburst` | out | 2 | Burst type (fixed: 01 = INCR) |
| `m_axi_rdata` | in | 32 | Read data |
| `m_axi_rresp` | in | 2 | Read response (00 = OKAY) |
| `m_axi_rvalid` | in | 1 | Read data valid |
| `m_axi_rready` | out | 1 | Read data ready |
| `m_axi_rlast` | in | 1 | Last beat of burst |

> The AXI write channel is present in the port list but permanently tied off
> (awvalid = '0', wvalid = '0', bready = '0'). It is required by Vivado
> Block Design to allow automatic AXI interface detection and connection to
> the AXI Interconnect. No write transactions are ever issued by this module.

## Timing

- **Latency per line**: 5 × (1 AXI address cycle + 128 data cycles) = ~650 cycles minimum

## Implementation Notes

- `vga_x_i` is present in the port list but not used internally, line
  loading is triggered by `vga_y_i` only
- The ping-pong value is sampled from `ping_pong_s1` at each beat during


## Files

| File | Description |
|---|---|
| `vga_axi_reader.vhd` | RTL implementation |
| `vga_axi_reader_wrapper.vhd` | VHDL-93 wrapper for Vivado BD integration |
| `tb_vga_axi_reader.vhd` | Testbench |