# Track 12 "How Far": Ani's lecture narration (Writer, DRAFT v2)

- **v2 change (Showrunner ruling, 2026-11-18):** in S6's worked example (LG5), the sign-slip line now says "about three point six kilometers of fake range" (c·t/2 for the round trip, matching the demo's d = c·sum/2), not "about seven kilometers". Nothing else changed.

- **Spoken words:** 1,749 (1,649 narration plus 100 read-aloud self-check questions). **Est. read time:** 11.7 min at 150 wpm. With about 10 s of silence at each of the 6 self-check pauses, the total is about 12.7 min.
- **Budget (TIME_BUDGETS_v2, "How Far" row):** min 7, typical 13, max 18 min. Read time is 1.3 min under typical; with pauses, 0.3 min under. Above the floor and below the ceiling. Length comes from the worked examples, the critical self-checks and the term definitions, not padding.
- **Path:** `lecture/track12/track12_narration_v2.md` (v1 kept unchanged beside it). Sources were taken from `lecture/track12/`, whose files carry the title "How Far" (RENUMBER_MAP 12 = old T11), and from `lecture/pedagogue/T12_DFMEA.md`, including its B4_REMEDIATION section (D5).
- **Format:** follows the NARRATION SPEC at the top of `scratch/narration/track01_narration_v1.md`.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent.

## Critical-finding map (pedagogue/T12_DFMEA.md; K = 6)
| DFMEA | Where handled |
|---|---|
| F5 representation (336) | S6: the fixed B4 identity gNB(Rx−Tx) + UE(Rx−Tx) = 2d/c, with the sign-slip print as the named mistake (D5 / R1–R5); pause |
| F6 transfer (252) | S4: the move-the-UE Try, with the predicted sample delays and the search-box warning; pause |
| F8 assessment (210) | S5: predict the fix shift for a 10 ns bias on tower 2 before the Try; the 1 m check called a printed check, not an assert |
| F2 prereq gap (150) | S4: one line each for fractional delay (phase ramp) and the parabolic fit; S5 defines hyperbola and DOP; pause on the parabola |
| F4 load (140) | S4: the FFT block is flagged "setup, skip on first read"; pause on what B2 actually measures |
| F3 ordering (125) | S5: "TDOA assumes synchronized towers" comes first; pause on which clock drops out |

---
## S1 Cold open (target 25 s)
[Screen] Ani at the desk. Three tower icons and a phone on a map.

ANI: Light moves about thirty centimeters every nanosecond. Measure time well enough, and you've measured distance. Today we use 5G signals from three base stations to locate a phone, and see the one thing that can fool every method.

## S2 Concept: time is distance (target 60 s)
[Screen] A ruler marked in nanoseconds and meters.

ANI: The whole lecture rests on one conversion. Distance is the speed of light times time. The speed of light is about three hundred million meters per second, so one nanosecond is about zero point three meters.

Worked example, for the first learning goal. The phone is two hundred fifty meters from the first tower. Two hundred fifty divided by the speed of light is about eight hundred thirty-four nanoseconds. The demo's sample rate is thirty point seven two megahertz, so one sample lasts about thirty-two and a half nanoseconds, and light covers about nine point seven six meters in that time. So the travel time is about twenty-five point six samples. A timing error of one whole sample is almost ten meters of range.

## S3 Code beat B1: one P R S per base station (target 120 s)
[Screen] Demo section B1, the comb image and the correlation print.

ANI: "The positioning reference signal, P R S, comes down from several base stations." Each one gets its own sequence identity, the N P R S I D, "anywhere from zero to four thousand ninety-five, so the phone can tell them apart."

In the code, the carrier is thirty kilohertz with fifty-one resource blocks. N R OFDM Info reports the sample rate, and the first print gives thirty point seven two megahertz and nine point seven six meters per sample. Then, for N P R S I D zero, one and two, the script builds an N R PRS Config with Comb Size four, twelve P R S symbols and fifty-one resource blocks. N R PRS Indices places the symbols, N R PRS makes them, and each goes onto its own grid.

Worked example, for the second learning goal. Fifty-one blocks is six hundred twelve subcarriers. A comb of four keeps one in four, a hundred fifty-three per symbol. Over twelve symbols, that's one thousand eight hundred thirty-six resource elements for each identity. All three use the same positions. What differs is the content. The script prints the normalized correlation of each sequence with the first: about one with itself, and small with the other two. That's how the phone tells tower one from tower two. Try Comb Size six: a hundred two per symbol.

