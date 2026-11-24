# Track 02 "Copy the Tail" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| 52 RB default Nfft | 1024 | 1024 | yes |  |
| K=12*52 | 624 | 624 | yes |  |
| fs = 1024*15e3 | 15360000 | 15360000 | yes |  |
| frame samples | 153600 | 153600 | yes |  |
| CP ordinary/long at Nfft=1024 | (72, 80) | (72, 80) | yes |  |
| EVM at 25 dB time-domain SNR % | 4.38977556279 | 4.39 | yes |  |
| CFO eps=0.05 EVM after CPE % | 9.0634041689 | 9.06 | yes |  |
| B2 Try: lastEcho = 80 vs CP lengths | normal CP 72, long CP 80 samples @ 15.36 MHz | 80 <= 80 long; 80 > 72 normal | yes | long-CP symbols clean, normal-CP symbols break; assert only when lastEcho > 80 |
| B2 long-CP symbols per frame (15 kHz) | 20 of 140 | symbols 0 and 7 of each 1 ms subframe | yes | H learned from symbol 0 (long CP) |
