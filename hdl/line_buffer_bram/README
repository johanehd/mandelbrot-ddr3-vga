# line_buffer_bram

## Description

Dual-port BRAM acting as a ping-pong line buffer between the AXI reader
(83.33 MHz write domain) and the VGA controller (25 MHz read domain).
It holds two line buffers of 640 bytes each, for a total of 1280 bytes.
No reset is needed — the memory is initialized to zero at power-on by the
FPGA bitstream.

## Functional Specification

### Memory Layout
```
Address   0 –  639 : Buffer 0 — 640 pixels
Address 640 – 1279 : Buffer 1 — 640 pixels
```

### Ping-Pong Operation

Port A (write) and Port B (read) always access opposite buffers, controlled
externally by `ping_pong` from `vga_controller`:

| ping_pong | VGA reads (Port B) | AXI writes (Port A) |
|---|---|---|
| 0 | Buffer 0 (0–639) | Buffer 1 (640–1279) |
| 1 | Buffer 1 (640–1279) | Buffer 0 (0–639) |

### Clock Domains

Port A and Port B run on independent clocks with no shared reset. This is
a standard Xilinx true dual-clock BRAM inference pattern. Xilinx guarantees
correct operation as long as the two ports never access the same address
simultaneously which is ensured by the ping-pong scheme.

### BRAM Inference

The RTL is written to match Xilinx BRAM inference templates:
- Port A : synchronous write only (no read)
- Port B : synchronous read only (no write)



## Ports

| Port | Direction | Width | Clock domain | Description |
|---|---|---|---|---|
| `clk_a` | in | 1 | 83.33 MHz | Write port clock (AXI reader) |
| `we_a_i` | in | 1 | clk_a | Write enable |
| `addr_a_i` | in | 11 | clk_a | Write address (0–1279) |
| `din_a_i` | in | 8 | clk_a | Write data (iteration count) |
| `clk_b` | in | 1 | 25 MHz | Read port clock (VGA controller) |
| `addr_b_i` | in | 11 | clk_b | Read address (0–1279) |
| `dout_b_o` | out | 8 | clk_b | Read data, valid 1 cycle after addr_b_i |


## Implementation Notes

- Read latency of 1 cycle is compensated by the `h_cnt + 1` offset in
  `vga_controller`
- **No reset** memory initialized to 0x00 at power-on

## Files

| File | Description |
|---|---|
| `line_buffer_bram.vhd` | RTL implementation |