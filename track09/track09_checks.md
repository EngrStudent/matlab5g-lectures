# Track 09 "Steer the Beam" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| 10*log10(16) dB | 12.0411998266 | 12.0412 | yes |  |
| 10*log10(64) dB | 18.0617997398 | 18.0618 | yes |  |
| B3 lobes ≥ peak−8 dB, N=16, steer 30°, d=0.5λ | [30°] | 1 lobe | yes | numpy array factor |
| B3 same, d=1.0λ | [−30°, 30°] | 2 lobes | yes | assert now holds |
| B3 Try d=0.75λ / 1.5λ | 2 / 3 lobes | achievable | yes | |
| v1 B3 (broadside, d=λ) | lobes only at 0° inside (±90° endpoints excluded) | 1 vs 1 | **fail** | why the v1 L101 assert failed |
