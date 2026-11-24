# Track 13 "Signals from Orbit" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| GEO 2d/c ms | 238.738494215 | 238.74 | yes | rounded to 0.01 ms in the notes |
| GEO 4d/c ms | 477.47698843 | 477.48 | yes | rounded to 0.01 ms in the notes |
| LEO 2d/c ms | 4.00276914238 | 4.003 | yes |  |
| LEO 4d/c ms | 8.00553828476 | 8.006 | yes | rounded to 0.001 ms in the notes |
| LEO Doppler max kHz | 50.0346142797 | 50.035 | yes |  |
| GEO processes for 1 ms slot | 478 | 478 | yes |  |
| GEO worst-case 4d/c at 10° (d = 40581 km) ms | 541.45 | 541 | yes | reconciles notes A1/A3 with code's 477 |
| B3 DC probe row for 52 RB | 313 | 0 Hz | yes | row 1 = −312·15 kHz = −4.68 MHz (old probe) |
| B3 lag-1 phase step at 20 kHz, fs 15.36 MHz | 0.008181 rad | < π | yes | no phase wrap |
