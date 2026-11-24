# Track 15 "End to End": Ani's lecture narration (Writer, DRAFT v3)

- **v3 change (Showrunner ruling, 2026-11-18):** in S5's worked example (LG4), "nine point seven" now reads "nine point seven six" (3.37 + 4.39 + 1 + 1 = 9.76%). Nothing else changed from v2.

- **Spoken words (S1–S6, budgeted):** 1,622 (1,471 narration plus 151 read-aloud self-check questions). **Est. read time:** 10.8 min at 150 wpm; with about 10 s of silence at each of the 6 pauses, about 11.8 min.
- **S6 album recap:** 168 words (≈ 67 s) plus one 10 s recall pause, about 77 s, inside the 60–90 s window. **S7 outro (separate, not budgeted):** 28 words, ≈ 11 s.
- **All sections including S7:** 1,650 words, 11.0 min spoken, about 12.0 min with pauses.
- **Budget (TIME_BUDGETS_v2, "End to End" row):** min 7, typical 12, max 17 min, with the S6 album recap counted and the S7 outro not counted. S1–S6 runs 1.2 min under typical on read time and 0.2 min under with pauses. Above the floor and below the ceiling, with no padding.
- **Path:** `lecture/track15/track15_narration_v3.md` (v3; v1 and v2 kept unchanged beside it). Sources were taken from `lecture/track15/` (title "End to End", RENUMBER_MAP 15 = old T15) and `lecture/pedagogue/T15_DFMEA.md`. I used `track15_demo_plan.md`, which uses the new numbers. `track15_demo_plan_v2.md` is a history copy with old IDs and was not used.
- **Format:** follows the NARRATION SPEC at the top of `scratch/narration/track01_narration_v1.md`. S6 is the 60–90 s album recap; S7 is a separate outro.
- **v2 changes.** (1) Review FIX 1, L32: BWP, CORESET and PDCCH are now recalled as labels from P00a ("Grid and Waveform": BWP) and P00b ("Map of the Link": PDCCH in a CORESET, "lecture 15 shows them in a full configuration"), not taught as new or called uncovered. The S2 pause and its answer were reworded to match. (2) Review FIX 2, L81 and L77: the noise-EVM arithmetic is now stated as in lecture 02, 100/√((Nfft/Kocc)·SNR) = 100/√((1024/624)·316.2) = 100/√518.9 = 4.39%. The S4 0 dB line was aligned the same way (100/√(1024/624) = 78.1%). Re-checked in Python; v1's spoken order would give about 1388%.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent.

## Critical-finding map (pedagogue/T15_DFMEA.md; K = 6)
| DFMEA | Where handled |
|---|---|
| F5 representation (288) | S3: one hardware order (IQ → PA → channel → AWGN → Rx-LO phase noise), the reason for each place, and "all four on" over an identity channel; pause |
| F6 transfer (240) | S4: B3's input goes through the same flags, so the Try is one flag flip; pause predicts the failure |
| F7 retention (189) | S6: a 15-lecture album recap (one invariant per lecture), plus a recall pause before it |
| F2 prereq gap (150) | S2: BWP (P00a), CORESET and PDCCH (P00b) recalled as P00 labels, first seen here in a full configuration; the wavegen PDSCH config differs from nrPDSCHConfig; pause |
| F3 ordering (150) | S5: lecture two's noise-EVM formula predicts the AWGN row; pause predicts it |
| F8 assessment (150) | S5: an album-level question that needs two lectures (two and fourteen) |

---
## S1 Cold open (target 25 s)
[Screen] Ani at the desk. Lecture title cards tile in behind her.

ANI: Fourteen lectures, fourteen pieces: a grid, a waveform, a sync block, a code, a shared channel, two channel models, an estimate, beams, sounding, a full link, position, orbit, and an imperfect radio. Today all of them go into one scenario.

## S2 Code beat B1: one config, one waveform (target 150 s)
[Screen] Demo section B1, the printed generator summary.

ANI: The album ends where a real stack starts: one downlink configuration and one call to a generator. In the code, c f g is an N R DL Carrier Config for frequency range one, a ten megahertz channel, ten subframes, and no windowing. The sync burst is switched off to keep the grid simple. N R Waveform Generator returns the waveform and an info structure. The script reads the generator's own grid, Resource Grid In Carrier, and its info: the F F T size and the sample rate.

That configuration also holds three names from the first two lectures, and this is the first full configuration that shows them. The bandwidth part, or B W P, from the grid-and-waveform lecture, is the window of resource blocks a device uses. From the map-of-the-link lecture, the P D C C H is the control channel that tells each phone where its data is, and it sits in a control region called a CORESET. Here they're filled in by the generator, and we leave them at their defaults.

