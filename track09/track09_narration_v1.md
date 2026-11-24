# Track 09 "Steer the Beam": Ani's lecture narration (Writer, DRAFT v1)

- **Spoken words:** 1,749 (1,653 narration plus 96 read-aloud self-check questions). **Est. read time:** 11.7 min at 150 wpm. With about 10 s of silence at each of the 5 self-check pauses, the total is about 12.5 min.
- **Budget (TIME_BUDGETS_v2, track 09):** min 7, typical 12, max 17 min. The read time is 0.3 min under typical; with the pauses it is about 0.5 min over. Either way it is well above the floor and below the ceiling. The length comes from 5 worked examples, 5 critical self-checks and the term definitions, not padding. A first pass ran to 2,296 words (15.3 min) and was cut back.
- **Path:** `track09/track09_narration_v1.md`. Album number 09 is the same before and after the renumber (RENUMBER_MAP: 09 = old T09).
- **Format:** follows the NARRATION SPEC at the top of `scratch/narration/track01_narration_v1.md`.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent.

## Critical-finding map (pedagogue/T09_DFMEA.md; K = 5)
| DFMEA | Where handled |
|---|---|
| F6 transfer, grating lobes (336) | S6: both arrays steered to 30 degrees, lobe predicted at minus 30; pause predicts the 0.75 wavelength lobe before the Try runs |
| F5 representation (252) | S4: one setup stated (fixed total power, unit-norm w, amplitude root N, gain 10 log10 N); N squared named as the per-element-power case; S5 ties the receive framing to the same number; pause on "which setup" |
| F8 assessment (240) | S4: predict the N = 64 peak before it prints (commit point); answer only after the pause |
| F3 ordering (175) | S7: CSI half labelled a preview (D4 keeps it here); the real order, measure then report then aim, is said aloud; pause on "which comes first" |
| F2 prereq gap (150) | S7: one-line glosses for RF chain, hybrid beamforming, beam index, CSI, CSI-RS, CQI, PMI, each with the lecture that teaches it; pause on "is a CQI an angle" |

---
## S1 Cold open (target 25 s)
[Screen] Ani at the desk. A row of sixteen small dots on paper.

ANI: Take many small antennas, each sending the same signal. Get the timing of each one right, and the copies add up in one direction and cancel in others. That's beamforming. Today we build the array, steer it, measure the gain, and break it on purpose.

## S2 Concept: why an array (target 50 s)
[Screen] A tower, a distant phone, a nearly empty signal bar.

ANI: First, the problem. At mid-band and millimeter-wave frequencies, a signal loses a lot of strength on its way to the phone. One antenna spreads its power everywhere. Sixteen antennas working together can aim that same power and gain about twelve decibels, which is often what closes the link.

Three words before the code. A uniform linear array, or U L A, is a row of identical elements with equal spacing. Broadside is straight out from the row, at zero degrees. End-fire is along the row, at ninety. The wavelength, lambda, is the speed of light over the frequency. At the demo's three gigahertz, that's about ten centimeters.

## S3 Animation A1 and code beat B1: the steering vector (target 130 s)
[Screen] Animation A1: a tilted wavefront sweeps sixteen dots, each phase dial lagging the last. Then demo section B1.

ANI: A wave arriving from angle theta reaches each element a little later than the last, and later means a turn in phase. With spacing d, the phase step is two pi times d over lambda, times sine theta. At half a wavelength, that's the song's line: "At half wavelength spacing, the phase step between neighbours is pi times sine theta." And "Write those phases down, one per element, and you have the steering vector."

In the code, N is sixteen and el Spacing is half of lambda. phased dot U L A builds the array from Num Elements and Element Spacing. Set the spacing explicitly, because the default is half a meter, not half a wavelength. phased dot Steering Vector takes that array, the propagation speed and the operating frequency. Calling the object, s v, with f c and an angle in degrees returns one complex number per element. The script asks for a zero, at broadside, and a thirty, at thirty degrees. The first print shows every entry has magnitude one. The second shows the phase step at thirty degrees.

Worked example, for the first learning goal. Sine of thirty degrees is one half, and pi times one half is ninety degrees. On screen you'll see steps of ninety, with a sign set by the toolbox's convention. A few entries may show two hundred seventy the other way. That's the same step, wrapped around the circle.

A common mistake: if you write the formula by hand, sine in MATLAB takes radians. Sine of thirty radians is about minus zero point nine nine, which puts the beam near minus eighty-one degrees. Use s i n d, or convert first.

## S4 Code beat B2: pattern, gain and the power invariant (target 150 s)
[Screen] Demo section B2. Hold on the code before the peak line prints.

