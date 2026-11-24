# P00a "Grid and Waveform": Ani's lecture narration (Pedagogue loop r01, DRAFT v3)

- **Spoken words:** 885 (764 narration plus 121 read-aloud pause questions; `ANI:` text and pause questions only, headings, `[Screen]` and `[CHECK]` labels excluded; hyphenated words and spoken acronym letters counted as parts). **Timing plan (voice not yet blessed, so this is a plan, not a measurement):** 6 pauses, 84 s of holds. **Min 6:54** (150 wpm, every hold 10 s) · **Typical 7:30** (145 wpm, holds as marked) · **Max 7:43** (140 wpm, holds as marked). Holds longer than marked (T_PAUSE max 25 s each) would give 8:49, so keep the marked holds.
- **Budget (TIME_BUDGETS_v2, P00A):** min 6, typical 7, max 8 min. Unchanged; the typical plan lands in band (see `P00_LECTURE_LOOP_r01.md`).
- **Source:** `p00a_narration_v2.md` (left in place), rewritten by the P00 lecture loop r01. Review, timing method and change list: `lecture/p00/P00_LECTURE_LOOP_r01.md`.
- **Demos matched (Loop-2 r02, authoritative):** `p00/revised_r02/p00a_bits_and_grid_demo.m` (B1, B2, Build it) and `p00/revised_r02/p00a_ofdm_and_cp_demo.m` (B3, B4, Build it). Worked numbers are the values the demos give or call "narrated". Pause practice uses changed values that are not any demo Try, Stage 3a, interpretation, E1, E2 or Review answer.
- **Spec:** NARRATION SPEC in `lecture/track01/track01_narration_v1.md`, with two convention changes (reasons in the summary): each pause mark names its hold and type, and every answer after a pause sits under a `[CHECK — after the hold]` label. P00 now has demos, so `[Screen]` cues can name M's demo recordings, as T01 does.
- Written 2026-11-23, America/New_York. Nothing was run, recorded or sent. Album numbers are used throughout.

## Self-check map
| Pause | Beat | Kind | Hold | Practice of |
|---|---|---|---|---|
| SC-01 | S3 B1 | changed values, one step | 10 s | log2 M; the QPSK sign rule and quadrant numbering |
| SC-02 | S4 B2 | changed values, arithmetic | 18 s | CRB = BWP start + PRB; REs per RB-slot |
| SC-03 | S6 B3 | changed values, arithmetic | 18 s | sample rate = NFFT × spacing |
| SC-04 | S6 B3 | concept, transfer | 10 s | offset breaks orthogonality (ICI) |
| SC-05 | S7 B4 | changed values, arithmetic | 18 s | CP samples = fixed time × sample rate |
| SC-06 | S9 | spaced retrieval | 10 s | the QPSK sign rule (from S3) |

---
## S1 Cold open (plan 16 s at 145 wpm, holds included)
[Screen] Ani at the desk. A box drawn on paper, divided into numbered cells.

ANI: Picture a 5G carrier as a box of numbered cells. Each cell holds a complex number that began as a couple of bits. Today: bits into cells, and cells out into samples. Every later lecture counts in these units.

## S2 The four steps (plan 17 s at 145 wpm, holds included)
[Screen] Four labels in a row: bits, symbols, cells, samples. Under the first two, "bits-and-grid demo"; under the last two, "OFDM-and-CP demo" (local text).

ANI: Four steps. Bits become symbols on the complex plane. Symbols fill the cells of a time-frequency grid. Each grid column becomes samples through an inverse F F T. Each burst gets a copy of its end in front: the cyclic prefix.

## S3 Beat B1: bits to symbols (plan 78 s at 145 wpm, holds included)
[Screen] Animation A1: a QPSK constellation builds point by point, then 16-QAM.

ANI: A constellation is the set of points a modulation can send. With M points, a symbol carries log base two of M bits. Worked example: sixteen Q A M has sixteen points, two to the four, so four bits per symbol. Points are scaled to unit average power; for Q P S K, divide by root two. Labels are Gray coded: neighbours differ in one bit.

The 5G Q P S K rule: the first bit sets the real part's sign, the second bit the imaginary part's, and zero means plus. So zero, zero gives one plus j, over root two, and zero, one gives one minus j, over root two. Counting quadrants anticlockwise from the top right, those are quadrants one and four.

[PAUSE — self-check · hold 10 s · changed values, one step] A constellation with eight points: how many bits per symbol? And where do the Q P S K bits one, zero land?

[CHECK — after the hold]
ANI: Three bits, since two cubed is eight. One, zero gives minus one plus j, over root two: quadrant two.

## S4 Beat B2: the grid (plan 85 s at 145 wpm, holds included)
[Screen] Animation A2: zoom from the carrier to a bandwidth part, to one resource block, to one resource element.

ANI: Grid words. A resource element, R E, is one subcarrier for one symbol. A resource block, R B, is twelve subcarriers. A slot is fourteen symbols, with normal prefix. So one R B for one slot holds twelve times fourteen: one hundred sixty-eight R Es.

