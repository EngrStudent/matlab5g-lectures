# Track 07 "Learn the Channel": Ani's lecture narration (Writer, DRAFT v2)

- **Spoken words:** 1,322 (1,196 narration plus 126 read-aloud self-check questions; hyphenated words counted as parts). **Est. read time:** 8.8 min at 150 wpm, or about 9.6 min with about 10 s of silence at each of the 5 self-check pauses.
- **Budget (TIME_BUDGETS_v2, track 07):** min 6, typical 10, max 14 min. v2 runs 9.6 min with pauses: above the floor, 0.4 min under typical, under the ceiling.
- **Spec:** NARRATION SPEC at the top of `lecture/track01/track01_narration_v1.md` (voice, structure, fill rules, spoken form, notation, numbering, count method).
- **Sources read:** `track07/track07_lyrics_prelim.md` (certified box, formerly T06, with 'the ratio' chorus), `lecture/track07/` demo_plan, demo.m, lecture_notes; `pedagogue/T07_DFMEA.md`, FIXES_v1, DECISIONS, TIME_BUDGETS_v2.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent. Album numbers are used throughout (RENUMBER_MAP.md).

## Self-check map
- F2/F3: the lecture 06 recall pause (S2).
- F5: the pilot-density Try (S3) and the per-RE error-vs-|H| plot (S5).
- F8: the data-RE vs pilot-RE grade pause and the ZF/MMSE commit (S4, S5).
- F6: the corrected B4 decode plus a wrong-nVar pause (S6).

---
## S1 Cold open (target 30 s)
[Screen] Ani at the desk.

ANI: "The grid went out clean, and it came back bent." "Every tone got a gain and a twist on the way." To undo that, the receiver first has to measure it. Today we estimate a channel from a handful of known symbols, then undo it without making the noise worse.

## S2 Concept: why the receiver needs H (target 110 s)
[Screen] A clean QPSK constellation, then the same constellation rotated and scaled differently on each tone.

ANI: In lecture 02, a channel whose echoes fit inside the prefix became one complex gain per tone. Call that gain H. Lecture 06 gave us the channel models that produce it. Here they're simply some multipath; the setup lines in this demo are marked as a black box.

[PAUSE — self-check] Recall from lecture 06: compared with thirty nanoseconds of delay spread, what does three hundred nanoseconds do to H from one tone to the next?

ANI: It makes H change faster across frequency. That's why this demo uses a long delay spread: it gives the equalizers some deep fades to fight.

Why measure H at all? Without it, every tone's constellation arrives rotated and scaled by a different amount, so a fixed decision grid fails. Detecting symbols against a known reference phase is called coherent detection, and it needs H.

"The sender plants symbols you already know: the demodulation reference signals." Lecture 05 placed them. "At those spots, what you receive is the channel times the known pilot, plus noise." "Divide what you got by what was sent, and you have a raw guess of the channel there." That raw ratio is often called the least squares estimate. We use that as a lecture name; the toolbox page doesn't state which estimator it uses internally.

## S3 Code beat B1: pilots and the raw ratio (target 120 s)
[Screen] Demo section B1: the raw-ratio scatter.

ANI: The demo builds a fifteen kilohertz, fifty-two block carrier with a Q P S K shared channel on symbols two to thirteen, and one additional reference symbol. It maps the pilots and data, runs them through a T D L C channel at three hundred nanoseconds delay spread with twelve decibels of noise, and demodulates. Then it divides the received pilots by the known ones.

Worked example, for the first learning goal. Say the known pilot is point seven plus point seven j, and you receive minus point seven plus point seven j. Divide: the ratio is exactly j. On that tone the channel kept the size and turned the symbol a quarter turn, ninety degrees.

On screen, the raw ratios form a noisy cloud. There's one per pilot, and the pilots are sparse. With this reference type, every other subcarrier on two symbols: fifty-two blocks times six times two, six hundred twenty-four pilot resource elements, out of a grid of more than eight thousand.

[PAUSE — self-check] The Try line changes the number of additional reference symbols to zero, then to two. Predict which way the pilot count moves each time, and in which direction, time or frequency, the pilots get denser.

ANI: Zero drops it to three hundred twelve; two raises it. More reference symbols add pilots in time. Halving the resource blocks wouldn't make the pilots sparser in frequency. It only narrows the band, because pilot density per block is fixed by the reference signal type.

## S4 Code beat B2: average, interpolate, grade (target 140 s)
[Screen] Demo section B2: interpolated estimate against the perfect channel.

