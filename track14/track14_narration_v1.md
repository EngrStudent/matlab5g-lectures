# Track 14 "Mirror Image": Ani's lecture narration (Writer, DRAFT v1)

- **Spoken words:** 1,621 (1,521 narration plus 100 read-aloud self-check questions). **Est. read time:** 10.8 min at 150 wpm. With about 10 s of silence at each of the 5 self-check pauses, the total is about 11.6 min.
- **Budget (TIME_BUDGETS_v2, "Mirror Image" row):** min 7, typical 12, max 17 min. Read time is 1.2 min under typical; with pauses, 0.4 min under. Above the floor and below the ceiling. Length comes from the worked examples, the critical self-checks and the term definitions, not padding.
- **Path:** `track14/track14_narration_v1.md`. Sources were taken from the Track 14 lecture materials, whose files carry the title "Mirror Image" (RENUMBER_MAP 14 = old T13).
- **Format:** follows the NARRATION SPEC at the top of `scratch/narration/track01_narration_v1.md`.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent.

## Critical-finding map (pedagogue/T14_DFMEA.md; K = 5)
| DFMEA | Where handled |
|---|---|
| F5 representation (288) | S4: row 60 is 253 subcarriers below DC, its mirror is row 566, and the wanted and mirror magnitudes print together; pause predicts the mirror row |
| F3 ordering (216) | S3: slow part = CPE (fixable), fast part = ICI (not); S5 states B3 scores phase noise after the CPE fix; pause |
| F6 transfer (210) | S6: back-off = moving left; the Try removes the noise floor; pause predicts what vanishes |
| F8 assessment (210) | S4: the measured wanted-to-mirror ratio is asserted within 0.5 dB of the IRR; predict it first |
| F2 prereq gap (150) | S2 and the beats: units for dBc/Hz, IIP3, kTB, IRR and AM/AM–AM/PM at first use; pause on units |

---
## S1 Cold open (target 25 s)
[Screen] Ani at the desk. An oscillator, a mixer and an amplifier drawn as three boxes.

ANI: No real radio is perfect. Oscillators drift, mixers are slightly unbalanced, and amplifiers compress near the top of their range. Today we add each flaw on purpose, measure it, and learn the one rule for combining them.

## S2 Concept: the budget we're spending (target 70 s)
[Screen] An error vector drawn from an ideal constellation point to a received one.

ANI: First, why care. Lecture two set an error budget: error vector magnitude, or E V M. "Take each received symbol, subtract the ideal one, and square the error. Average the squares, divide by the average reference power, take the root, and say it as a percentage." The base station limits get tighter as the constellation grows: "eight for sixty-four QAM, and three and a half for two fifty-six QAM." Every flaw in today's lecture spends part of that budget.

The demo computes E V M with a one-line function, evm Pct, using exactly that definition. The carrier is fifteen kilohertz with fifty-two resource blocks, and every resource element holds a random Q P S K symbol. A clean modulate and demodulate gives an E V M of essentially zero, on the order of rounding. That's the baseline.

## S3 Code beat B1: phase noise, the common part and the leak (target 150 s)
[Screen] Demo section B1, the constellation before and after the common-phase correction.

ANI: An oscillator never holds one perfect frequency. Its phase wanders. The demo models that with comm dot Phase Noise, at a level of minus sixty d B c per hertz at a ten kilohertz offset. d B c per hertz means power relative to the carrier, in decibels, measured in a one hertz band at that offset from the carrier. Minus sixty is far noisier than the default, on purpose, so the effect is visible.

The song names the two parts: "In OFDM, the slow part of that wander turns every subcarrier in a symbol by the same angle, a common phase error, and a receiver can track it. The fast part leaks each subcarrier into its neighbours, and that part acts like noise." The slow part is the common phase error, or C P E. The fast part is inter-carrier interference, or I C I.

The code measures the common phase per symbol, c p e, as the angle of the sum of the reference conjugate times the received grid, down each column. Then it rotates each symbol back. It prints the E V M before and after.

