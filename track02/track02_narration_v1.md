# Track 02 "Copy the Tail": Ani's lecture narration (Writer, DRAFT v1)

- **Spoken words:** 1,585 (1,434 narration plus 151 read-aloud self-check questions). **Est. read time:** 10.6 min at 150 wpm, or about 11.6 min with about 10 s of silence at each of the 6 self-check pauses.
- **Budget (TIME_BUDGETS_v2, track 02):** min 8, typical 13, max 18 min. About 1.4 min under typical. Substance ran out honestly (5 LGs, 5 beats, 2 terms, 6 pauses), so no padding was added.
- **Spec:** NARRATION SPEC at the top of `lecture/track01/track01_narration_v1.md` (voice, structure, fill rules, spoken form, notation, numbering, count method).
- **Sources read:** `track02/track02_lyricbox.txt`, `lecture/track02/` demo_plan, demo.m, lecture_notes; `pedagogue/T02_DFMEA.md`, FIXES_v1, DECISIONS, TIME_BUDGETS_v2.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent. Album numbers are used throughout (RENUMBER_MAP.md).

## Self-check map
- F6: lastEcho 72/80 pause (S4).
- F8: EVM-at-25-dB commit (S6).
- F5: CP − W pauses (S5, two).
- F2: CP is not zeros (S3); circular convolution and ICI are defined.
- F4: B3 optional columns flagged (S5).
- F3: B5 preview and the SSB-on pause (S7).

---
## S1 Cold open (target 30 s)
[Screen] Ani at the desk; the empty grid from lecture 01.

ANI: In lecture 01 we built a grid of zeros. Today we make it move. Every column of that grid becomes a short burst of radio, and every burst starts with a copy of its own ending. By the end of this lecture you'll know why that one copy lets a 5G receiver undo a messy channel with a single divide per tone, and exactly when it stops working.

## S2 Concept: one IFFT per symbol (target 120 s)
[Screen] A complex number in each grid cell, then a sum of spinning phasors.

ANI: Start with the problem. A radio signal reaches the receiver along several paths: the direct one, plus echoes off buildings that arrive a little later. Those late copies smear each symbol into the next one. The cyclic prefix is how 5G makes that smear harmless.

First the waveform itself. Put one complex number on every tone in a column of the grid, then take one inverse F F T for that column. Each tone becomes a spinning wheel at its own frequency, and the waveform is all the wheels added up. That's C P O F D M: one inverse F F T per symbol, with a cyclic prefix in front.

The F F T is wider than the tones you use. The empty bins at either edge are the guard band. Worked example, for the first learning goal. At fifteen kilohertz and fifty-two resource blocks, the default F F T size is one thousand twenty-four. Twelve times fifty-two is six hundred twenty-four active tones, so four hundred bins sit quiet. The sample rate is one thousand twenty-four times fifteen kilohertz, fifteen point three six megahertz, so one ten-millisecond frame is one hundred fifty-three thousand six hundred samples.

This lecture assumes three things from the grid and waveform lecture and from basic signal processing: the discrete Fourier transform, convolution, and a root mean square.

## S3 Code beat B1: copy the tail (target 120 s)
[Screen] Demo section B1 asserts, then the one-symbol plot.

ANI: Here's N R O F D M Modulate, with windowing set to zero so we see the raw prefix. The script checks four things. One: a frame is exactly ten milliseconds of samples. Two, the heart of it: the prefix equals the tail of the symbol, sample for sample. Three: exactly six hundred twenty-four F F T bins carry energy. Four: N R O F D M Demodulate gives the grid back to one part in a billion.

On this carrier the normal prefix is seventy-two samples, and the first symbol of each half millisecond gets a long prefix of eighty. Those are the reference counts of one hundred forty-four and one hundred sixty, scaled by one thousand twenty-four over two thousand forty-eight.

[PAUSE — self-check] Is the cyclic prefix a run of zeros placed in front of the symbol? Answer before you resume.

ANI: No. It's a copy of the symbol's own tail, and that copy is what the next beat depends on.

## S4 Code beat B2, with animations A1 and A2: why a single divide works (target 170 s)
[Screen] Animation A1, then demo section B2, then animation A2.

ANI: Why copy the tail? "A channel is a convolution that spills past the end." "But when every echo is shorter than the prefix," the window the receiver keeps sees only this symbol, with its own tail wrapped back around.

That wrap-around has a name: circular convolution. It's convolution on a loop, where whatever spills off the end comes back in at the start. Its key property is that after an F F T, circular convolution becomes a plain multiply. So each tone sees the channel as one complex gain, one size and one twist. Undo it with one divide per tone.

Worked example, for the second learning goal. The demo puts a direct path at zero, plus echoes at seventeen and fifty-one samples, all inside the seventy-two sample prefix. The script measures the channel on every tone of every symbol and asserts it's identical on all one hundred forty symbols. It learns that channel once from a single known symbol, divides it out everywhere, and the error is essentially zero.

Now break it. The script moves the last echo to one hundred twenty samples, past even the long prefix. "The symbol before bleeds in, the tones leak into each other," "and no single divide fixes it." The E V M climbs well above one percent.