ANI: Now the pattern. The weights w are a zero divided by its norm, so their squared magnitudes add up to one. The script sweeps ang from minus ninety to ninety degrees, builds s v Ang toward every angle, and plots the magnitude of w prime times s v Ang in decibels. W prime is the conjugate transpose of w. That curve is the array factor: the array's gain in each direction relative to one element.

Here's the one setup we use all lecture. The total transmit power is fixed, and unit-norm weights split it. The song's rule: "if every weight has magnitude one, the total power sent stays the same." In the song, magnitude one means every element gets the same strength. The script scales all sixteen down equally, by the square root of N, so the total stays at one, and the beam's shape doesn't change. "Steering doesn't make energy. It moves energy, toward one angle and away from the rest."

Worked example, for the second learning goal. Sixteen weights, each of magnitude one quarter. Each squared is one sixteenth, and sixteen of those make one. The total power didn't change. Only where it goes did.

In the look direction the copies add in phase, so the amplitude is the square root of N, four. Power is amplitude squared, so the gain is N, or ten log ten of N decibels. Worked example, for the third learning goal: ten log ten of sixteen is twelve point zero four. The script finds the pattern's peak and asserts it's within five hundredths of a decibel of ten log ten of N. That checks the pattern itself, not just the arithmetic. Expect twelve point zero four at zero degrees.

You'll also see a second setup quoted. If every element keeps its own full power, total power grows by N as well, and the effective isotropic radiated power, E I R P, grows as N squared: twenty log ten of N, or twenty-four point zero eight decibels for sixteen. That's not a mistake, just a different setup.

[PAUSE — self-check] One source says a sixteen element array gives twenty-four decibels, another says twelve. Which setup is each one using?

ANI: Twenty-four keeps each element at full power, so the total grew. Twelve holds the total fixed. Both are right for their setup.

[PAUSE — self-check] Change N at the top of B1 to sixty-four. Before you run it, write down the peak you expect.

ANI: Eighteen point zero six decibels. "Sixty-four elements give ten log ten of sixty-four, about eighteen decibels." If a longer array ever seems to beat ten log ten of N, check the normalisation. You've silently sent more total power.

## S5 Animation A2: why noise doesn't keep up (target 35 s)
[Screen] Animation A2: signal phasors add head to tail into one long arrow; noise phasors wander. A decibel counter climbs to 18.06.

ANI: The receive side gives the same number. "The gain comes from adding in phase: the signal power grows with N squared, the noise power only with N, so the signal to noise ratio grows by N." Signal amplitudes line up and add. Independent noise adds only in power. N squared over N is N, the same ten log ten of N, as long as each element's noise is independent.

## S6 Animation A3 and code beat B3: the grating-lobe counterexample (target 130 s)
[Screen] Animation A3: a polar pattern morphs as spacing slides from half a wavelength to one; a second lobe grows at minus thirty. Then demo section B3.

ANI: So why not spread the elements wider for a sharper beam? "Here's the counterexample. Set the spacing to a whole wavelength and steer anywhere off broadside." Past half a wavelength, a second direction produces the same phase steps, wrapped by a full turn. The array can't tell them apart. That copy is a grating lobe, a second main lobe at a false angle.

Where does it land? Sine of the grating angle equals sine of the steer angle minus lambda over d. Worked example, for the fourth learning goal. Steer to thirty degrees with d equal to lambda. One half minus one is minus one half, and that's minus thirty degrees.

In the code, steer is thirty and spacing Wide is one wavelength. The script steers the half-wavelength array to thirty, then builds array Wide with phased dot U L A and its own steering object, s v W, steered to the same thirty. Both are steered off broadside on purpose. At broadside, the one-wavelength lobes would sit exactly at plus and minus ninety, the ends of the sweep, where the peak finder can't see them. is Peak marks any sample higher than both neighbours, and floor T keeps peaks within eight decibels of the maximum. Expect one lobe at thirty for half a wavelength, and two, at minus thirty and thirty, for one wavelength. The assert checks that the wide array has more. "Keep the spacing at half a wavelength, and only one main lobe can form."

[PAUSE — self-check] Set spacing Wide to zero point seven five, still steering to thirty. Where does the grating lobe land? Work it out first.

ANI: Lambda over d is about one point three three. One half minus that is about minus zero point eight three, so roughly minus fifty-six and a half degrees: two lobes. Stretching the array without adding elements narrows the beam but gives up a unique direction.

## S7 Code beat B4: hybrid weights and where C S I comes from (target 140 s)
[Screen] Demo section B4, then a still of the "5G NR Downlink CSI Reporting" example title, with attribution.

ANI: Two terms first. An R F chain is one complete radio path, a converter plus a mixer. Hybrid beamforming puts a few R F chains behind many elements: analog phase shifters steer groups, and a small digital precoder, meaning a set of digital beam weights, mixes a few streams. The song names O M P hyb weights for designing both together. This demo doesn't call it. It takes the simplest case, one R F chain.