Worked example, for the first learning goal. Suppose one symbol is rotated by a common three degrees. Each point moves along an arc, and the error is two times the sine of one and a half degrees, about five point two percent of the symbol's amplitude. The C P E fix removes all of it. What it can't remove is the leakage, so the E V M after the fix stays above zero.

[PAUSE — self-check] After the C P E fix, the E V M still isn't zero. Is the fix broken?

ANI: No. The fix removes only the common rotation, the slow part. The fast part spreads energy into neighbouring subcarriers, and that I C I acts like noise. A residual is expected.

## S4 Code beat B2: I Q imbalance and the image at minus k (target 170 s)
[Screen] Demo section B2. Hold before the wanted and mirror lines print.

ANI: A mixer splits the signal into two halves, in phase and quadrature, I and Q. They should match in gain and sit exactly ninety degrees apart. They never quite do. The result is an image: what you send on subcarrier k shows up again, faintly, on minus k.

"I Q imbal applies it: an amplitude imbalance in decibels, and a phase imbalance in degrees." The demo uses A equals zero point five decibels and P equals two degrees. The image rejection ratio, I R R, is the wanted power over the image power, in decibels.

Worked example, for the second learning goal. g is ten to the A over twenty, about one point zero five nine. The script's formula, g squared plus two g cos P plus one, over g squared minus two g cos P plus one, gives about eight hundred eighty-three. Ten log ten of that is twenty-nine point four six decibels. The E V M from imbalance alone is a hundred over the square root of that ratio, three point three seven percent. The script asserts both against those targets.

Now the mirror itself. The script puts one tone on grid row sixty. Row r sits r minus one minus three hundred twelve subcarriers from DC, because the grid has six hundred twenty-four rows.

[PAUSE — self-check] Row sixty: which side of DC is it on, and which row holds its mirror? Work it out before the line prints.

ANI: Sixty minus one minus three hundred twelve is minus two hundred fifty-three. That's below DC, a negative frequency. The mirror is plus two hundred fifty-three, which is row five hundred sixty-six: six hundred twenty-four minus sixty plus two.

[PAUSE — self-check] Now predict the measured ratio between the wanted row and the mirror row, in decibels.

ANI: About twenty-nine point four six, the I R R. In amplitude, the mirror is about three point four percent of the wanted tone. The script asserts the measured ratio is within half a decibel of the prediction, which checks the toolbox's actual image, not just the formula. The plot shows two spikes, one at minus two hundred fifty-three and one at plus two hundred fifty-three, about twenty-nine decibels apart. Try A and P at zero: the image vanishes. Double A, and the image rises. In a real receiver you'd estimate the imbalance and remove it. The song names comm dot I Q Imbalance Compensator for that job, but today's demo doesn't call it. We only measure the damage.

## S5 Code beat B3: independent flaws add in power (target 120 s)
[Screen] Demo section B3, the printed triangle.

ANI: Here's the one rule for combining them. "Here's the invariant: independent impairments add in power, not in percent. Three percent from one and four percent from another make five, not seven." Three squared plus four squared is twenty-five, and the root is five.

In the code, c p e Fix is the B1 correction as a function. e v m P N is phase noise alone, after the C P E fix, so only its I C I is left. e v m I Q all is the imbalance alone. e v m Both is the cascade, also after the C P E fix. The prediction is the hypotenuse of the first two.

Worked example, for the fourth learning goal. If the phase-noise residual came out at two percent, then with three point three seven percent from imbalance, the prediction would be the square root of two squared plus three point three seven squared, about three point nine two percent, not five point three seven. Compare the printed cascade with the printed prediction. The rule holds when the flaws are small and independent. This triangle comes back in lecture fifteen.

## S6 Code beat B4: the amplifier and the back-off U-curve (target 160 s)
[Screen] Demo section B4, the U-shaped curve with its two arms labelled.

