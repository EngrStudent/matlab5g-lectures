# Track 04 "Every Check Agrees" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| BG rule A=200 R=0.5 | 2 | 2 | yes |  |
| BG rule A=3000 R=0.6 | 2 | 2 | yes |  |
| BG rule A=3000 R=0.8 | 1 | 1 | yes |  |
| BG rule A=8000 R=0.2 | 2 | 2 | yes |  |
| BG rule A=8000 R=0.5 | 1 | 1 | yes |  |
| BG1 Zc=384 K,N | (8448, 25344) | (8448, 25344) | yes |  |
| BG2 Zc=384 K,N | (3840, 19200) | (3840, 19200) | yes |  |
| B4 single-bit flip vs CRC16 | detected | CRC err ≠ 0 | yes | Any CRC with ≥2 terms detects every 1-bit error (algebraic, not run) |
| B3 BG2 A=200 filler present | K=10·Zc > 216 | fillers exist | yes | Why B3 scores only non-filler bits (DFMEA F6) |
