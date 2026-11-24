# Track 15 "End to End" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| B4 T02 noise-EVM formula, full occupancy K=624, Nfft=1024, SNR 25 dB | 4.39 % | — | yes | 100·sqrt(624/(1024·316.2)); the script uses the measured average occupancy |

The all-off bit invariant and the impairment-cascade EVM triangle are run results. The rss combination itself is the same hypot() identity checked under Track 13.
