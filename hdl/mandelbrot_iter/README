# mandelbrot_iter

## Description

Computes one iteration of the Mandelbrot sequence using Q4.28 fixed-point
arithmetic on 32-bit signed integers, running at 83.33 MHz on Artix-7.

## Background

The Mandelbrot set is defined by the recurrence:
```
z_n+1 = z_n² + c
```

Where:
- **c = cr + i*ci** is a **fixed** complex number representing the pixel
  coordinates in the complex plane. It does not change across iterations
  of the same pixel.
- **z = x + i*y** is a **variable** complex number initialized to 0 at
  the start of each pixel. It evolves at every iteration.

A pixel belongs to the Mandelbrot set if z never diverges. In practice,
divergence is detected when |z|² > 4, which avoids computing a square root.

## Functional Specification

### Implemented Formula

Expanding z² + c with z = x + i·y and c = cr + i·ci:
```
z² = (x + i·y)² = (x² - y²) + i·(2·x·y)     

z² + c = (x² - y² + cr) + i·(2·x·y + ci)
```

This gives:
```
x_next  = x² - y² + cr        (new real part)
y_next  = 2·x·y + ci          (new imaginary part)
escaped = 1 if x² + y² > 4   (divergence check on current z, not z_next)
```

### Fixed-Point Format

- Format: Q4.28 signed on 32 bits
- 4 integer bits (including sign) + 28 fractional bits
- Representable range: [-8.0 ; +7.999999996]
- Resolution: 2⁻²⁸ ≈ 3.7 × 10⁻⁹

## Ports

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | System clock (83.33 MHz) |
| `rst` | in | 1 | Synchronous active-high reset |
| `x_i` | in | 32 | Real part of current z  |
| `y_i` | in | 32 | Imaginary part of current z  |
| `cr_i` | in | 32 | Real part of c — pixel coordinate, constant per pixel  |
| `ci_i` | in | 32 | Imaginary part of c — pixel coordinate, constant per pixel  |
| `x_next_o` | out | 32 | Real part of z_next  |
| `y_next_o` | out | 32 | Imaginary part of z_next |
| `escaped_o` | out | 1 | '1' if current \|z\|² > 4 |

## Timing

```
Cycle N   : x_i, y_i, cr_i, ci_i presented at input
Cycle N+1 : x², y², xy, |z|² computed and registered
Cycle N+2 : x_next_o, y_next_o, escaped_o valid
```

## Generics

| Generic | Default | Description |
|---|---|---|
| `F_BITS` | 28 | Number of fractional bits |

## Implementation Notes

- 32×32 multiplications produce 64-bit intermediate results
- Right shift by `F_BITS` brings results back to Q4.28 format
- Escape threshold 4 is represented in Q8.56 format (F_BITS × 2)
- A combinational architecture was discarded: critical path of 14.2 ns
  exceeds the 12 ns clock period → negative slack of −2.2 ns

## Files

| File | Description |
|---|---|
| `mandelbrot_iter.vhd` | RTL implementation |
| `tb_mandelbrot_iter.vhd` | Testbench (5 test cases) |