[PAUSE — self-check] The Try line moves that last echo to seventy-two samples, then to eighty. Predict which symbols stay clean at eighty: the long-prefix symbols, the normal ones, or neither.

ANI: At seventy-two, everything stays clean. At eighty, the echo is past the normal prefix but still inside the long one, so the long-prefix symbols stay clean and the normal ones break. The script prints those two groups separately, so you can check yourself. That's the third learning goal: an echo that outlasts the prefix breaks the one-tap model.

## S5 Code beat B3: windowing (target 120 s)
[Screen] Demo section B3: three spectra and the printed table.

ANI: Hard edges on every symbol splash energy out the sides of the band and into the neighbor's channel. The fix is windowing: round the edges off with a raised cosine and overlap each symbol with the next. The sidebands drop.

The taper isn't free. It spends samples of the prefix. The receiver starts its F F T window early to dodge the taper, so the echo margin left is about the prefix minus the window length. That's the one rule to keep from this beat: margin is about C P minus W.

The demo runs three window lengths: zero, about half the default, and the default that N R O F D M Info reports. The printed table puts the window, the margin that remains, the out-of-band power, and the echo E V M side by side, so you see both the gain and the cost. Two tools, two defaults: the waveform generator starts with windowing at zero, and the modulator takes the largest taper the three G P P E V M test allows. Some columns are marked optional; skip them on a first pass.

[PAUSE — self-check] You turned windowing up for a cleaner spectrum, and an echo that used to fit now causes errors. What did you spend?

ANI: W samples of the prefix. The margin left is the prefix minus W.

[PAUSE — self-check] The Try line sets the test echo to exactly the prefix minus the default window, then one sample past it. Which window lengths stay clean in each case? Commit, then run with strict mode on so a wrong guess stops with a message.

## S6 Code beat B4, with animation A3: measuring the damage (target 150 s)
[Screen] Demo section B4 printout, then animation A3.

ANI: To grade a waveform, take what you received minus what you sent. That difference is the error vector. "EVM is the root mean square of the error" "over the root mean square of the reference, in percent."

Here's a trap. The demo adds noise at twenty-five decibels signal-to-noise ratio, measured over the full sample rate. But "Noise lands on every bin, not just the ones you use." Only six hundred twenty-four of one thousand twenty-four bins carry signal, so the signal-to-noise per tone is better than twenty-five decibels by a factor of one thousand twenty-four over six hundred twenty-four.

[PAUSE — self-check] Before the next line prints, write down your predicted E V M at twenty-five decibels. Use that factor.

ANI: Worked example, for the fourth learning goal. Twenty-five decibels is a ratio of three hundred sixteen point two. Times one thousand twenty-four over six hundred twenty-four gives about five hundred nineteen. E V M is one hundred over the square root of that: about four point four percent. If you used one hundred over the square root of three hundred sixteen, you got five point six, and you forgot the quiet bins.

Second impairment: a frequency offset. When every tone shifts by a fraction of the spacing, the nulls no longer line up with the neighbors, and each tone leaks into the next. That leakage is inter-carrier interference, from the grid and waveform lecture. At seven hundred fifty hertz, five percent of fifteen kilohertz, and with the common phase removed, the demo's model gives about nine percent, nine point oh six to be exact. The base station limit for sixty-four Q A M in the three G P P base station specification, T S thirty-eight one-oh-four, is eight percent. So a five percent offset fails. Other things raise E V M too: phase noise, clipping, echoes past the prefix, and too much taper.

## S7 Code beat B5: end to end (target 100 s)
[Screen] Demo section B5.

ANI: Last, the full path, and the fifth learning goal: check it all with the toolbox's own generator. We build an N R D L Carrier Config, a ten megahertz downlink carrier with windowing at zero, and switch off the synchronization burst so the comparison is clean. N R Waveform Generator makes the waveform and reports the grid it sent. We demodulate with the generator's own F F T size and sample rate and compare on the occupied resource elements.

The E V M is about zero, and the frame is sample rate times ten milliseconds. This beat is a preview. The synchronization block is taught in lecture 03 and the shared data channel in lecture 05. Read the occupied cells as places the generator put something.

[PAUSE — self-check] Turn the synchronization burst back on. The occupied set no longer matches a grid you built by hand. Which one is right?

ANI: The generator. Compare against the grid it reports, because that includes every signal the configuration asked for.

## S8 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Four things to keep. One inverse F F T per symbol makes the waveform. Copying the tail in front turns every echo shorter than the prefix into one gain per tone, so one divide undoes it. Windowing cleans up the spectrum, but the echo margin drops to the prefix minus the window. And E V M grades all of it: count the quiet bins when you predict it. Lecture 06 measures real delay spread, and lecture 07 builds the one-tap equalizer properly. Run the demo, move the echo, and watch where it breaks.

---
## Notes for Showrunner
- The untaught terms (circular convolution, the TS 38.104 64-QAM EVM limit) are defined where first used.
- The B3 default window length isn't quoted, because the demo prints it.
- Lyric quotes are verbatim (L29, L30, L38, L39, L61, L62, L63).