ANI: "Raw guesses are noisy, so average neighbours first." "N R Channel Estimate takes an averaging window," "F pilots wide in frequency and T pilots wide in time, odd numbers both." "Leave them at zero, and it picks the window from its own noise estimate." Then it interpolates across frequency and time to cover the whole grid, and returns the estimate and a noise variance.

"Here's the rule that holds: averaging only helps while the channel stays nearly flat across the window." "Past that, the average smears away the very channel it was meant to find."

Worked example, for the second learning goal. A common rule of thumb, from the map-of-the-link lecture, puts coherence bandwidth at about one over five times the delay spread. At three hundred nanoseconds that's about six hundred sixty-seven kilohertz. Pilots here sit every thirty kilohertz, so a window fifteen pilots wide spans four hundred fifty kilohertz. That's most of a coherence bandwidth: averaging that wide begins to blur the channel itself.

Now grade it. N R Perfect Channel Estimate builds the true channel from the model's path gains and path filters, with the same timing offset. The demo prints the R M S error of the estimate against that truth twice: on the data resource elements and on the pilot resource elements alone.

[PAUSE — self-check] Which of those two error numbers should you trust, and why might the other look better than it is?

ANI: Trust the data resource elements. Those are the ones you equalize. The pilot-only score hides the interpolation error between pilots. That's the third learning goal: grade the practical estimate against the true channel, where it matters.

## S5 Code beat B3: zero forcing versus MMSE (target 140 s)
[Screen] Demo section B3: printed EVMs, then the per-RE error against |H| plot.

ANI: "Now undo it. Zero forcing just divides by the channel." "But here's the counterexample: on a tone in a deep fade, the channel is almost zero," "and dividing by almost zero blows the noise up to the sky."

Minimum mean square error equalization, M M S E, backs off. In its textbook scalar form, it multiplies by the conjugate of the channel over the channel's power plus the noise variance. N R Equalize MMSE documents its inputs and outputs, not its exact formula, so the demo compares results, not algebra.

Worked example, for the fourth learning goal. Take a deeply faded tone with channel magnitude point one, and noise variance point zero five. Zero forcing applies a gain of one over point one, which is ten, so the noise power on that tone goes up a hundred times. M M S E applies point one, over the quantity point zero one plus point zero five: about one point seven. On a strong tone with magnitude one, zero forcing applies one and M M S E applies about point nine five. Nearly the same. M M S E only differs where the channel is weak.

[PAUSE — self-check] Before the next line prints: at twelve decibels on this channel, which equalizer gives the lower E V M?

ANI: M M S E, on average. The plot shows where: per resource element error against channel magnitude, and the zero forcing errors climb steeply at the left, in the fades. If a particular draw has no deep fades, the two come out close, and the script tells you so. The Try line raises the signal-to-noise ratio to twenty-two decibels: watch the gap shrink, because the noise variance term stops mattering.

## S6 Code beat B4: soft bits out (target 90 s)
[Screen] Demo section B4: bit-error counts and the LLR histogram.

ANI: The decoder doesn't want equalized symbols. It wants soft bits, the log-likelihood ratios from lecture 04. N R PDSCH Decode takes the M M S E output plus the noise variance and returns them. The demo then weights each soft bit by the equalizer's reliability output, so bits from faded resource elements carry less confidence.

The data here is random bits standing in for a coded block, so the script counts raw bit errors. It asserts that equalized soft bits beat decoding the unequalized symbols, which is the mistake to avoid. The histogram shows two clusters, one for each bit value, with faded resource elements near zero.

[PAUSE — self-check] The Try line passes a noise variance ten times too small. Predict what happens to the average size of the soft bits, and to the bit-error count.

ANI: The soft bits get larger: the decoder becomes overconfident. The hard decisions, and so the bit-error count, barely move. The damage shows up later, in the decoder, which trusts bad bits too much.

## S7 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Four steps to keep. Known pilots give a raw ratio, received over sent. Average while the channel stays nearly flat across the window, then interpolate to every data resource element, and grade the estimate there. Equalize with M M S E, which backs off in fades where zero forcing amplifies noise. Then pass reliability-weighted soft bits to the decoder. The full-link lectures reuse this chain. Run a slot through the channel, estimate it, and compare both equalizers.

---
## Notes for Showrunner
- v2 (Pedagogue review, FIX 1): the MMSE worked example now says "over the quantity" so the denominator can't be misheard; header recounted with the reviewer's method.
- The demo's B2 uses the default averaging window only. The plan's [0 0] vs [15 3] table is not in the code, so the window is taught in speech plus the coherence-bandwidth example.
- 'Least squares' and the MMSE formula are stated as lecture names, not as toolbox internals (VERIFY in the demo).
- The track title phrase and the chorus/L64 lines are not spoken or quoted (avoid list).