Common resource blocks, C R Bs, count from zero at the carrier's bottom. A bandwidth part, B W P, is a device's window of C R Bs; physical resource blocks, P R Bs, count from zero at the window's bottom. So C R B equals window start plus P R B. Worked example: a window at C R B four puts P R B seven at C R B eleven.

[PAUSE — self-check · hold 18 s · changed values, arithmetic] A window starts at C R B thirty. Which C R B holds P R B six? And how many R Es do two R Bs hold in one slot?

[CHECK — after the hold]
ANI: C R B thirty-six. And three hundred thirty-six, twice one hundred sixty-eight.

## S5 Demo bridge: bits and grid (plan 12 s at 145 wpm, holds included)
[Screen] M's recording of `p00a_bits_and_grid_demo`: the Build it Stage 3a and Stage 3b sections with their blanks unfilled. No results table, figure or check output on screen.

ANI: In this demo's Build it, Stage 3a asks for the quadrant of symbol two before you build. Its check refuses once Stage 3b exists; a pass locks your prediction.

## S6 Beat B3: one inverse FFT per symbol (plan 97 s at 145 wpm, holds included)
[Screen] Animation ANIM-P00a-b "FFT bins", then animation A3 "Tones and nulls".

ANI: Each grid column becomes one inverse F F T. Its size, N F F T, is a power of two above the used subcarriers; the empty edge bins are guard bins. The sample rate is N F F T times the subcarrier spacing. Worked example, the demo's reference: two thousand forty-eight times thirty kilohertz is sixty-one point four four million samples a second.

Tones can sit this close because they're orthogonal: at the receiver's F F T, each tone's null lands on every other tone. If the clocks disagree, the tones shift, the nulls miss, and energy leaks: inter-carrier interference, I C I. The demo's Try predicts how much, with a sinc-squared rule.

[PAUSE — self-check · hold 18 s · changed values, arithmetic] Five hundred twelve bins at thirty kilohertz: what's the sample rate?

[CHECK — after the hold]
ANI: Fifteen point three six million samples a second.

[PAUSE — self-check · hold 10 s · concept, transfer] The clocks are off by a quarter of the spacing. Is there I C I, and why?

[CHECK — after the hold]
ANI: Yes. The nulls no longer land on the other tones, so orthogonality is lost.

## S7 Beat B4: the cyclic prefix in samples (plan 80 s at 145 wpm, holds included)
[Screen] Animation ANIM-P00a-c "Half-millisecond in samples", then ANIM-P00a-d "Copied tail".

ANI: Clock check: this beat uses the fifteen kilohertz reference, thirty point seven two million samples a second, not the last beat's clock.

The cyclic prefix, C P, is a copy of the symbol's tail, placed in front. It's a fixed time, so its sample count is that time times the sample rate. Here the normal prefix is one hundred forty-four samples, and the first symbol of each half millisecond gets one hundred sixty, so seven symbols fill half a millisecond exactly.

The first sample sent copies body sample two thousand forty-eight, minus one hundred forty-four, plus one: one thousand nine hundred five.

[PAUSE — self-check · hold 18 s · changed values, arithmetic] Same fifteen kilohertz spacing, but N F F T is five hundred twelve. How many samples is the normal prefix?

[CHECK — after the hold]
ANI: Thirty-six: a quarter of the F F T size, so a quarter of one hundred forty-four. Lecture 02 shows why the prefix beats echoes.

## S8 Demo bridge: OFDM and the prefix (plan 12 s at 145 wpm, holds included)
[Screen] M's recording of `p00a_ofdm_and_cp_demo`: the B4 clock reminder, then the Build it Stage 3a and Stage 3b sections with their blanks unfilled. No results table, leakage table or check output on screen.

ANI: In the O F D M demo's Build it, Stage 3a asks which body sample is copied to the front. Use the tail-start rule; a pass locks your prediction.

## S9 Retrieval (plan 22 s at 145 wpm, holds included)
[Screen] Self-check card on a plain background. No recap lines on screen.

[PAUSE — self-check · hold 10 s · spaced retrieval] No looking back: in Q P S K, which bit sets the real part, and what sign does a zero give?

[CHECK — after the hold]
ANI: The first bit, and a zero gives plus.

## S10 Recap (plan 30 s at 145 wpm, holds included)
[Screen] Ani, close-up.

ANI: Keep these. Bits per symbol: log base two of M, at unit average power, with Gray labels so a slip costs one bit. One R B for one slot: twelve times fourteen R Es. C R B: window start plus P R B. Sample rate: N F F T times spacing. The prefix: a copied tail of fixed time, so its samples follow the rate. Next, P00b: the map of the link.

---
## Notes for Showrunner
- Every P00_SPEC objective (1–6) keeps a worked number; each now also has changed-values practice.
- The worked QPSK pair is now 00 and 01, the pair the bits demo checks as "stated in the narration" (v2 used 00 and 10). WE-01 changes with it (cut sheet v3).
- The 64-QAM count, the PRB 5 / CRB 10 example and the Nfft 1024 prefix counts are no longer spoken: they are Try targets in the r02 demos.
- New spoken item: the tail-start rule (S7) and the quadrant numbering (S3), both used by the r02 Stage 3a checks.
