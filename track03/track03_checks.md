# Track 03 "Find Me in the Noise" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| PCI bijection size | 1008 | 1008 | yes |  |
| PCI bijection covers 0..1007 | True | True | yes |  |
| Case A Lmax=4 first symbols | (2, 8, 16, 22) | (2, 8, 16, 22) | yes |  |
| B5 Try Period=5, all 4 blocks | 64 symbols: {2..5,8..11,16..19,22..25} + 0/70/140/210 | floor(20/5)=4 bursts | yes | derived by the new expected loop |
| B5 Try TransmittedBlocks=[1 0 0 0], Period 20 | symbols 2..5 only (4) | first block only | yes | |
| B4 Lmax=4 DM-RS index | ibar = i_SSB + 4*n_hf | 38.211 7.4.1.4.1 | yes | corrects old "only two LSBs" comment |