ANI: Near the top of its range, an amplifier's gain compresses, and its phase twists with the input level. Those effects are called A M to A M and A M to P M: amplitude in changes amplitude out, and amplitude in changes phase out. The demo uses comm dot Memoryless Nonlinearity with a cubic polynomial, an I I P 3 of ten d B m, and no A M to P M. I I P 3, the input third-order intercept point, is a drive level in d B m that marks how strongly the amplifier bends: the higher it is, the more linear the amplifier.

Why back off at all? An O F D M waveform is a sum of many subcarriers, so its peaks rise well above its average power. Run the average near the top of the amplifier's range and the peaks get squashed. So you lower the drive to keep the peaks in the linear region.

The script sweeps input power from minus thirty to plus six d B m in two-decibel steps. It adds a fixed noise floor of minus fifty d B m after the amplifier, then undoes the known drive and measures E V M. For scale, thermal noise, k T B, is Boltzmann's constant times temperature times bandwidth. In fifteen point three six megahertz that's about minus one hundred two d B m. The demo's floor is set much higher, standing in for the whole receive chain, so both arms fit on one sweep.

Worked example, for the third learning goal. At minus thirty d B m input, the signal is twenty decibels above the floor, so noise alone gives an E V M of ten percent. At minus fourteen, it's thirty-six decibels above, about one point six percent. Push the input toward the I I P 3, and compression takes over. A model of this setup puts the minimum near one point four percent, around minus fourteen d B m, but your printed minimum is the one to trust. Backing off means moving left on this axis.

[PAUSE — self-check] Set noise Floor d B m to minus infinity. Which arm of the U disappears?

ANI: The left one. Without a noise floor, backing off only ever helps. Raise the I I P 3 to twenty instead, and the minimum moves right. More back-off isn't always cleaner.

[PAUSE — self-check] Units check. Which of these is a power, which is a ratio, and which is a density: d B m, I R R in decibels, and d B c per hertz?

ANI: d B m is an absolute power, relative to one milliwatt. I R R is a ratio of two powers. And d B c per hertz is a density relative to the carrier, per hertz of bandwidth.

## S7 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Phase noise is a common rotation you can track, plus leakage you can't. I Q imbalance puts a mirror image at minus k, about the I R R below the wanted tone: twenty-nine point four six decibels for half a decibel and two degrees. Independent errors add in power, not in percent. And amplifier back-off has an optimum, between noise on one side and compression on the other. Next, in lecture fifteen, every piece goes into one chain.

---
## Notes for Showrunner
- **Learning goals (4 of 4).** LG1: a 3° common rotation → 5.2% EVM (removed by CPE), with the ICI residual. LG2: IRR 29.46 dB, EVM 3.37%, row 60 at −253 ↔ mirror row 566 at +253, amplitude ratio ≈ 0.034. LG3: the noise arm at 10% (−30 dBm) and 1.6% (−14 dBm) above a −50 dBm floor; kTB ≈ −102.1 dBm. LG4: rss(3, 4) = 5 and a hypothetical rss(2, 3.37) = 3.92. All were checked in Python.
- **Order.** The beats follow the demo (B3 is the power rule before the B4 amplifier), so LG4 is worked before LG3. Each is labelled by its plan number.
- **Model-based number.** The "about 1.4% near −14 dBm" minimum comes from `track14_checks.md` (a NumPy approximation of the cubic model). The narration tells learners to trust their printed minimum. The phase-noise EVMs are toolbox outputs, so no number is quoted for them.
- **Lyric quotes.** All are verbatim and from the dry list: the EVM definition (L51–53), the limits (L59), the CPE / ICI lines (L11–13), the iqimbal lines (L27–28) and the invariant (L55–56). The hook and chorus aren't quoted; the k / minus k line is paraphrased.
- **Terms (U = 5).** dBc/Hz (S3), IRR (S4), AM/AM–AM/PM, IIP3 and kTB (S6) are defined at first use; CPE and ICI are defined too.
- **Cross-references (new numbers).** Lecture two (the EVM limits; T02 "Copy the Tail" holds the 38.104 limit per TIME_BUDGETS), and lecture fifteen next.
