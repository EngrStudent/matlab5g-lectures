# Track 05 "Say It Again" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| CRC 16 if A<=3824 else 24: A=3824 | 16 | 16 | yes |  |
| CRC 16 if A<=3824 else 24: A=3825 | 24 | 24 | yes |  |
| B1 TBS static estimate (QPSK, 24 PRB, 132 RE/PRB, R=0.48) | N_info=3041.3 -> N_info'=3040 -> 3104 | 38.214 5.1.3.2 table (N_info<=3824) | estimate | compare with B1 print in R2024b |
| B5 NREPerPRB for AdditionalPosition 0..3 (symbols 2..13, type 1, 2 CDM groups) | 132/120/108/96 | 38.211 Table 7.4.1.1.2-3, l_d=14 | estimate | DM-RS at {2},{2,11},{2,7,11},{2,5,8,11} |
| B5 TBS for AdditionalPosition 0..3 | 3104/2792/2472/2216 | same table path | estimate | printed inside the B5 loop now |
| B2 Try: MCS 9 vs 10 in QAM64Table | QPSK R=679/1024 vs 16QAM R=340/1024 | 38.214 Table 5.1.3.1-1 | yes | Qm*R: 1.326 vs 1.328, so TBS barely moves |
