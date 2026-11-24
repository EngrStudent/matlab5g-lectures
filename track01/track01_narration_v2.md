# Track 01 "Two to the Mu": Ani's lecture narration (Writer, DRAFT v2)

- **Spoken words:** 1,614 (1,464 narration plus 150 read-aloud self-check questions; hyphenated words counted as parts). **Est. read time:** 10.8 min at 150 wpm, or about 11.9 min with about 10 s of silence at each of the 7 self-check pauses.
- **Budget (TIME_BUDGETS_v2, track 01):** min 6, typical 10, max 15 min. v2 runs 11.9 min with pauses: above the floor, 1.9 min over typical, under the ceiling.
- **Path:** `lecture/track01/track01_narration_v2.md` (v1 kept unchanged). v2 applies the Pedagogue review (S7 preview pointer).
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent.

## NARRATION SPEC (reuse for the batch)
1. **Voice.** Ani (she/her), calm, a straight teaching read. No breathy cues, held vowels, singing or whispering. Clean/PG for adult learners. No new lore or characters. No certification or endorsement claims.
2. **Sources.** Each track uses its demo plan (latest, retimed), `trackNN_demo.m`, its lecture notes, its DFMEA, `pedagogue/FIXES_v1.md`, `pedagogue/DECISIONS.md` and `pedagogue/TIME_BUDGETS_v2.md`. MATLAB facts must match the plan and the post-fix demo (R2024a+ baseline, no fallbacks).
3. **Structure.**
   - Order: S1 cold open, then the concept, then code beats B1..Bn in demo order with the plan's animation segments in place, then the recap.
   - Recap: 30–45 s. Track 15 gets an S6 album recap of 60–90 s, and its S7 outro is a separate segment.
4. **Fill rules (TIME_BUDGETS_v2).**
   - Define each untaught or local term in one line where it is first used.
   - Give one worked numerical example per learning goal, using numbers the demo prints.
   - Put one `[PAUSE — self-check]` with a question at each critical DFMEA finding (RPN above 100). An answer line follows where the pause has a definite answer.
   - No padding. Aim at typical, never go under min, and run nearer the floor if the substance runs out.
5. **Spoken form.**
   - Write numbers and symbols the way they are read aloud.
   - Say function names as spaced letters ("N R Carrier Config").
   - Read acronyms letter by letter on first use (R B, P D S C H, F F T).
6. **Notation.**
   - On-screen equations in `[Screen]` cues use the Greek μ. Spoken text says "mu".
   - Quoted lyrics use straight quotes and are verbatim from the certified box, in the certified spelling "mu". Never quote a delivery-note line or an AVOID or survivor line.