Why fifty-one blocks and not five? A wider signal gives sharper timing. The correlation peak gets narrower as the bandwidth grows. Fifty-one blocks of twelve subcarriers at thirty kilohertz span about eighteen point four megahertz. As a rough scale, one over that is about fifty-four nanoseconds, or about sixteen meters, before any sub-sample refinement. Halve the bandwidth and that scale doubles.

## S4 Code beat B2: delay, sum, estimate (target 170 s)
[Screen] Demo section B2. The FFT block is shaded "setup, skip on first read".

ANI: The scene: the phone sits at two hundred, one hundred fifty meters. The towers are at the origin, at five hundred zero, and at zero five hundred. The true ranges print as two hundred fifty, three hundred thirty-five point four one, and four hundred three point one one meters. That's twenty-five point six two, thirty-four point three seven, and forty-one point three one samples. None of them is a whole number.

To delay a waveform by a fraction of a sample, the script uses a fractional delay, meaning a delay that isn't a whole number of samples. A delay tau is a linear phase ramp in frequency, e to the minus j two pi f tau, so the script takes an F F T, multiplies by that ramp, and transforms back. The upper half of the frequencies is wrapped to negative values so the ramp is a real delay. That block is setup. Skip it on a first read. It just builds a received signal, r x, the sum of the three delayed towers.

Then, for each tower, N R Timing Estimate takes the carrier, r x, and that tower's P R S indices and symbols. It returns off, a whole-sample offset, and mag, the magnitude of the correlation.

Worked example, for the third learning goal. Tower one's true delay is twenty-five point six two samples. A whole-sample answer can be off by up to half a sample, which is about four point nine meters. So the script refines it with a parabolic peak fit, meaning it fits a parabola through the peak and its two neighbours. If the neighbours have magnitudes zero point six and zero point eight around a peak of one, the formula, one half times the left minus the right, over the left minus twice the peak plus the right, gives plus zero point one seven samples, toward the stronger neighbour. The fit itself is the plan's method, not a MathWorks page, and it can leave a bias of about a tenth of a sample, about one meter.

[PAUSE — self-check] Why does the parabola move the estimate toward the larger neighbour, and not away from it?

ANI: The true peak sits between samples, closer to the bigger side. The parabola's vertex lands between the two samples, on the side with more energy.

[PAUSE — self-check] Strip away the setup. What does B2 actually measure?

ANI: One arrival time per tower, in samples, from correlation against that tower's known P R S. Everything else in B2 just builds the test signal.

ANI: Now the Try. Move the phone fifty meters, to two hundred fifty, one hundred fifty.

[PAUSE — self-check] Before the delays print, predict them. Hint: the phone is now the same distance from the first two towers.

ANI: Both are about twenty-nine point eight eight samples, and the third is about forty-four point zero seven. The solver searches around the towers' centroid, not around the true phone, so the fix follows the phone. If the answer ever lands on the edge of its search box, the script warns you to widen it.

## S5 Code beat B3: hyperbolas cross at the fix (target 160 s)
[Screen] Demo section B3, the two contour curves crossing at the phone.

ANI: First, the assumption. Downlink time difference of arrival, D L T D O A, needs the towers to be synchronized, meaning their clocks agree. The phone measures when each P R S arrives compared with the first one. A difference in arrival time is a difference in range, not a range. "Each difference puts the phone on a hyperbola, and the hyperbolas cross at the fix." A hyperbola is the set of points whose distances to two fixed points differ by a constant. Why three towers? In two dimensions you need two unknowns, x and y, so you need two independent differences, and two differences take three towers. Tower one is the reference, and the others are compared against it.

[PAUSE — self-check] In D L T D O A, whose clock drops out, and whose clocks must agree?

ANI: The phone's clock drops out, because it's common to every arrival it measures. The towers' clocks must agree.

Worked example, for the fourth learning goal. The true differences print as eighty-five point four one meters and one hundred fifty-three point one one meters. The script turns the refined offsets into ranges, subtracts the first, and grid-searches half-meter steps across a box seven hundred meters wide, centered on the towers' centroid. It doesn't know where the phone is. With perfect delays, the grid lands within about a quarter meter of two hundred, one hundred fifty. The real error depends on the sub-sample fit. The one meter threshold is the demo's own choice, and the script prints a pass or a warning, not an assert.

"Ten nanoseconds of disagreement is about three metres of error." Precisely, ten nanoseconds is two point nine nine eight meters of range difference. How much that moves the fix depends on the geometry, which is called dilution of precision, or D O P.

[PAUSE — self-check] Set bias N s to zero, ten, zero, so only tower two is ten nanoseconds late. Predict how far the fix moves before you run it.

ANI: With exact delays, it moves about two meters, here to about one hundred ninety-eight, one hundred fifty. That's less than the three meter difference error, because of the geometry. Now set all three biases to ten. The common bias cancels exactly in the differences, and the fix returns.

