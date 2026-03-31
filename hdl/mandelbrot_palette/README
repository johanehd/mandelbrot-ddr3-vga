# mandelbrot_palette

## Description

Pure combinatorial lookup table that maps a Mandelbrot iteration count
(0–255) to a 12-bit RGB444 color for VGA display.

## Color Mapping

| iter_count | Color | Description |
|---|---|---|
| 255 | `0x000` | Black — point belongs to Mandelbrot set |
| 0–15 | `0x001` → `0x00F` | Dark blue gradient |
| 16–71 | `0x11F` → `0xEEF` | Blue to white gradient |
| 72–89 | `0xFFF` | White |
| 90–254 | `0xFFE` → `0xFF7` | White to yellow gradient |

## Ports

| Port | Direction | Width | Description |
|---|---|---|---|
| `iter_count_i` | in | 8 | Iteration count from sequencer (0–255) |
| `rgb_out` | out | 12 | RGB444 color output |

## Implementation Notes

- Purely combinatorial — no clock, no reset, no latency
- Synthesizes as a LUT-based ROM
- `rgb_out` is valid within the same cycle as `iter_count_i`

## Files

| File | Description |
|---|---|
| `mandelbrot_palette.vhd` | RTL implementation |