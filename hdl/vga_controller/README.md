# vga_controller

## Description

Generates VGA timing signals for a 640×480@60Hz display. It drives the
horizontal and vertical sync pulses, computes the active display zone,
generates pixel coordinates for other modules, manages the ping-pong buffer
selection for the line buffer BRAM, and outputs RGB444 pixel data to the
VGA connector.

## Functional Specification

### VGA Timing — 640×480@60Hz

The scan is divided into 4 horizontal zones repeated for each line, and
4 vertical zones repeated for each frame:
```
Horizontal (per line, 800 cycles at 25 MHz = 32 µs):
  ├── VISIBLE  : 640 cycles  h_cnt [0,   639]  pixels displayed
  ├── FP       :  16 cycles  h_cnt [640, 655]  front porch (black)
  ├── SYNC     :  96 cycles  h_cnt [656, 751]  hs = '0'
  └── BP       :  48 cycles  h_cnt [752, 799]  back porch (black)

Vertical (per frame, 525 lines):
  ├── VISIBLE  : 480 lines   v_cnt [0,   479]  lines displayed
  ├── FP       :  10 lines   v_cnt [480, 489]  front porch
  ├── SYNC     :   2 lines   v_cnt [490, 491]  vs = '0'
  └── BP       :  33 lines   v_cnt [492, 524]  back porch
```

Frame rate: 25 MHz / (800 × 525) ≈ 59.52 Hz

### Ping-Pong

`ping_pong_reg` toggles at the end of each visible line (h_cnt = 799,
v_cnt < 480). It indicates which half of the line buffer BRAM the VGA
controller is currently reading:

| ping_pong_reg | VGA reads | AXI reader writes |
|---|---|---|
| 0 | Buffer 0 (addresses 0–639) | Buffer 1 (addresses 640–1279) |
| 1 | Buffer 1 (addresses 640–1279) | Buffer 0 (addresses 0–639) |

### BRAM Read Address

The BRAM read address is computed one cycle ahead (h_cnt + 1) to compensate
for the 1-cycle synchronous read latency of the BRAM:
```
ping_pong_reg = 0 : bram_rd_addr = h_cnt + 1          (range 1–640)
ping_pong_reg = 1 : bram_rd_addr = 640 + h_cnt + 1    (range 641–1280)
```

### RGB Output

`pixel_data_i` is a 12-bit RGB444 value split as follows:
```
pixel_data_i[11:8] → vga_r_o
pixel_data_i[7:4]  → vga_g_o
pixel_data_i[3:0]  → vga_b_o
```

All RGB outputs are forced to 0 outside the active zone.

## Ports

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk_25` | in | 1 | VGA pixel clock (25 MHz) |
| `rst` | in | 1 | Asynchronous active-high reset |
| `pixel_data_i` | in | 12 | RGB444 pixel data from BRAM via palette |
| `pixel_x_o` | out | 10 | Current pixel x coordinate (0 in blanking) |
| `pixel_y_o` | out | 10 | Current pixel y coordinate (0 in blanking) |
| `zone_on_o` | out | 1 | High when in visible area |
| `ping_pong_o` | out | 1 | Current ping-pong buffer selector |
| `bram_rd_addr_o` | out | 11 | BRAM read address (1 cycle ahead) |
| `vga_hs_o` | out | 1 | Horizontal sync (active low) |
| `vga_vs_o` | out | 1 | Vertical sync (active low) |
| `vga_r_o` | out | 4 | Red channel (4 bits) |
| `vga_g_o` | out | 4 | Green channel (4 bits) |
| `vga_b_o` | out | 4 | Blue channel (4 bits) |

## Timing

- **Clock frequency**: 25 MHz
- **Resolution**: 640 × 480
- **Refresh rate**: ≈ 59.52 Hz
- **Reset**: asynchronous active-high

## Implementation Notes

- `bram_rd_addr_o` is registered (synchronous process) with a +1 offset
  to compensate for BRAM synchronous read latency
- `vga_hs_o` and `vga_vs_o` are combinatorial, no pipeline delay
- `ping_pong_reg` toggles only during visible lines (v_cnt < 480) to avoid
  spurious toggles during vertical blanking

## Files

| File | Description |
|---|---|
| `vga_controller.vhd` | RTL implementation |