## S6 Code beat B4: round trips, angles, and the blocked path (target 150 s)
[Screen] Demo section B4, the printed identity and the sign-slip line.

ANI: Round trip time, or R T T, is a range, not a difference. "Add those two differences, and the waiting time and the clock offsets drop out." Each side subtracts only its own two readings, which is why no shared clock is needed. Neither the phone nor the base station does the final geometry. Both report their time differences, and the network's location management function, in the core, combines them into a position.

The code gives the base station a clock offset a Clk of a hundred nanoseconds and the phone b Clk of minus forty. w T A is the phone's turnaround, twelve microseconds. The base station's receive minus transmit is two d over c plus w. The phone's receive minus transmit is minus w. The sum is two d over c, and a, b and w all cancel. The assert checks that identity. The spec pages describe forming these round trips, but this exact equation is a teaching identity.

Worked example, for the fifth learning goal. For two hundred fifty meters, two d over c is about one thousand six hundred sixty-eight nanoseconds. Half of that, times c, gives back two hundred fifty meters. The script also prints sum Wrong, the base station's term minus the phone's. That sign slip leaves two w in, off by twenty-four microseconds, which is about three point six kilometers of fake range.

[PAUSE — self-check] Why does subtracting the two Rx minus Tx terms fail, when adding them works?

ANI: The phone's term is minus w. Adding it cancels the turnaround. Subtracting adds it a second time.

Now set n l o s Extra to thirty. That adds thirty meters of blocked-path length to both legs, and the range comes out thirty meters long. A blocked direct path doesn't cancel, and that tower's hyperbola shifts outward. More bandwidth can't fix a path that isn't there. Angles of arrival and departure, from lecture eight, are a third method. Here they're spoken only, with no code: one angle from one site gives a line, and two lines cross.

## S7 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Range comes from delay, about thirty centimeters per nanosecond, and one sample here is about nine point seven six meters. Each tower gets its own P R S identity. Time differences, from synchronized towers, put the phone on hyperbolas. Round trips cancel both clocks and the turnaround, as long as you add the two receive-minus-transmit terms. A blocked direct path makes every range too long. Next, in lecture thirteen, the transmitter is a satellite, and delay and Doppler get much bigger.

---
## Notes for Showrunner
- **Learning goals (5 of 5).** LG1: 250 m → 833.9 ns → 25.62 samples, 9.76 m per sample. LG2: 1836 PRS REs per ID (153 × 12); 102 per symbol at comb 6. LG3: the half-sample limit (4.9 m) and a parabola example (0.6 / 1 / 0.8 → +0.17 sample). LG4: differences of 85.41 and 153.11 m, and the fix. LG5: 2d/c = 1667.8 ns, the 2w sign slip (24 µs ≈ 7.2 km), and NLOS +30 m. All were checked in Python on the box.
- **checks.md mismatch.** `track12_checks.md` gives the tower-2 bias answer as (198.0, 150.5), 2.06 m. That came from an older grid centred on the known UE. Rerunning the fixed demo's centroid grid (−350 to +350 m in 0.5 m steps) with exact delays gives (198.17, 150.17): 1.84 m from the true UE, a 2.0 m move from the unbiased fix (200.17, 150.17, which is 0.24 m off on grid quantisation alone). The narration says "about two meters" and "about one hundred ninety-eight, one hundred fifty", so it's safe either way. Please ask Pedagogue to refresh checks.md.
- **D5 / B4.** The narration follows the fixed B4 (R1–R6 applied in the demo): named rxtxGNB / rxtxUE terms, the sumWrong print as the common mistake, and the nlosExtra hook on both legs.
- **Unverified.** The `nrTimingEstimate` (carrier, waveform, ind, sym) form and the parabolic-fit bias are both VERIFY items in the demo. The RTT equation is a teaching identity (it's not written out in 38.305). The narration says so.
- **Lyric quotes.** All are verbatim and from the dry list: L7, L8–9, L31, L45 and L47. The chorus (survivor SV4), the NLOS bridge lines and the outro are not quoted.
- **Terms (U = 5).** Fractional delay and the parabolic fit (S4), and hyperbola, DOP and tower sync (S5), are defined at first use. NPRSID, RTT, DL-TDOA and NLOS are glossed.
- **Rule of thumb flagged.** S3's "one over bandwidth" scale (18.36 MHz → 54 ns ≈ 16 m) is a rough scale, and the speech says so. L13 is paraphrased, not quoted, because it's logged PG-13.
- **Cross-references (new numbers).** Lecture eight (angles), lecture thirteen next (Signals from Orbit).
