# P00b "Map of the Link": Ani's lecture narration (Pedagogue loop r01, DRAFT v2)

- **Spoken words:** 991 (871 narration plus 120 read-aloud pause questions; `ANI:` text and pause questions only, headings, `[Screen]` and `[CHECK]` labels excluded; hyphenated words and spoken acronym letters counted as parts). **Timing plan (voice not yet blessed, so this is a plan, not a measurement):** 6 pauses, 104 s of holds. **Min 7:36** (150 wpm, every hold 10 s) · **Typical 8:34** (145 wpm, holds as marked) · **Max 8:49** (140 wpm, holds as marked). Holds longer than marked (T_PAUSE max 25 s each) would give 9:40, so keep the marked holds.
- **Budget (TIME_BUDGETS_v2, P00B):** min 7, typical 8, max 9 min. Unchanged; the typical plan lands in band (see `P00_LECTURE_LOOP_r01.md`). D7 overload watch: B1 drops from eight new names to six.
- **Source:** `p00b_narration_v1.md` (left in place), rewritten by the P00 lecture loop r01. Review, timing method and change list: `lecture/p00/P00_LECTURE_LOOP_r01.md`.
- **Demos matched (Loop-2 r02, authoritative):** `p00/revised_r02/p00b_signal_map_and_coding_demo.m` (B1a, B1b, B2, Build it) and `p00/revised_r02/p00b_softbits_and_dynamics_demo.m` (B3, B4, Build it). Worked numbers are the values these demos call "narrated" (K and E, the 24-bit CRC, the LLR example, the 120 km/h, 3 km and 300 ns defaults). Pause practice uses changed values that are not any demo Try, Stage 3a, interpretation, E1, E2 or Review answer.
- **Spec:** NARRATION SPEC in `lecture/track01/track01_narration_v1.md`, with the same two convention changes as P00a v3: pause marks name their hold and type, and answers sit under `[CHECK — after the hold]`.
- Written 2026-11-23, America/New_York. Nothing was run, recorded or sent. Album numbers are used throughout.

## Self-check map
| Pause | Beat | Kind | Hold | Practice of |
|---|---|---|---|---|
| SC-01 | S3 B1 | concept, transfer | 10 s | the order: SSB, then PDCCH, then PDSCH |
| SC-02 | S4 B2 | changed values, arithmetic | 18 s | R = K / E; CRC miss ≈ 2^−L |
| SC-03 | S6 B3 | changed values, arithmetic | 18 s | LLR = 2y / σ², sign and size |
| SC-04 | S7 B4 | changed values, multi-step | 30 s | Doppler, then coherence time, then slots |
| SC-05 | S7 B4 | changed values, arithmetic | 18 s | TA = 2d / c |
| SC-06 | S9 | spaced retrieval | 10 s | what a redundancy version chooses (from S5) |

---
## S1 Cold open (plan 14 s at 145 wpm, holds included)
[Screen] Ani at the desk. A phone icon, then four steps: find, listen, get data, report.

ANI: A phone wakes up. It must find a cell, hear instructions, get data, and report back, all on one grid. Hold this question: until it has found the cell, what can it read?

## S2 Three questions (plan 12 s at 145 wpm, holds included)
[Screen] Three headings: where, how protected, how fast. Under the first two, "signal-map-and-coding demo"; under the third, "soft-bits-and-dynamics demo" (local text).

ANI: Three questions: where each signal sits, how a block of bits is protected, and how fast the channel changes. Each idea gets a name, a meaning, and its lecture.

## S3 Beat B1: find, control, data, and the pilots (plan 73 s at 145 wpm, holds included)
[Screen] Animation A1: one downlink slot; regions highlight in narration order, then an uplink slot.

ANI: The synchronization signal block, S S B, is found first: it gives the cell's identity and timing, and without timing no symbol can be located. Lecture 03. The control channel, P D C C H, tells each phone where its data is: lecture 15. The shared data channel, P D S C H, carries the data: lecture 05.

Then pilots, known signals for measuring. The demodulation reference signal, D M R S, sits inside the data block: lecture 07. C S I R S is sent down, so the phone can measure and report. The sounding reference signal, S R S, is sent up, so the base station can measure. Both, lecture 10.

[PAUSE — self-check · hold 10 s · concept, transfer] A phone has the S S B but hasn't read any P D C C H yet. Can it find its own data? Why, or why not?

[CHECK — after the hold]
ANI: Not yet. The control channel is what tells it where its data is.

## S4 Beat B2: the coding chain (plan 89 s at 145 wpm, holds included)
[Screen] Animation A2: the five-stage chain; then equation card EQ-01 with the narrated example and the CRC scale.

ANI: Five steps protect a block. A C R C, cyclic redundancy check, to detect errors. A channel code, L D P C for data and polar for control, to correct them. Rate matching, to read exactly E bits from a circular buffer. Scrambling, so a neighbour cell's interference looks like noise. Then modulation.

The code rate R is information bits K over sent bits E. Worked example: one thousand over two thousand is one half.

A C R C detects but never corrects, and a pass is likely right, not certainly right. An L-bit C R C misses about one random error pattern in two to the L: for twenty-four bits, one in sixteen point eight million.

[PAUSE — self-check · hold 18 s · changed values, arithmetic] K is three thousand and E is four thousand: what's the code rate? And about how often does a sixteen-bit C R C miss a random error pattern?

[CHECK — after the hold]
ANI: Three quarters. And about one in two to the sixteen: one in sixty-five thousand five hundred thirty-six. Lecture 04 teaches both.

