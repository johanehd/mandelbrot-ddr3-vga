# mandelbrot_master

## Description

Top-level controller for the Mandelbrot image computation. It iterates over
all 640×480 pixels, computes the Mandelbrot iteration count for each via
`mandelbrot_sequencer`, and writes the result to DDR3 memory over AXI4-Lite.
When all pixels are processed, it asserts `done_image_o` to signal that the
image is ready to be displayed.

## Functional Specification

### Operation
```
For each pixel (x, y) in [0..639] × [0..479]:
  1. Convert (x, y) to complex coordinates (cr, ci)
  2. Send cr, ci to mandelbrot_sequencer via seq_start_o
  3. Wait for seq_ready_i
  4. Write iter_count to DDR3 at address: DDR3_BASE + (y*640 + x) * 4
  5. Move to next pixel
When all pixels done → assert done_image_o for 1 cycle
```

### Complex Plane Mapping

The 640×480 pixel grid is mapped to the complex plane as follows:

| Parameter | Value (Q4.28) | Decimal |
|---|---|---|
| X_START (cr at x=0) | 0xE0000000 | -2.0 |
| Y_START (ci at y=0) | 0xECCCCD00 | -1.2 |
| X_STEP (per pixel) | 0x00134000 | ≈ 0.00469 |
| Y_STEP (per pixel) | 0x00147AE1 | ≈ 0.00500 |

### Memory Layout

Each pixel is stored as a 32-bit word in DDR3:
```
Address = DDR3_BASE + ((y × 640) + x) × 4
Data    = 0x000000XX  where XX = iter_count (0–255)
```

- **DDR3_BASE** : 0x80010000
- **Total size** : 640 × 480 × 4 = 1,228,800 bytes ≈ 1.17 MB

### FSM

| State | Description | Exit condition |
|---|---|---|
| `S_IDLE` | Waits for `start_image_i`. Resets pixel coordinates | `start_image_i = '1'` → `S_INIT_PIXEL` |
| `S_INIT_PIXEL` | Pulses `seq_start_o` for 1 cycle | Unconditional → `S_WAIT_PIXEL` |
| `S_WAIT_PIXEL` | Waits for `seq_ready_i`. Computes DDR3 address and write data | `seq_ready_i = '1'` → `S_AXI_WRITE` |
| `S_AXI_WRITE` | Issues AXI write address and data. Handles simultaneous AW/W handshakes | Both AW and W accepted → `S_AXI_WAIT_RESP` |
| `S_AXI_WAIT_RESP` | Waits for AXI write response | `bvalid = '1'` and `bresp = OKAY` → `S_NEXT_PIXEL`, else → `S_ERROR` |
| `S_NEXT_PIXEL` | Increments pixel coordinates and complex plane position | Last pixel → `S_FINISH`, else → `S_INIT_PIXEL` |
| `S_FINISH` | Asserts `done_image_o`. Clears `busy_o` | Unconditional → `S_IDLE` |
| `S_ERROR` | Asserts `error_out`. Latches permanently until reset | Reset only |

<p align="center">
  <img src="my_fsm_1_0.svg" alt="FSM diagram"/>
</p>

## Ports

### Control

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | System clock (83.33 MHz) |
| `rst` | in | 1 | Synchronous active-high reset |
| `start_image_i` | in | 1 | Pulse high for 1 cycle to start image computation |
| `busy_o` | out | 1 | High during image computation |
| `done_image_o` | out | 1 | Pulses high for 1 cycle when image is complete |
| `error_out` | out | 1 | High on AXI write error (latches until reset) |

### Sequencer Interface

| Port | Direction | Width | Description |
|---|---|---|---|
| `seq_start_o` | out | 1 | Pulses high for 1 cycle to start pixel computation |
| `seq_cr_o` | out | 32 | Real part of c for current pixel (Q4.28) |
| `seq_ci_o` | out | 32 | Imaginary part of c for current pixel (Q4.28) |
| `seq_ready_i` | in | 1 | Pulses high when sequencer result is valid |
| `seq_iter_i` | in | 8 | Iteration count from sequencer |

### AXI4-Lite Master

| Port | Direction | Width | Description |
|---|---|---|---|
| `m_axi_awaddr` | out | 32 | Write address |
| `m_axi_awvalid` | out | 1 | Write address valid |
| `m_axi_awready` | in | 1 | Write address ready |
| `m_axi_wdata` | out | 32 | Write data (0x000000XX) |
| `m_axi_wstrb` | out | 4 | Write strobe (always 0xF) |
| `m_axi_wvalid` | out | 1 | Write data valid |
| `m_axi_wready` | in | 1 | Write data ready |
| `m_axi_bvalid` | in | 1 | Write response valid |
| `m_axi_bready` | out | 1 | Write response ready |
| `m_axi_bresp` | in | 2 | Write response (00 = OKAY) |

> The AXI read channel is present in the port list but permanently tied off
> (arvalid = '0', rready = '0'). It is required by Vivado Block Design to
> allow automatic AXI interface detection and connection to the AXI
> Interconnect. No read transactions are ever issued by this module.

## Timing

- **Clock frequency** : 83.33 MHz 
- **Latency per pixel** : sequencer latency + AXI write latency
- **Total image time** : 640 × 480 × (sequencer + AXI) cycles

## Implementation Notes

- y × 640 is computed as shift_left(y, 9) + shift_left(y, 7) to avoid
  a hardware multiplier (512 + 128 = 640)
- AW and W channels are issued simultaneously for minimum write latency
- The AXI read channel is fully tied off (arvalid = '0', rready = '0')

## Wrapper

`mandelbrot_master_wrapper` is a thin VHDL-93 compatible wrapper around
`mandelbrot_master`. It converts `signed`/`unsigned` port types to
`std_logic_vector` for compatibility with Vivado Block Design IP integration.

## Dependencies

| Module | Description |
|---|---|
| `mandelbrot_sequencer` | Computes iteration count for one pixel |

## Files

| File | Description |
|---|---|
| `mandelbrot_master.vhd` | RTL implementation |
| `mandelbrot_master_wrapper.vhd` | VHDL-93 wrapper for Vivado BD integration |
| `tb_mandelbrot_master.vhd` | Testbench |