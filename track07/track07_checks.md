# Track 07 "Learn the Channel" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| B1 coherence bandwidth, TDL-C 300 ns | ≈ 1/(5·300 ns) ≈ 0.67 MHz | ≪ 9.36 MHz band | yes | rule of thumb; why B3 now sees fades |
| B1 Try DMRSAdditionalPosition 0/1/2 (type 1, 12-symbol PDSCH) | 1/2/3 DM-RS symbols | count scales | yes | 6 RE/PRB per DM-RS symbol (type 1); not run |

No definite pure-math numerical claim beyond the LS/MMSE discussion; residual EVMs are run results.
