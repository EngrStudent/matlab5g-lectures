# P00a "Grid and Waveform": Ani's lecture narration (Writer, DRAFT v2)

- **Spoken words:** 1,034 (916 narration plus 118 read-aloud self-check questions; hyphenated words counted as parts). **Est. read time:** 6.9 min at 150 wpm, or about 7.7 min with about 10 s of silence at each of the 5 self-check pauses.
- **Budget (TIME_BUDGETS_v2, P00A):** min 6, typical 7, max 8 min. v2 runs 7.7 min with pauses: above the floor, 0.7 min over typical, under the ceiling.
- **Spec:** NARRATION SPEC at the top of `lecture/track01/track01_narration_v1.md` (voice, structure, fill rules, spoken form, notation, numbering, count method).
- **Sources read:** `pedagogue/ARCHITECTURE_PASS.md` P00_SPEC (objectives 1–6, the P00a beat table, commit points); `pedagogue/TIME_BUDGETS_v2.md`; `pedagogue/DECISIONS.md` D1/D7. There is no `lecture/p00/` source folder, demo, notes, DFMEA or lyrics; none are needed (spoken-only, no song).
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent. Album numbers are used throughout (RENUMBER_MAP.md).

## Self-check map
There is no P00 DFMEA (TIME_BUDGETS_v2: NO DATA), so the self-checks sit at the P00_SPEC commit points: 16-QAM bits/QPSK mapping (B1), PRB→CRB and 168 REs (B2), 61.44 Msps (B3), ICI under offset (B3), and 144/72 CP samples (B4).

---
## S1 Cold open (target 25 s)
[Screen] Ani at the desk. A box drawn on paper, divided into numbered cells.

ANI: Picture a twenty megahertz 5G carrier as a box of numbered cells. Every cell holds one number, and that number started life as a few bits. This lecture follows those bits into the cells, and the cells out into samples a radio can send. No song and no code today: just the vocabulary every later lecture uses.

## S2 Concept: bits to symbols to cells to samples (target 50 s)
[Screen] Four labels in a row: bits, symbols, cells, samples.

ANI: There are four steps. Bits become symbols, points on a plane of complex numbers. Symbols go into cells of a time-frequency grid. Each column of the grid becomes a burst of samples through an inverse F F T. And each burst gets a short copy of its own end in front, the cyclic prefix. For each, I'll name the lecture that goes deeper.

## S3 Beat B1: symbols (target 85 s)
[Screen] Animation A1: a constellation building point by point.

ANI: A constellation is the set of complex points a modulation can send. Q P S K has four points, so each symbol carries two bits. M-ary Q A M, quadrature amplitude modulation, has M points on a square grid, and carries log base two of M bits per symbol. Sixteen Q A M has sixteen points; sixty-four Q A M carries six bits. Every constellation is scaled to unit average power.

The points are labeled with Gray coding: neighbors differ in only one bit. A small noise error then usually costs one bit, not several.

In 5G's Q P S K, the first bit picks the sign of the real part and the second bit the sign of the imaginary part, each scaled by one over root two. Zero means plus. So bits zero, zero map to one plus j, over root two. Bits one, zero map to minus one plus j, over root two.

[PAUSE — self-check] How many bits does one sixteen Q A M symbol carry? And where do bits zero, one land in Q P S K?

ANI: Four bits, because two to the four is sixteen. Zero, one lands at one minus j, over root two: positive real part, negative imaginary part.

## S4 Beat B2: the grid (target 95 s)
[Screen] Animation A2: zoom from the carrier to a bandwidth part, to one resource block, to one resource element.

ANI: Five grid terms. A resource element, R E, is one subcarrier for one symbol, a single cell. A resource block, R B, is twelve subcarriers tall. A slot is fourteen symbols wide with the normal cyclic prefix. So one resource block for one slot holds twelve times fourteen, one hundred sixty-eight resource elements. A carrier of fifty-one resource blocks is twelve times fifty-one, six hundred twelve subcarriers tall.