7. **Numbers.** Use new album numbers throughout (D2 renumber). Forward references name the new lecture number.
8. **Header and count.**
   - Each file opens with spoken word count and est. minutes at 150 wpm.
   - Count `ANI:` text plus pause questions. Exclude headings and `[Screen]` cues. Count hyphenated words as their parts (Pedagogue's method, from v2 on).
   - Report time with and without about 10 s of silence per pause.

## Critical-finding map (track01_dfmea_review.md; K = 7)
| DFMEA | Where handled |
|---|---|
| F1 trade-off (120) | S2 "why bigger / smaller mu" + pause; numbers in S8 |
| F8 no commit point (240) | S3 predict-and-write pause at 30 kHz |
| F2 prereq / sample counts (280) | S4: durations only; sample counts sent to the grid and waveform lecture (P00a); pause on prefix samples vs time |
| F5 representation (168) | S5/S6: mu = 4 tile called synchronization-only; pause on "more REs?" |
| F6 transfer (180) | S3 Try names muList/cpList/nrbList; S6 5.76 MHz prediction pause; S7 warning, not crash |
| F3 ordering (192) | S2 defines RB; S7 defines bandwidth part and labels PDSCH/DM-RS a preview (taught in 05/07); pause on "what this beat tests" |
| F4 load (144) | S4 split (core durations, sample aside named only); S7 Nfft-doubling pause |

---
## S1 Cold open (target 25 s)
[Screen] Ani at the desk. A blank grid sketch on paper.

ANI: Draw a grid. Time runs left to right, frequency climbs the page, and one square is one tone for one symbol. 5G calls that square a resource element. Today's question is simple. What happens to this grid when you double the spacing between the tones? By the end, you'll answer that before MATLAB does.

## S2 Concept: one knob called mu (target 100 s)
[Screen] The equation SCS = 15 kHz × 2^μ builds on screen.

ANI: New Radio shapes its grid with one setting, called the numerology. Its symbol is the Greek letter mu, and it's a whole number. The subcarrier spacing, which I'll call S C S, is fifteen kilohertz times two to the mu. So mu zero through four give fifteen, thirty, sixty, one hundred twenty, and two hundred forty kilohertz.

Two grid words before we start. Twelve subcarriers stacked together make a resource block, or R B. The carrier's height in resource blocks is a property called N Size Grid, so the grid is twelve times N Size Grid subcarriers tall.

In time, a frame is ten milliseconds, a subframe is one millisecond, and both are fixed. A slot is fourteen symbols with the normal cyclic prefix. The only thing mu changes in time is how many slots fit in one millisecond. The song puts it in one line: "Two to the mu slots in every millisecond,".

Why would an engineer want a bigger mu? Shorter slots mean lower latency, and wider tones tolerate Doppler shift and oscillator phase noise, which matters at millimeter-wave frequencies. Why want a smaller mu? Because the cyclic prefix, the guard time at the start of each symbol, shrinks with the slot, and a longer prefix absorbs longer echoes. We'll put numbers on that trade-off near the end.

[PAUSE — self-check] Before the next segment, say it in one sentence: what do you gain by raising mu, and what do you give up?

## S3 Code beat B1: read it back (target 120 s)
[Screen] M's recording of demo section B1. Pause on SubcarrierSpacing = 30 before the row prints.

ANI: Here's the sweep. For each mu, the script builds an N R Carrier Config and reads back Symbols Per Slot, Slots Per Subframe, and Slots Per Frame. It asserts two to the mu slots per subframe, and ten times that per frame.

[PAUSE — self-check] Thirty kilohertz. Write down your prediction for Slots Per Subframe, and why, before you resume.

ANI: Thirty is fifteen times two, so mu is one, and two to the one is two. The lyric says it plainly: "It tells you two. Did you guess two?"

Worked example, for the first learning goal. Take mu three. Spacing is fifteen times two cubed, which is fifteen times eight, one hundred twenty kilohertz. Slots per subframe is eight. Slots per frame is ten times eight, eighty. At fourteen symbols per slot, that frame holds one thousand one hundred twenty symbols. Check that row on screen.

Two rows are special. The extended prefix row, allowed only at sixty kilohertz, prints twelve symbols per slot. The mu four row, at two hundred forty kilohertz, is in the table for the arithmetic only. In New Radio that spacing carries synchronization blocks, not user data.

To try a mu five row, edit mu list, C P list, and N R B list together. The spacing is computed from mu list, so editing Subcarrier Spacing alone does nothing.

## S4 Code beat B2: why the slot shrinks (target 120 s)
[Screen] Demo section B2, the timing table, then animation A2.

ANI: Why does the slot shrink? Neighboring tones stay orthogonal, meaning they don't interfere, when they complete a whole number of cycles relative to each other over one symbol. The closest spacing that works is exactly one cycle apart, so the useful part of the symbol lasts one over the spacing.

At fifteen kilohertz that's sixty-six point seven microseconds. Every step of mu halves it.

The cyclic prefix scales by the same factor. At fifteen kilohertz the ordinary prefix is about four point six nine microseconds, so symbol plus prefix is about seventy-one point four, and fourteen of those fill one millisecond. Because the symbol and the prefix both shrink by two to the mu, the slot does too.

Worked example, for the second learning goal. At mu two, sixty kilohertz, the slot lasts one millisecond over two squared, which is one millisecond over four, or two hundred fifty microseconds. The script asserts that every slot equals one millisecond over two to the mu.

One small detail makes the clock land clean. Seven ordinary symbols come up a little short of half a millisecond, so the first symbol of each half millisecond gets a slightly longer prefix to make up the difference. The sample-count version belongs to the grid and waveform lecture. Here we stay with durations, which is why the script compares times, not raw sample counts. Printed prefix lengths in samples depend on the F F T size the toolbox picks for your carrier.

[PAUSE — self-check] A wide carrier at fifteen kilohertz prints prefix lengths in samples that are twice the reference values. Has the prefix time changed? Answer, then resume.

ANI: No. The sample rate doubled, so twice the samples still span the same microseconds.

## S5 Animation A1: same box, new shape (target 50 s)
[Screen] Animation A1, the counter holding at 2688.

ANI: Now hold a box, one millisecond wide and B hertz tall. In frequency, you get B over the spacing subcarriers. In time, you get fourteen times two to the mu symbols. Multiply them. The spacing is fifteen kilohertz times two to the mu, so the two to the mu on top cancels the two to the mu underneath. What's left is fourteen times B over fifteen kilohertz, with no mu in it at all. In the song's words: "The box doesn't grow. It only changes shape."

[PAUSE — self-check] If you raise mu by one step, does the same bandwidth for the same millisecond hold more resource elements, fewer, or the same? Decide, then resume.

## S6 Code beat B3: count the squares (target 100 s)
[Screen] Demo section B3, five checkerboard tiles with white slot lines.

ANI: The demo uses a box two point eight eight megahertz tall. That's our worked example for the third goal.

At mu zero, two point eight eight megahertz over fifteen kilohertz is one hundred ninety-two subcarriers, which is sixteen resource blocks. In one millisecond there are fourteen symbols. One hundred ninety-two times fourteen is two thousand six hundred eighty-eight resource elements.

At mu four, the spacing is two hundred forty kilohertz, so there are just twelve subcarriers, one resource block. But there are fourteen times sixteen, two hundred twenty-four symbols. Twelve times two hundred twenty-four is again two thousand six hundred eighty-eight.

On screen, the tiles go from tall and narrow to short and wide, and the white lines mark slot boundaries. The mu four tile is labeled synchronization-only, shown for the math. The assert checks two thousand six hundred eighty-eight every time.

[PAUSE — self-check] Change the box height to five point seven six megahertz. Predict the resource element count before you run it.

ANI: Twice the bandwidth, so twice the count: five thousand three hundred seventy-six, at every mu.

## S7 Code beat B4: one real frame (target 125 s)
[Screen] Demo section B4, the labeled frame map with slot lines and bandwidth-part edges.

ANI: Last, a real frame, using the fourth learning goal: confirm the numbers with N R Carrier Config, N R Resource Grid, and N R O F D M Info. The carrier is thirty kilohertz and fifty-one resource blocks, so N R Resource Grid hands back zeros, six hundred twelve subcarriers by fourteen symbols.

This beat contains a preview. To fill the grid with something visible, the script maps the shared data channel, called P D S C H, and its demodulation reference signal, called D M R S, into a bandwidth part. A bandwidth part is just a block of the carrier's resource blocks that a device is set up to use. Here it is twenty-four blocks, starting at block ten. Both are taught in lecture 05, which also places the D M R S on the grid; lecture 07 then estimates the channel from it. Today, read the colored squares as "something occupies these resource elements."

[PAUSE — self-check] Without the channel names, what does this beat actually test? Say it in your own words, then resume.

ANI: It tests the frame count. At mu one there are ten times two, twenty slots per frame, so the script fills twenty slots and O F D M modulates the whole frame. The worked example: the toolbox's default F F T size for this carrier is one thousand twenty-four, and one thousand twenty-four times thirty kilohertz is a sample rate of thirty point seven two megahertz. Times ten milliseconds, that's three hundred seven thousand two hundred samples.

The script asserts that the waveform lasts exactly ten milliseconds. The specific three hundred seven thousand two hundred figure is a printed comparison. If your release picks a different F F T size, you get a warning, not a crash, and the plot still draws.

[PAUSE — self-check] If you widened the carrier until the default F F T size jumped to two thousand forty-eight, what would the frame sample count become?

ANI: It doubles, to six hundred fourteen thousand four hundred. The frame is still ten milliseconds. As the song says, "If you predicted it, you own it."

## S8 Animation A3: the price of wide spacing (target 50 s)
[Screen] Animation A3, an echo pulse against a prefix bar.

ANI: So why not always go wide? An echo that arrives later than the prefix spills into the next symbol. Multiply prefix time by the speed of light to get distance. Four point six nine microseconds times three hundred million meters per second is about fourteen hundred meters of extra path. At one hundred twenty kilohertz the prefix is eight times shorter, about six hundred nanoseconds, which covers under two hundred meters. "Short slots buy you latency. Long prefix buys you reach."

## S9 Recap (target 40 s)
[Screen] Ani, close-up talk.

ANI: Three things to keep. Spacing is fifteen kilohertz times two to the mu. A slot is fourteen symbols, so it lasts one millisecond over two to the mu, while the subframe and frame stay fixed. And a fixed box of time and bandwidth holds the same number of resource elements at every mu. Wider spacing buys latency and robustness, and a longer prefix buys reach. Open the demo, change one number, and predict the table before it prints.

---
## Notes for Showrunner
- **Learning goals.** All four are covered. LG1 is worked with mu 3, LG2 with mu 2 (250 µs), LG3 with 2.88 MHz at mu 0 and mu 4 (2688), and LG4 with the 51 RB frame (307200).
- **Lyric quotes.** These are verbatim from the certified box: L26, L17, L54, L88 and L74. L20 is not quoted.
- **Track 01 DFMEA file.** `lecture/pedagogue/T01_DFMEA.md` does not exist. I used `lecture/track01/track01_dfmea_review.md` instead, which SYSTEM_DFMEA also names as T01's source.
- **Demo plan vs post-fix demo.** The plan's S3–S7 text predates C1/C2/C5/C6. This narration follows the post-fix demo:
  - durations only in B2;
  - B4 as a preview;
  - the 307200 check printed with a warning;
  - the mu 4 tile marked as synchronization-only.
- **Cut candidates if typical (10 min) is required.**
  - The S4 prefix-samples pause and its answer, about 25 s.
  - The S6 5.76 MHz pause, about 20 s.
  - The S8 distance worked numbers (they repeat the song), about 20 s.
- **v2 (Pedagogue review, FIX 1):** the S7 preview now says P D S C H and D M R S placement are both lecture 05, and lecture 07 estimates from the D M R S.
- **Unrun.** None of the MATLAB was run, so every printed value is still unverified until M runs the demo on R2024b.