One more detail matters later. c f g dot P D S C H one is a generator P D S C H config, an N R Wavegen PDSCH Config, not the N R PDSCH Config from lecture eleven. It carries extra fields, such as Target Code Rate. B3 passes it where a P D S C H config is accepted.

[PAUSE — self-check] The generator's grid shows filled resource elements you didn't place by hand. Name one source of them, and the lecture where you met it.

ANI: The D M R S, from the map-of-the-link lecture, or the control region, the CORESET, named in that same lecture and built for the first time today. That's why you read the generator's own grid instead of rebuilding it by hand.

Worked example, for the first learning goal. A ten megahertz carrier at fifteen kilohertz has fifty-two resource blocks, six hundred twenty-four subcarriers. Ten subframes of fourteen symbols is one hundred forty symbols, so the grid should be six hundred twenty-four by one hundred forty. With the expected F F T size of one thousand twenty-four, the sample rate is fifteen point three six megahertz, and ten milliseconds is one hundred fifty-three thousand six hundred samples. The script asserts that the waveform length equals the sample rate times ten milliseconds, whatever F F T size your release chooses.

## S3 Code beat B2: make the radio real, in hardware order (target 150 s)
[Screen] Demo section B2, the five-stage order printed as a line.

ANI: Impairments aren't a bag you sprinkle in any order. The demo uses one order, and the notes and the animation follow it. First, transmit I Q imbalance, with the same pair as lecture fourteen: half a decibel and two degrees. Then the transmit power amplifier, comm dot Memoryless Nonlinearity with a cubic polynomial and an I I P 3 of fifteen d B m. Then the channel, which here is the identity. Then thermal noise at the receiver, at a signal to noise ratio of twenty-five decibels. And last, phase noise from the receiver's own oscillator, minus seventy d B c per hertz at ten kilohertz, which is why it comes after the noise.

The song lists phase noise first, among the transmitter's flaws, and that's also physical: both ends have oscillators. This demo models the receiver's, and says so.

Four flags, apply I Q, apply P A, apply A W G N and apply P N, all start false. The function radio Chain applies whichever are on, in that fixed order, and every later beat uses it. The waveform is single-port, so no beam weights are applied. Mapping one port onto a panel would be a choice the toolbox doesn't make for you.

Worked example, for the fifth learning goal. Suppose a stage before the noise had twenty decibels of gain, and you put the noise in front of it by mistake. The noise power comes out a hundred times too big, so the noise E V M is ten times too big. And if the amplifier sat after the noise, it would compress the noise and the fading too, and your E V M would blame the wrong part.

[PAUSE — self-check] Why does the amplifier have to come before the receiver's noise in this chain?

ANI: The amplifier lives in the transmitter, so it only ever sees the transmitter's own waveform. Every impairment goes where it happens in the hardware.

## S4 Code beat B3: the plumbing invariant (target 140 s)
[Screen] Demo section B3, blkerr and the bit-match flag printed.

ANI: "Here's the invariant that keeps you honest: turn every impairment off, give it a clean channel and plenty of signal, and the chain must hand back exactly the bits you sent. If it doesn't, the bug is in the plumbing, not the physics." Lecture eleven checked one slot. Here the check covers the whole generator.

The documented place to read the transmitted bits is the info structure: Waveform Resources, P D S C H, Resources, Transport Block. The script walks that structure and asserts the field exists. It doesn't invent a substitute bit source.

Then the waveform goes through radio Chain with the B2 flags. With all four false, it's untouched. N R OFDM Demodulate uses the generator's F F T size and sample rate. N R PDSCH Indices and N R PDSCH Decode recover soft bits, with a tiny noise variance, and N R DLSCH Decoder checks the C R C. When all-off is true, the script asserts zero block error and a bit-exact match with the transport block.

Worked example, for the second learning goal. The printed line shows all-off one, blkerr zero, bit match one, and the T B S. Every one of those bits must match, not most of them.

[PAUSE — self-check] The Try sets apply A W G N to true with snr d B at zero. Before you run it, will the invariant pass?

ANI: No, and it isn't supposed to. At zero decibels, lecture two's formula, one hundred over the square root of one thousand twenty-four over six hundred twenty-four, puts the noise E V M near seventy-eight percent, so the block fails. With a flag on, the script reports blkerr instead of asserting, and B4 tells you which stage did it. Set the flag back, and the bits return.

## S5 Code beat B4: one change at a time, then all together (target 160 s)
[Screen] Demo section B4, the five-row E V M table.

ANI: "A scenario with ten knobs can fool you ten ways. So change one thing at a time, and keep the random seeds fixed." B4 runs five rows: I Q only, P A only, A W G N only, receiver phase noise only, and all four together. The channel stays the identity, so all four means all four impairments. E V M is measured on the resource elements the generator used.

Lecture two gave a formula for noise E V M: one hundred over the square root of the F F T size over the occupied subcarriers, times the linear S N R.

