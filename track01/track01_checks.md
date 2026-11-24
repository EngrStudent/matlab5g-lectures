# Track 01 "Two to the Mu" — pure-math checks

Checked in Python on this box (no MATLAB). Toolbox outputs, fading draws and runtimes are not claimed here. Plan numbers are compared where the plan stated a definite value.

| Check | Value | Expected (if any) | OK? | Note |
|---|---|---|---|---|
| SCS table 15*2**mu kHz | (15, 30, 60, 120, 240) | (15, 30, 60, 120, 240) | yes |  |
| slots/subframe = 2**mu | (1, 2, 4, 8, 16) | (1, 2, 4, 8, 16) | yes |  |
| Tu(mu=0) us | 66.6666666667 | 66.6666666667 | yes | 66.6... us |
| ordinary CP us | 4.6875 | 4.6875 | yes |  |
| symbol+CP us | 71.3541666667 | 71.3541666667 | yes |  |
| 7*(2048+144) | 15344 | 15344 | yes |  |
| 15360-16 | 15344 | 15344 | yes |  |
| CP samples mu=0 NRB=106 Nfft=2048 ordinary/extra | (144, 16) | (144, 16) | yes | integer check |
| those CP samples are integers | True | True | yes |  |
| CP samples mu=0 NRB=270 Nfft=4096 ordinary/extra | (288, 32) | (288, 32) | yes | integer check |
| those CP samples are integers | True | True | yes |  |
| CP samples mu=1 NRB=51 Nfft=1024 ordinary/extra | (72, 16) | (72, 16) | yes | integer check |
| those CP samples are integers | True | True | yes |  |
| CP samples mu=4 NRB=20 Nfft=512 ordinary/extra | (36, 64) | (36, 64) | yes | integer check |
| those CP samples are integers | True | True | yes |  |
| box 2688 REs at 2.88 MHz | 2688 | 2688 | yes |  |
| 51 RB @ 30 kHz default Nfft | 1024 | 1024 | yes |  |
| frame samples 1024*30e3*10e-3 | 307200 | 307200 | yes |  |
| A3 4.6875 us * 3e8 m | 1406.25 | 1406.25 | yes | plan uses c=3e8 for the distance cue |
| A3 120 kHz CP * 3e8 m | 175.78125 | 175.78125 | yes |  |
| B1 Try mu=5 row | SCS 480 kHz, 32 slots/subframe, 320 slots/frame | 15·2^5, 2^5 | yes | FR2-2 numerology; edit muList/cpList/nrbList |
