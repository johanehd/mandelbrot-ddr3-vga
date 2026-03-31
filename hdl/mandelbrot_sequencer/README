# mandelbrot_sequencer

## Description

Controls the iterative computation of the Mandelbrot sequence for a single pixel.
It instantiates `mandelbrot_iter` and drives it repeatedly until either the
escape condition is met or the maximum number of iterations is reached.
When complete, it outputs the iteration count and pulses `pixel_ready_o` for
one clock cycle to signal the result is valid.

## Functional Specification

### Operation

For each pixel, the Mandelbrot sequence is computed as:
```
z_0     = 0
z_n+1   = z_n² + c      with c = cr + i·ci (fixed per pixel)

Stop when:
  - |z|² > 4  (escaped)      → iteration count = current count
  - count = 255 (MAX_ITER)   → pixel belongs to the set
```

The caller provides `c` via `cr_i` and `ci_i`, asserts `start_i` for one
clock cycle, then waits for `pixel_ready_o` to pulse before reading
`iter_count_o`.

### FSM

<p align="center">
  <img src="fsm_seq_0.svg" alt="FSM diagram"/>
</p>

### States

| State | Description | Exit condition |
|---|---|---|
| `S_IDLE` | Waits for `start_i`. Holds `pixel_ready_o` low, resets z and counter to 0 | `start_i = '1'` → `S_WAIT_PIPE` |
| `S_WAIT_PIPE` | Waits 2 cycles for `mandelbrot_iter` pipeline latency | After 2 cycles → `S_COMPUTE` |
| `S_COMPUTE` | Reads iterator output, updates z | `escaped` or `count = 255` → `S_FINISH`, else → `S_WAIT_PIPE` |
| `S_FINISH` | Pulses `pixel_ready_o = '1'` for 1 cycle | Unconditional → `S_IDLE` |

### Iteration count

`iter_count_o` represents the number of **completed** iterations before
escape or MAX_ITER. It is valid only when `pixel_ready_o = '1'`.

| Value | Meaning |
|---|---|
| 0–254 | Pixel escaped after N iterations |
| 255 | Pixel did not escape (belongs to Mandelbrot set) |

## Ports

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | System clock (83.33 MHz) |
| `rst` | in | 1 | Synchronous active-high reset |
| `start_i` | in | 1 | Pulse high for 1 cycle to start computation |
| `cr_i` | in | 32 | Real part of c, pixel coordinate (Q4.28) |
| `ci_i` | in | 32 | Imaginary part of c, pixel coordinate (Q4.28) |
| `pixel_ready_o` | out | 1 | Pulses high for 1 cycle when result is valid |
| `iter_count_o` | out | 8 | Number of iterations before escape or MAX_ITER |

## Timing

## Timing

```
Cycle N   : start_i asserted
Cycle N+1 : S_WAIT_PIPE begins (delay_cnt = 0)
Cycle N+2 : delay_cnt = 1
Cycle N+3 : delay_cnt = 2
Cycle N+4 : S_COMPUTE — reads iterator output, updates z
Cycle N+5 : S_WAIT_PIPE (next iteration) or S_FINISH if escaped
...
Cycle X   : S_FINISH — pixel_ready_o = '1' for 1 cycle
```

## Constants

| Constant | Value | Description |
|---|---|---|
| `MAX_ITER` | 255 (0xFF) | Maximum number of iterations per pixel |

## Dependencies

| Module | Description |
|---|---|
| `mandelbrot_iter` | Single iteration engine (Q4.28, 2-cycle latency) |

| File | Description |
|---|---|
| `mandelbrot_sequencer.vhd` | RTL implementation |
| `tb_mandelbrot_sequencer.vhd` | Testbench — TC01 : fast escape, diverging point/ TC02 : stable point, reaches MAX_ITER = 255 |