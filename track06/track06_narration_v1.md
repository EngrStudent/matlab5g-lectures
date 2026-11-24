# Track 06 "Taps in Time": Ani's lecture narration (Writer, DRAFT v1)

- **Spoken words:** 1,296 (1,149 narration plus 147 read-aloud self-check questions). **Est. read time:** 8.6 min at 150 wpm, or about 9.5 min with about 10 s of silence at each of the 5 self-check pauses.
- **Budget (TIME_BUDGETS_v2, track 06):** min 6, typical 11, max 16 min. About 1.6 min under typical; no padding (5 LGs, 1 term).
- **Spec:** NARRATION SPEC at the top of `lecture/track01/track01_narration_v1.md` (voice, structure, fill rules, spoken form, notation, numbering, count method).
- **Sources read:** `track06/track06_lyrics_prelim.md` (certified box, formerly T07), `lecture/track06/` demo_plan, demo.m, lecture_notes; `pedagogue/T06_DFMEA.md`, FIXES_v1, DECISIONS, TIME_BUDGETS_v2.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent. Album numbers are used throughout (RENUMBER_MAP.md).

## Self-check map
- F2: the one-line fading model (S2).
- F3: coherence time is defined; 'stale within about a slot' (S5, S6).
- F5: the 5 vs 300 Hz fading plot (S5).
- F6: the normDiff note and the reuse-gap prediction (S3, S6).
- F8: the TDL-C prediction, the f_D/T_c commit, and a no-answer exercise (S4, S5, S6).

---
## S1 Cold open (target 30 s)
[Screen] Ani at the desk.

ANI: "One signal leaves the tower." "It reaches you many times: off buildings, off hills, off the road." "Every copy is late, and every one has its own strength." Today we model that with a short list of taps, test one assumption most people get wrong, and work out how fast the whole picture changes when you start moving.

## S2 Concept: tapped delay line (target 130 s)
[Screen] Tap diagram.

ANI: In lecture 02, every echo had to fit inside the cyclic prefix. That raises the obvious question: how long are real echoes, and how strong? A channel model answers it in a form you can test against.

"A tapped delay line writes the whole mess as a short list of taps." "Each tap is a delay and an average power, and each one fades on its own." The model is called T D L.

Fading needs a one-line model, so here it is. Each tap is a random complex gain. Its average power is the number in the table, but any single moment can be stronger or weaker as the paths that make up the tap add and cancel. Those moment-by-moment values are the path gains.

"Three G P P gives five shapes, A through E." "A, B and C have no line of sight. D and E do," "and their first tap carries a steady direct path on top of the fading." "The table lists the delays in units of the delay spread." The delay spread is the root mean square spread of all the arrivals, weighted by power. That's the first learning goal: a T D L model is a list of taps, each a delay, an average power, and its own fading.

## S3 Code beat B1: scale it (target 120 s)
[Screen] Animation A1, then demo section B1.

ANI: So what sets the actual time? "Multiply every normalized delay by the delay spread," "and the shape stays the same, only the time stretches."

The demo builds an N R TDL Channel with profile T D L A at thirty nanoseconds, the default, then at three hundred. It reads the delays and powers from the channel's info function. One detail: the path delays and average path gains properties you can set directly apply only to a custom profile. For a named profile, read them from info.

Worked example, for the second learning goal. T D L A's last tap is at nine point six five eight six delay spreads. At thirty nanoseconds that's about two hundred ninety nanoseconds. At three hundred nanoseconds it's about two point nine microseconds. The script asserts that delay over delay spread is identical for both. It compares the normalized delays directly, because T D L A's first delay is zero and dividing by it would fail.

[PAUSE — self-check] The prefix at fifteen kilohertz is about four point seven microseconds. Which of the two settings still fits all of T D L A inside it? Convert before you compare.

ANI: Both. Two point nine microseconds is still inside four point seven. At fifteen point three six megahertz, that last tap is about forty-four samples against a seventy-two sample prefix. A common mistake is comparing a delay spread in seconds with a prefix quoted in samples. Convert first: samples equal seconds times sample rate.

## S4 Animation A2 and code beat B2: the counterexample (target 120 s)
[Screen] Animation A2, then the B2 stem plot.