Common resource blocks, C R Bs, are numbered across the whole carrier. A bandwidth part, B W P, is a window of consecutive common resource blocks that a device is set up to use. Its start is N Start B W P and its width is N Size B W P. Physical resource blocks, P R Bs, are numbered from the start of the bandwidth part, not from the carrier.

[PAUSE — self-check] A bandwidth part starts at common resource block ten. Physical resource block five sits at which common resource block? And how many resource elements does one resource block hold in one slot?

ANI: Common resource block fifteen: ten plus five. And one hundred sixty-eight resource elements. Lecture 01 shows how this grid changes shape with the numerology.

## S5 Beat B3: one inverse FFT per symbol (target 95 s)
[Screen] Animation A3: tones summing, then an offset breaking the nulls.

ANI: Each column of the grid becomes one inverse F F T. The F F T size, N F F T, is a power of two and bigger than the number of used subcarriers. The unused bins at both edges are guard bins: they keep energy off the neighbors' channels. The sample rate is N F F T times the subcarrier spacing.

Orthogonality is why the tones can sit so close. Over one symbol, every tone completes a whole number of cycles relative to its neighbors, so at the receiver's F F T, each tone's spectrum has a null exactly on every other tone. Nothing leaks.

Shift every tone by a fraction of the spacing, with a frequency offset between the transmitter and receiver clocks, and those nulls no longer line up. Each tone leaks into its neighbors. That's inter-carrier interference, I C I.

[PAUSE — self-check] What's the sample rate for an F F T size of two thousand forty-eight at thirty kilohertz spacing?

ANI: Two thousand forty-eight times thirty thousand: sixty-one point four four million samples a second.

[PAUSE — self-check] A frequency offset of a tenth of the spacing. Does it cause inter-carrier interference, and why?

ANI: Yes. The tones are no longer a whole number of cycles apart over the symbol, so orthogonality is lost. Lecture 02 measures the damage.

## S6 Beat B4: the cyclic prefix in samples (target 70 s)
[Screen] A sample-count timeline of one half millisecond.

ANI: The cyclic prefix, C P, is a copy of the last part of each symbol placed in front of it. Its length is a fixed time, so its length in samples, N C P, depends on the sample rate. The reference case is fifteen kilohertz with an F F T size of two thousand forty-eight. There the normal prefix is one hundred forty-four samples. The first symbol of each half millisecond gets one hundred sixty instead, so the clock lands exactly.

Check one slot at that rate: fourteen symbols of two thousand forty-eight, plus twelve prefixes of one hundred forty-four and two of one hundred sixty, make thirty thousand seven hundred twenty samples. That's exactly one millisecond at thirty point seven two megahertz.

Counts scale with the F F T size: an F F T size of one thousand twenty-four gives seventy-two and eighty. Why the prefix works against echoes is lecture 02's job.

[PAUSE — self-check] At fifteen kilohertz and an F F T size of two thousand forty-eight, how many samples is the normal prefix? And at one thousand twenty-four?

ANI: One hundred forty-four, and seventy-two.

## S7 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Four invariants to keep. Bits per symbol is log base two of the constellation size: two, four, six for Q P S K, sixteen Q A M, and sixty-four Q A M. One resource block for one slot holds one hundred sixty-eight resource elements. The sample rate is the F F T size times the subcarrier spacing. And the cyclic prefix is a fixed time, so its sample count scales with the F F T size. Next, the map of the link: who sits where on this grid, and how the bits are protected.

---
## Notes for Showrunner
- Every objective (1–6) is covered with a worked number.
- The QPSK mapping (bit 0 → +, scaled by 1/√2) follows TS 38.211 §5.1.3. It isn't in the P00_SPEC text, so it's my addition; please check it.
- v2 (Pedagogue review, FIX 1): trimmed the S6 slot-sum walk and short restatements in S2, S3, S4 and S6 (about 18 s) so the paused delivery stays under the 8 min max; header recounted with the reviewer's method (hyphenated words count as parts).
- The 1024-FFT counts of 72/80 match lecture 02's demo.
- Animations A1–A3 are named as in P00_SPEC; there is no kit plate pick.
