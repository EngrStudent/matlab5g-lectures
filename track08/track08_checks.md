# Track 08 "Clusters and Angles" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| ±45° slants both ends: E[co] vs E[cross] (38.901 pol. matrix, random phases) | both (1+1/κ)/2 | equal | yes | why B3 uses V/H [0 90] instead |
| V/H both ends: E[co]/E[cross] | κ = XPR | 10 dB for CDL-A | yes | algebraic, per ray; one draw varies |

The rank-1 teaching matrix H = a a^H has a second singular value of 0 by construction (asserted in the demo). CDL snapshot singular values are run results.
