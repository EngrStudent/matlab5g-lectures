# Track 11 "One in Ten" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| 100 errors at BLER 0.1 | 1000 | 1000 | yes |  |
| 100 errors at BLER 1e-3 | 100000 | 100000 | yes |  |
| Residual ≤ first-tx BLER (per block) | always | logical | yes | a block that fails after HARQ also failed RV 0 |
| Throughput denominator | slots used (Σ attempts) | ≥ nSlots | yes | was nSlots (DFMEA F5a) |