## S5 Beat B2: the circular buffer (plan 20 s at 145 wpm, holds included)
[Screen] Animation ANIM-P00b-e "Ten-entry ring": a ring of ten numbered entries; a read arc starts at entry eight and wraps.

ANI: The circular buffer reads as if its end joins its start. The redundancy version, R V, picks the start point, so a retransmission can send bits the first one skipped. Worked example: ten entries, start at entry eight, read five. That's eight, nine, ten, one, two. Lecture 05.

## S6 Demo bridge: signal map and coding (plan 12 s at 145 wpm, holds included)
[Screen] M's recording of `p00b_signal_map_and_coding_demo`: the Build it Problem text, then Stage 3a and Stage 3b with their blanks unfilled. No role table, RE-count table, toy-chain table or check output on screen.

ANI: In the signal-map demo's Build it, Stage 3a asks for the last position read. Use the wrap rule; its start counts from zero. A pass locks your prediction.

## S7 Beat B3: soft bits (plan 80 s at 145 wpm, holds included)
[Screen] Animation A3: a number line with zero at the center; an LLR marker moves along it. Then equation card EQ-02.

ANI: A hard decision says zero or one; a soft decision adds how sure. The log-likelihood ratio, L L R, is the log of how well bit zero explains the received value, over how well bit one does. Its sign is the guess; its size, the confidence. Zero is sent as plus one, so positive means zero. For B P S K in Gaussian noise, the L L R is two y over sigma squared: twice the received value over the noise variance.

Worked example: y of point four and a variance of point five give one point six. Positive, so the guess is zero, with modest confidence.

[PAUSE — self-check · hold 18 s · changed values, arithmetic] Now y is minus point three, and the variance is point six. What's the L L R, and what's the guess?

[CHECK — after the hold]
ANI: Minus one. Negative, so it guesses one, and less surely than before. Lectures 04 and 07 feed these to the decoder.

## S8 Beat B4: time, distance, and change (plan 151 s at 145 wpm, holds included)
[Screen] Animations ANIM-P00b-a to -d in narration order, with worked-example cards.

ANI: Doppler shift is speed times carrier frequency, over the speed of light. Coherence time, how long the channel stays about the same, is roughly point four two three over the Doppler shift. That's a convention.

Worked example: one hundred twenty kilometers an hour is thirty-three point three meters a second. Times three point five billion, over three hundred million, gives a Doppler shift of about three hundred eighty-nine hertz. Point four two three over that is about one point one milliseconds. A thirty kilohertz slot is half a millisecond, so about two slots stay coherent. Lecture 06.

Coherence bandwidth is roughly one over five times the R M S delay spread. At three hundred nanoseconds, that's about six hundred sixty-seven kilohertz.

Time division duplex, T D D, shares one frequency in turns, so after calibration the channel measured one way serves the other: reciprocity. Frequency division duplex, F D D, uses two frequencies and doesn't get it free. Lecture 10.

Timing advance makes the phone transmit early by the round trip, two d over c. At three kilometers, that's twenty microseconds. Lecture 13.

[PAUSE — self-check · hold 30 s · changed values, multi-step] Same carrier, but thirty-six kilometers an hour. About how many thirty kilohertz slots stay coherent?

[CHECK — after the hold]
ANI: Thirty-six kilometers an hour is ten meters a second, which gives about one hundred seventeen hertz, so a coherence time of just over three and a half milliseconds: about seven slots.

[PAUSE — self-check · hold 18 s · changed values, arithmetic] What timing advance does a phone one and a half kilometers away need?

[CHECK — after the hold]
ANI: Ten microseconds.

## S9 Demo bridge: soft bits and dynamics (plan 13 s at 145 wpm, holds included)
[Screen] M's recording of `p00b_softbits_and_dynamics_demo`: the Build it Problem text, then Stage 3a and Stage 3b with their blanks unfilled. No results table, figure or check output on screen.

ANI: In the soft-bits demo's Build it, Stage 3a asks for the first L L R. Its check uses the two likelihoods, a different route, and a pass locks your prediction.

## S10 Retrieval (plan 20 s at 145 wpm, holds included)
[Screen] Self-check card on a plain background. No recap lines on screen.

[PAUSE — self-check · hold 10 s · spaced retrieval] From earlier in this lecture, no looking back: what does a redundancy version choose?

[CHECK — after the hold]
ANI: Where in the circular buffer a transmission starts reading.

## S11 Recap (plan 31 s at 145 wpm, holds included)
[Screen] Ani, close-up.

ANI: Keep these. S S B first; then control, data with D M R S, C S I R S down, S R S up. The chain: C R C, code, rate matching, scrambling, modulation; rate is K over E. L L R: sign is the guess, size the confidence. Coherence time about point four two three over Doppler; coherence bandwidth about one over five delay spreads. Timing advance, two d over c. Next, lecture 01.

---
## Notes for Showrunner
- Objectives 7–13 are covered, each with a worked number and changed-values practice, except: coherence bandwidth and TDD/FDD stay a worked number or a definition (preview level, per P00_SPEC), and the circular-buffer read gets its changed-values practice in the demo's Stage 3a.
- CORESET and RNTI are no longer spoken (not in the r02 map demo; D7 load). PDCCH still points to lecture 15.
- New spoken items: the 300 ns coherence-bandwidth example (the soft demo checks a "narrated" value that v1 never said), the calibration caveat on TDD reciprocity (r02 Common mistakes), the likelihood wording of the LLR (r02 Key relationships and Stage 3a check), and the ten-entry circular-buffer worked example.
- The CRC scale now says "about one in sixteen point eight million", as the demo prints (v1 said seventeen million).
