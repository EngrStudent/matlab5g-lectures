# Track 06 "Taps in Time" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| lambda at 3 GHz m | 0.0999308193333 | 0.1 | yes |  |
| f_D at 30 m/s, 3 GHz Hz | 300.207685678 | 300 | yes |  |
| 5 Hz default equivalent v m/s | 0.499654096667 | 0.5 | yes |  |
| T_c = 0.423/f_D at 300 Hz | 1.41 ms (≈ 19.7 symbols at 15 kHz) | ~20 symbols | yes | "stale a symbol later" was wrong |
| T_c at 5 Hz | 84.6 ms | — | yes | |
| Reuse gap sym 2→13 | 0.786 ms; Jakes ρ = J0(2π·300·0.786e-3) ≈ 0.52 | large error at 300 Hz | yes | single-draw value will vary |
| TDL-A first normalized delay | 0 | 0 | yes | why v1 ratio assert divided by zero (38.901 Table 7.7.2-1) |
