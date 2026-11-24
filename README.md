# 5G Fundamentals with MATLAB

Companion MATLAB scripts, lecture notes, checks, and narration for the 5G Fundamentals lecture series. The series walks a 5G NR downlink from the resource grid to an end-to-end link.

By EngrStudent. Teacher voice and visuals generated with Grok.

## How to use this repository

1. Watch the lectures in order, from P00a through T15.
2. Open that lecture's folder in this repository.
3. Run the MATLAB demo and do the Build-it exercise yourself. Work the self-checks before you look at what the script prints.
4. Use the lecture notes and checks alongside the demo.

Build-it answers are not included in this repository.

## What you need

MATLAB R2024a or later and the 5G Toolbox. Some later tracks also need Communications Toolbox or Phased Array System Toolbox; the demo header lists them when they are required.

These are teaching demos for you to run in MATLAB. They are not a live MATLAB session, and printed values come from your own run. To open a demo as a Live Script, use the Live Editor's Save As `.mlx` (do not hand-edit).

## Lectures

| Code | Folder | Lecture | About |
|---|---|---|---|
| P00a | [Grid and Waveform](track00_fundamentals/) | [P00a · Grid and Waveform](https://www.youtube.com/watch?v=wyDEW97bGpE) | Follow a 5G signal through four steps: bits become symbols, symbols fill the cells of a time-frequency grid, each grid column becomes samples through an inverse FFT, and every symbol gets its cyclic prefix. |
| P00b | [Map of the Link](track00_fundamentals/) | [P00b · Map of the Link](https://www.youtube.com/watch?v=P6A8iGZS2Q0) | Map a 5G link: where each signal sits on the grid, how a block of bits is protected, and how fast the channel changes. |
| T01 | [Two to the Mu](track01/) | [T01 · Two to the Mu](https://www.youtube.com/watch?v=8Ar_MpVsuAI) | Raising numerology μ doubles the subcarrier spacing and cuts the symbol time in half, while a fixed time-bandwidth region keeps the same number of resource elements. |
| T02 | [Copy the Tail](track02/) | [T02 · Copy the Tail](https://www.youtube.com/watch?v=FJVyE2SxfcM) | The cyclic prefix lets one complex divide undo a multipath echo on each subcarrier, and windowing spends prefix samples to cut out-of-band energy. |
| T03 | [Find Me in the Noise](track03/) | [T03 · Find Me in the Noise](https://www.youtube.com/watch?v=546d0mgqEIQ) | The phone searches the synchronization signal block to learn the cell identity, the timing, and the master information block. |
| T04 | [Every Check Agrees](track04/) | [T04 · Every Check Agrees](https://www.youtube.com/watch?v=2Sngaa5I_30) | LDPC lifting and belief-propagation decoding can pass every parity check and still be the wrong word, which is why a CRC sits outside the code. |
| T05 | [Say It Again](track05/) | [T05 · Say It Again](https://www.youtube.com/watch?v=3RZGGfP52k4) | Transport-block size and the MCS table set how many information bits fit, and HARQ sends another redundancy version of the same block. |
| T06 | [Taps in Time](track06/) | [T06 · Taps in Time](https://www.youtube.com/watch?v=VvxoG9fSYRs) | A tapped delay line sets the echo delays and powers, and Doppler sets how fast those taps change. |
| T07 | [Learn the Channel](track07/) | [T07 · Learn the Channel](https://www.youtube.com/watch?v=a3XOzGPbJ0M) | Known DM-RS pilots estimate the channel, and MMSE equalization turns that estimate into soft bits. |
| T08 | [Clusters and Angles](track08/) | [T08 · Clusters and Angles](https://www.youtube.com/watch?v=KRC9kALBOLw) | A clustered delay line groups rays by delay, power, and angle, and a narrow angle spread can leave a large array with only one strong stream. |
| T09 | [Steer the Beam](track09/) | [T09 · Steer the Beam](https://www.youtube.com/watch?v=cJba4nWFfN8) | A phased array steers a beam by a phase ramp across its elements, and hybrid beamforming reports that direction as a compressed beam index. |
| T10 | [Sound It Out](track10/) | [T10 · Sound It Out](https://www.youtube.com/watch?v=Ck9tLkB-Xjs) | Sounding reference signals and CSI-RS measure the channel, including whether an FDD duplex gap is wider than the coherence bandwidth. |
| T11 | [One in Ten](track11/) | [T11 · One in Ten](https://www.youtube.com/watch?v=qPTDpw5HVJY) | A PDSCH link curves first-transmission and after-HARQ block error rate against SNR, with the CQI target at one error in ten. |
| T12 | [How Far](track12/) | [T12 · How Far](https://www.youtube.com/watch?v=HeMoGgnnL7A) | Positioning reference signals turn a time delay into a range, and time-difference or round-trip measurements locate the phone among towers. |
| T13 | [Signals from Orbit](track13/) | [T13 · Signals from Orbit](https://www.youtube.com/watch?v=w-5muEFZMcI) | A satellite link changes the round-trip time and the Doppler scale, and a long GEO delay leaves a stop-and-wait HARQ process idle. |
| T14 | [Mirror Image](track14/) | [T14 · Mirror Image](https://www.youtube.com/watch?v=Z7KYdugreb0) | Phase noise, I/Q imbalance, and amplifier compression each leave a residual error vector, and independent residuals add in power. |
| T15 | [End to End](track15/) | [T15 · End to End](https://www.youtube.com/watch?v=8zydzAzfjBw) | One downlink carrier configuration generates the waveform, then each impairment is switched on alone and together to see the error add up. |

P00a and P00b share the [Fundamentals](track00_fundamentals/) folder.

## License

This repository is licensed under [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0/). See [LICENSE](LICENSE) for the full text.

Free for personal, classroom and academic use with credit to EngrStudent. Commercial use, including selling or charging for access, requires written permission from EngrStudent.

Not affiliated with or endorsed by MathWorks; MATLAB is a trademark of The MathWorks, Inc.