ANI: "You'd think the first arrival is always the loudest. Look at T D L A." "Its first tap sits at delay zero, thirteen point four decibels down." "The second tap, a little later, is the strongest of them all, at zero decibels." "Echoes don't have to fade in order."

The demo reads the average path gains and asserts three things: tap one is minus thirteen point four decibels, tap two is zero, and tap two is louder. It tests the table's averages, not one faded draw, because a single draw can briefly put the peak anywhere. That's the third learning goal. A receiver that always locks onto the first arrival would lock onto a weak one.

[PAUSE — self-check] The Try line switches the profile to T D L C. Before you run it, predict: is the first tap the loudest there? Then check the printout.

ANI: Line-of-sight profiles change the picture. For T D L D and T D L E, turning on K factor scaling puts a steady direct path in the first tap. The K factor, nine decibels by default, says how much stronger that direct path is than the scattered part. That's the fifth learning goal. This demo doesn't run a line-of-sight profile. Switching it to T D L D with K factor scaling on is a good exercise: the first tap should now stand out.

## S5 Animation A3 and code beat B3: Doppler (target 140 s)
[Screen] Animation A3, then the B3 fading traces.

ANI: "Now move. Every tap starts to fade with time." "The fastest it can swing is set by the maximum Doppler shift: speed over wavelength."

Worked example, for the fourth learning goal. Wavelength is the speed of light over the carrier frequency. At three gigahertz that's three hundred million over three billion, point one meters, ten centimeters. At thirty meters a second, about a car on a main road, the Doppler shift is thirty over point one, three hundred hertz. The toolbox default is five hertz. At this carrier that's half a meter a second, a slow walk.

Doppler sets the coherence time, from the map-of-the-link lecture: roughly how long the channel stays about the same. Using the zero point four two three convention, coherence time is point four two three over the Doppler shift. At three hundred hertz that's about one point four milliseconds, about twenty symbols at fifteen kilohertz. At five hertz it's about eighty-five milliseconds.

The figure plots the strongest tap's gain over ten milliseconds at five hertz and at three hundred. The slow trace barely moves. The fast one swings through deep fades.

[PAUSE — self-check] The Try line sets the speed to three meters a second, then thirty, at three gigahertz. Write down both Doppler shifts and both coherence times before they print.

ANI: Thirty hertz and three hundred hertz. Coherence times of about fourteen milliseconds and about one point four.

## S6 Code beat B4: shortcuts and what the estimator must track (target 110 s)
[Screen] Demo section B4.

ANI: "The test specs add shortcuts: T D L A thirty, T D L B one hundred, T D L C three hundred." "They're valid delay profiles in the toolbox too." For those, the delay spread comes with the name. These profiles are repeatable stand-ins for a measured channel. They don't carry angles; lecture 08 adds those.

Three knobs describe the channel your estimator must face: the profile, the delay spread, and the maximum Doppler shift. The demo prints all three together. "Wide delay spread makes the channel change from tone to tone." "Fast Doppler makes it change from symbol to symbol."

Then it measures the cost of standing still. It takes the path gain at symbol two and reuses it at symbol thirteen, eleven symbols later, about eight hundred microseconds. At five hertz the reuse error is tiny. At three hundred hertz, that gap is more than half a coherence time, and the error is large. So at three hundred hertz an estimate goes stale within about a slot.

[PAUSE — self-check] Change the reuse gap or the Doppler shift. Using coherence time, predict whether the reuse error will be small or large before it prints.

[PAUSE — self-check] Exercise with no answer given: at three point five gigahertz and one hundred twenty kilometers an hour, compute the Doppler shift and the coherence time. How many thirty kilohertz slots is that? Bring your answer to lecture 07.

## S7 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Four things to keep. A T D L model is a list of taps, each a delay and an average power, each fading on its own. Multiply the normalized delays by the delay spread: the shape stays, the time stretches. The first arrival isn't always the strongest, and T D L A proves it. And Doppler is speed over wavelength, with coherence time about point four two three over Doppler. Lecture 07 builds the estimator that has to keep up. Build the channel, find the strongest tap, and double the Doppler.

---
## Notes for Showrunner
- The post-fix demo has no TDL-D/K-factor code (LG5). K-factor is covered in speech, with a suggested exercise.
- Delays and powers come from info(ch), per the demo.
- L22, L73 and L74 are not quoted (avoid list).