The code reuses w from B2, pointed at broadside, as an analog weight. a Inc is s v at thirty degrees, a wave arriving off-axis. on Bore is the squared magnitude of w prime times a zero, and off Bore is the same with a Inc.

Worked example, for the fifth learning goal. on Bore is sixteen, the full twelve point zero four decibels. off Bore is zero, to rounding. At thirty degrees the steps are ninety degrees, so sixteen phases go around the circle four times and cancel. A mis-steered weight with one R F chain can lose everything.

So how does the base station know where to aim? This part is a preview, and the next two lectures teach it. C S I, channel state information, is the report a phone sends back. The phone measures it on the C S I R S, a reference signal taught in lecture ten. The report carries a rank, the number of parallel streams; a P M I, precoder matrix indicator, saying which beam weights to use; and a C Q I, channel quality indicator, which sets the data rate. Its error target is lecture eleven. A beam index, the third local term, says which of a set of beams was strongest. The script calls N R C Q I Tables, from release twenty twenty-four a, and prints its property names, or a skip message on older releases. It's a glimpse of the C Q I menu, not a beamformer.

[PAUSE — self-check] A phone reports C Q I nine. Can you turn that into a beam angle?

ANI: No. A C Q I picks a row in a quality table. Direction comes from the P M I or a beam index.

[PAUSE — self-check] Put these in order for a real link: the phone reports, the base station aims, the phone measures the reference signal.

ANI: Measure, report, then aim. We ran it backward today because the beam is today's topic. Lecture ten starts at the measurement.

## S8 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Four things to keep. A steering vector is one phase per element, and at half a wavelength the step is pi times sine theta. With fixed total power and unit-norm weights, steering moves energy without making it, and the gain is ten log ten of N. Spacing above half a wavelength lets a grating lobe in. With one R F chain, a mis-steered weight can lose the gain, and the phone's report says where to aim. Build the array, steer it to thirty degrees, then widen the spacing.

---
## Notes for Showrunner
- **Learning goals (5 of 5).** LG1 is worked with 30 degrees (90-degree step). LG2 with sixteen weights of magnitude 1/4 (total 1). LG3 with 12.04 dB (N = 16) and the 18.06 dB prediction (N = 64). LG4 with the grating lobe at minus 30 degrees, plus the 0.75 wavelength pause (minus 56.5 degrees). LG5 with on Bore 16 vs off Bore 0. Every number was checked on the box with a NumPy re-implementation of the demo's array factor (0.5-degree grid, base-MATLAB peak rule). MATLAB itself was not run.
- **Untaught terms (U = 3), defined at first use in S7.** RF chain, hybrid beamforming, beam index. The other terms are also defined at first use: ULA, broadside, end-fire, lambda, array factor, EIRP, grating lobe, precoder, CSI, CSI-RS, rank, PMI, CQI.
- **Lyric quotes.** Verbatim from the certified box in `track09/track09_lyrics_prelim.md`: L9, L10, L27, L28, L29 to L30, L31, L41 to L42, and L45. All are on the inventory's "must stay dry" list. No chorus, intro, outro, survivor or R-logged line is quoted, and neither is L68.
- **F3 vs D4.** The DFMEA's F3 fix said to move the CSI half to track 10. DECISIONS D4, which is later and decided by M, keeps it here as dual delivery. I followed D4, labelled the CSI half a preview, and added the measure, report, aim pause. That covers F3's concern without cutting anything.
- **Plan vs post-fix demo.** The plan's B1 text uses `sv(fc,[30;0])` and its B4 uses `omphybweights` with SVD spectral efficiency. The post-fix `track09_demo.m` uses `sv(fc, 30)` and a one-RF-chain on/off-boresight comparison, and it doesn't call `omphybweights`. The narration follows the demo. It mentions `omphybweights` only as the function the song names, and says the demo doesn't call it.
- **B4 plan mismatch (Showrunner-confirmed 2026-11-18).** `track09_demo_plan.md` B4 (`omphybweights` plus the SVD spectral-efficiency comparison) does not match the fixed `track09_demo.m`. The narration follows the demo, which is the source of truth.
- **Unverified runtime details.** The sign of the printed phase step, the 270-degree wraps, and the `nrCQITables` property names depend on the toolbox. The narration hedges each of them.
- **Cut candidates if a shorter read is needed.** The S4 EIRP / N-squared paragraph and its pause, about 35 s, but that would drop the F5 fix, so I don't recommend it. The S3 radians mistake, about 15 s. The S5 animation narration could shrink to its lyric quote, about 10 s.
