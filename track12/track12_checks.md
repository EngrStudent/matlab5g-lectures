# Track 12 "How Far" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| ranges m | (250, 335.41, 403.11) | (250, 335.41, 403.11) | yes | rounded to 2 decimals |
| d1 exact | 250 | 250 | yes |  |
| d2 exact | 335.410196625 | 335.410196625 | yes |  |
| d3 exact | 403.112887415 | 403.112887415 | yes |  |
| c/fs m (c=299792458) | 9.75886907552 | 9.758868 | yes | plan used 2.998e8 -> 9.76 m |
| tau ns | (833.9, 1118.8, 1344.6) | (833.9, 1118.8, 1344.6) | yes | rounded to 0.1 ns |
| samples | (25.62, 34.37, 41.31) | (25.62, 34.37, 41.31) | yes |  |
| d2-d1 m | 85.41 | 85.41 | yes |  |
| d3-d1 m | 153.11 | 153.11 | yes |  |
| 10 ns * c m | 2.99792458 | 2.99792458 | yes | plan: 2.998 m |
| B3 baseline: no bias, exact delays → fix | (200.17, 150.17), 0.24 m | grid quantisation only | yes | numpy, demo's centroid grid (cen ± 350 m, 0.5 m steps) |
| B3 predict: 10 ns bias on tower 2 only → fix | (198.17, 150.17), 1.84 m from UE; moves 2.00 m from baseline | answer key | yes | refreshed 2026-11-18 for the fixed centroid grid (old UE-centred grid gave (198.0, 150.5), 2.06 m) |
| B3 same 10 ns bias on all towers → fix | (200.17, 150.17), same as baseline | exact cancel | yes | bias cancels exactly in the differences; the 0.24 m left is grid quantisation |
| B2 Try UE (250,150) → samples, solver | (29.88, 29.88, 44.07); fix (250.17, 150.17), 0.24 m | inside box | yes | centroid box finds it |
| B4 sum gNB(Rx-Tx)+UE(Rx-Tx) | 2d/c exactly | 2d/c | yes | (2d/c+w)+(−w) |
| B4 NLOS 30 m on both legs → c·sum/2 | d+30 m | +30 m | yes | |
