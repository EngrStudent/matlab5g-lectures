# Track 10 "Sound It Out" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| B4 raw residual (separate Tx/Rx chains) | 0.2036 | > 1e-3 | yes | numpy, same toy numbers as the script |
| B4 gNB-side-only calibration residual | 0.6295 | > 0 | yes | shows the one-side mistake |
| B4 both-ends calibration residual | 2.3e-16 | < 1e-12 | yes | |
| B4 old model (same gains both ends) | ~7e-17 | — | n/a | why the v1 beat could not break reciprocity (DFMEA F5) |
| B2 Try row 1 density three vs row 2 density one | 3 vs 1 RE/RB/symbol | ×3 | yes | 38.211 Table 7.4.1.5.3-1 rows 1-2 (not run) |

The toy calibration residual is an algebraic identity (asserted in the demo). Reciprocity residuals from nrTDLChannel are run results.