[PAUSE — self-check] Use that formula to predict the A W G N row at twenty-five decibels, assuming all six hundred twenty-four subcarriers are occupied and an F F T size of one thousand twenty-four.

ANI: Twenty-five decibels is about three hundred sixteen. One thousand twenty-four over six hundred twenty-four, times three hundred sixteen, is about five hundred nineteen. One hundred over the square root of that is about four point three nine percent. That's worked example three. The script prints its own prediction, using the measured average occupancy, next to the measured row. The two are close when occupancy is steady.

Then the triangle from lecture fourteen. "Remember that independent pieces add in power: three percent and four percent make about five, not seven." The script prints the root-sum-square of the four singles next to the all-on cascade.

Worked example, for the fourth learning goal. The I Q row should be near three point three seven percent, the same pair as lecture fourteen. Take four point three nine for noise, and suppose the amplifier and phase noise each print about one percent. The root-sum-square is about five point seven one percent, well short of the nine point seven six you'd get by adding. "If the total is much bigger than the root of the sum of squares, two of your pieces aren't independent, and that's worth knowing too."

[PAUSE — self-check] An album question that takes two lectures. An A W G N-only row reads four point four percent, and an I Q-only row reads three point four. Without running it, what should the two together read, and which lectures did you need?

ANI: About five point six percent: the root of four point four squared plus three point four squared. You needed lecture two for the noise E V M and lecture fourteen for adding in power.

## S6 Album recap (target 75 s)
[Screen] Ani, close-up. The fifteen lecture title cards tile in behind her, one per line.

[PAUSE — self-check] Before the recap: name one rule from any three earlier lectures, in your own words.

ANI: That's the whole path. The numerology sets the grid: fifteen kilohertz times two to the mu. The cyclic prefix turns an echo into one gain per tone. The sync block names the cell. L D P C protects each block, and its C R C is the final word. H A R Q resends with a new redundancy version. Taps carry delays, pilots let us estimate the channel, and clusters and angles set how many streams fit. A phase ramp steers a beam. Sounding goes up and C S I R S comes down. The C Q I aims at one in ten on the first transmission. Thirty centimeters per nanosecond turns time into distance. Satellites stretch the round trip and the Doppler. Real radios add flaws, and independent flaws add in power. And today: build the chain with everything off, check the bits come back, then add one flaw at a time.

## S7 Outro (target 25 s; separate segment, not in the recap window)
[Screen] Ani, outro plate.

ANI: Every demo in this series is teaching code, so run it, change one number, and predict what happens before you press go. Thanks for building it with me.

---
## Notes for Showrunner
- **Learning goals (5 of 5).** LG1: a 624 × 140 grid and 153600 samples (assuming Nfft = 1024; the assert holds for any Nfft). LG2: the bit-exact print, plus the 78% noise EVM at 0 dB. LG3: the 4.39% AWGN prediction at 25 dB (full occupancy), via (1024/624)·316.2 = 518.9. LG4: rss(3.37, 4.39, 1, 1) = 5.71% against 9.76% added; the PA and PN values are hypothetical and labelled so in speech. LG5: the 20 dB gain mis-order (noise EVM ten times too big). Two-lecture check: rss(4.4, 3.4) = 5.56%. All were checked in Python.
- **Plan vs fixed demo.** The plan's LG1 includes a CDL channel with a panel array and the full lecture-eleven receiver (timing, estimation, MMSE). The fixed demo uses an identity channel, a single port, and direct PDSCH decode (no estimator). The narration follows the demo and says the channel is the identity. The song's CDL and panel lines aren't quoted as demo steps.
- **Phase-noise position.** The lyric (L13) lists phase noise among the transmitter's flaws. The fixed demo models the receiver LO, after AWGN (the F5 fix). The narration names both and says which one the demo models. No lyric change.
- **Unverified.** The `TransportBlock` path, the wavegen-PDSCH-as-nrPDSCHConfig pass, and the multi-element mapping are demo VERIFY or "to confirm" items. The generator's default PDSCH, CORESET and occupancy are not stated as numbers.
- **Lyric quotes.** All are verbatim and from the dry list: L34–37, L54–55, L57–58 and L59–60. The intro (D3: stale neighbour references), the hook, survivor L6, L12 and L23, and the outro are not quoted.
- **Album recap.** S6 is 168 words (≈ 67 s) plus a 10 s recall pause, about 77 s, inside 60–90 s. It covers lectures 01–15 in D2 order, from the notes' 15-row table. P00a/b are folded into "the grid" and "the cyclic prefix" lines. S7 is 28 words, about 11 s spoken. It reads as written in the plan, which is under its 20–30 s window; pad with plate time, not words.
- **Cross-references (new numbers).** Lecture two (noise EVM), eleven (the one-slot pass), and fourteen (IQ pair, triangle).
