# Track 14 "Mirror Image" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| iqimbal IRR dB | 29.459068478 | 29.46 | yes |  |
| iqimbal EVM % | 3.36547660641 | 3.37 | yes |  |
| wrong g=10**(0.5*A/20) IRR dB (must NOT be used) | 32.9093700373 | 32.91 | yes | caught and corrected in track14_demo.m |
| rss(3,4) | 5 | 5 | yes |  |
| B2 row 60 offset from DC (K=624) | −253 sc | negative | yes | v1 called it "positive" |
| B2 mirror row | 566 (+253 sc) | K−k+2 | yes | |
| B4 U-curve shape, cubic AM/AM, IIP3 10 dBm, floor −50 dBm | min ≈ 1.4 % near −14 dBm | interior minimum | yes | numpy approximation of the cubic model on an OFDM-like signal; toolbox curve will differ in detail |
