# Track 10 "Sound It Out": Ani's lecture narration (Writer, DRAFT v2)

- **Spoken words:** 1,840 (1,727 narration plus 113 read-aloud self-check questions). **Est. read time:** 12.3 min at 150 wpm. With about 10 s of silence at each of the 5 self-check pauses, the total is about 13.1 min.
- **Budget (TIME_BUDGETS_v2, "Sound It Out" row):** min 7, typical 13, max 18 min. Read time is 0.7 min under typical; with pauses, 0.1 min over. Above the floor and below the ceiling. Length comes from the worked examples, the critical self-checks and the term definitions, not padding.
- **Path:** `lecture/track10/track10_narration_v2.md` (v2, Pedagogue review applied; v1 kept unchanged beside it). Sources were taken from `lecture/track10/` (title "Sound It Out", matching RENUMBER_MAP 10 = old T10) and `lecture/pedagogue/T10_DFMEA.md`.
- **Format:** follows the NARRATION SPEC at the top of `scratch/narration/track01_narration_v1.md`.
- **v2 change (review FIX 1, L103):** the FDD worked example now uses P00b's coherence-bandwidth convention, 1/(5·τ_rms) = 6.7 MHz at 30 ns, and adds that even 1/τ = 33 MHz is far below the 190 MHz gap. Checked in Python.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent.

## Critical-finding map (pedagogue/T10_DFMEA.md; K = 5)
| DFMEA | Where handled |
|---|---|
| F5 representation (432) | S7: separate Tx and Rx chains per node, as in the fixed demo; pause on why the same gain at both ends can't break reciprocity |
| F8 assessment (210) | S7: predict the raw residual before it prints; both asserts named |
| F2 prereq gap (150) | S2 defines TDD and FDD in one line each; S8 pause on the FDD case |
| F3 ordering (150) | S6: plain transpose, not conjugate, stated as the rule; toolbox layout as a footnote line; pause |
| F6 transfer (150) | S4: the row 1, density three Try with no other edits; predict the count first |

---
## S1 Cold open (target 25 s)
[Screen] Ani at the desk. A tower with many antennas, a phone in the distance.

ANI: A base station with many antennas wants to aim at your phone. To aim, it needs the channel. There are two ways to get it: listen to the phone going up, or ask the phone to measure coming down. Today we do both and check when they agree.

## S2 Concept: who measures the channel (target 60 s)
[Screen] Two arrows, up and down, between the tower and the phone. The labels T D D and F D D.

ANI: In lecture nine we steered a beam, and we assumed someone knew which way to point. This lecture supplies the measurements behind that. The base station needs the channel matrix, H: one complex gain for every pair of transmit and receive antennas.

Two words decide everything today. In time division duplex, or T D D, uplink and downlink take turns on the same carrier. In frequency division duplex, or F D D, they use two different carriers at the same time.

One more term. An antenna port is a logical antenna as the receiver sees it: one stream of reference signal that it can measure on its own. A port can map to one physical antenna or to several.

## S3 Animation A2 and code beat B1: sounding up (target 140 s)
[Screen] Animation A2: one column of subcarriers; phone one fills every other tooth, phone two the gaps. Then demo section B1 and its striped figure.

ANI: The song puts it plainly: "A sounding reference signal, S R S, goes up from the phone." It carries no data. It's there so the base station can measure the uplink, port by port.

The S R S sits on a comb. A comb means the signal uses only every second, fourth, or eighth subcarrier, so several phones can share the same symbol on different teeth. The comb size is a property called K T C.

In the code, carrier U L is an N R Carrier Config at fifteen kilohertz with fifty-two resource blocks. The script makes s r s with N R SRS Config, sets Num SRS Ports to one, Symbol Start to thirteen, Num SRS Symbols to one, K T C to two, and C SRS to three. Symbol thirteen is the last symbol of the slot, because the count starts at zero. C SRS is a row of the bandwidth table in the spec, and it sets how many resource blocks get sounded. N R SRS Indices says where the symbols go, and N R SRS makes them. The script drops them into an N R Resource Grid and prints the count.

Worked example, for the first learning goal. The grid is fifty-two times twelve, six hundred twenty-four subcarriers, by fourteen symbols. C SRS three sounds sixteen resource blocks, which is one hundred ninety-two subcarriers. A comb of two keeps half of them, so expect ninety-six resource elements in one symbol. The figure shows symbols ten to fourteen, with stripes only in the last one.

Try K T C equals four. Same sixteen blocks, every fourth subcarrier: forty-eight.

## S4 Code beat B2: measuring down (target 130 s)
[Screen] Demo section B2. Hold before the count prints.

ANI: The downlink measurement is different. "That downlink measurement rides on the channel state information reference signal, C S I R S." It's not the S R S run backward. It has its own sequence and its own placement rules.

"A non zero power resource carries symbols the phone can measure. A zero power resource leaves those elements empty." Zero power is useful for measuring interference, or for keeping a neighbour's signal clean. The demo uses non zero power, which is the default.

In the code, carrier D L matches the uplink carrier. c s i r s is an N R CSI RS Config with Row Number two, Density one, Symbol Locations four, Subcarrier Locations zero, and Num R B fifty-two. The row number, one through eighteen, picks a pattern from the spec table: how many ports, where they sit, and the density options. Row two is one port, one resource element per resource block. Rows with more ports share resource elements using code division multiplexing, or C D M: each port gets its own sign pattern across the shared elements, so the phone can separate them. Row two needs none.

Worked example, for the second learning goal. One resource element per block, across fifty-two blocks, is fifty-two resource elements. That's much sparser than the S R S's ninety-six.

[PAUSE — self-check] The Try sets Row Number to one and Density to three, and changes nothing else. Predict the new count before you run it.

ANI: Row one is a one-port tracking row, so no other field has to change. Density three puts three elements in each block. Three times fifty-two is one hundred fifty-six, triple the count. A row with two or more ports would also need a grid with that many ports, so read the row table before you edit.

## S5 Concept: from a known signal to a channel estimate (target 50 s)
[Screen] One resource element: sent symbol, received symbol, and their ratio.

ANI: How does a known signal become a channel? Divide what the base station heard by what the phone sent. That's the least-squares estimate at each reference element, ignoring noise.

Worked example, for the third learning goal. Suppose the S R S symbol sent on one element is one, and the base station hears zero point six plus zero point eight j. The channel at that element is zero point six plus zero point eight j: magnitude one, phase about fifty-three degrees. If the sent symbol were j instead, you'd divide by j and get zero point eight minus zero point six j. Do that at every comb tooth, and interpolate between them. Today's demo doesn't run the estimator. It works with the channel's true path gains, so we can check the physics directly.

## S6 Animation A1 and code beat B3: reciprocity (target 150 s)
[Screen] Animation A1: a four-by-two matrix of arrows reverses direction and flips about its diagonal. Then demo section B3.

ANI: "Here's the invariant. The air between two antennas is reciprocal:" At the same frequency, at nearly the same moment, "the path from A to B matches the path from B to A." For matrices, that means the uplink channel is the plain transpose of the downlink channel. Plain transpose: rows and columns swap, and nothing is conjugated.

In the code, the channel is an N R TDL Channel, a tapped delay line model, with delay profile T D L C, a delay spread of thirty nanoseconds, no Doppler, and a sample rate of fifteen point three six megahertz. It has two transmit antennas and four receive antennas. The script sends sixty-four samples of zeros and keeps only the path gains, p g Fwd. Then it calls swap Transmit And Receive on the same object, so four antennas now transmit and two receive, and collects p g Rev.

Worked example, for the fourth learning goal. The path gains are samples by paths by transmit antennas by receive antennas. T D L C has twenty-four paths, so expect sixty-four by twenty-four by two by four going forward, and sixty-four by twenty-four by four by two after the swap. Summing the paths at the last sample gives H f, two by four, and H r, four by two. The script prints the relative residual between H f transposed and H r. With the same object and no Doppler, it should be near zero. Toolbox tensors order their dimensions differently from the textbook matrix, which is why the script transposes the summed matrices.

[PAUSE — self-check] A colleague compares the uplink with the conjugate transpose of the downlink. Is that the physical reciprocity rule?

ANI: No. Physical reciprocity is the plain transpose. A conjugate shows up only when a particular formula or toolbox convention puts one there, so check the convention before you add it.

## S7 Code beat B4: break it with radios, then calibrate (target 150 s)
[Screen] Demo section B4. Hold before the residual line prints.

ANI: "But the radios aren't the air. Each transmit chain and receive chain adds its own gain and phase, so you calibrate those away first." The key is that each node's transmit chain differs from its own receive chain. The downlink uses the base station's transmit chains and the phone's receive chains. The uplink uses the phone's transmit chains and the base station's receive chains.

The code builds a two-by-two air channel, H phys. Each node gets a transmit vector and a receive vector: t G N B and r G N B for the base station, t U E and r U E for the phone. Each pairs a gain with a small phase, for example zero point eight at ten degrees. H d l is diag r U E times H phys times diag t G N B. H u l is diag r G N B times H phys transposed times diag t U E.

[PAUSE — self-check] Before it prints, write down your prediction: will the raw residual between H d l transposed and H u l be zero or not?

ANI: Not zero. Each node's transmit and receive chains differ, so the transpose picks up the wrong chain gains.

[PAUSE — self-check] Now the design question. Why would a model that gives each node one gain, used both for sending and for receiving, never show a break?

ANI: Because then H d l transposed equals H u l by construction, whatever the gains are. The experiment couldn't fail. That was the bug the fix removed.

Worked example, for the fifth learning goal. The printed raw residual is about zero point two zero four. Dividing all four chains back out gives about two times ten to the minus sixteen, which is rounding. Correcting only the base station's ratio leaves about zero point six three, worse than doing nothing. The script asserts the raw residual is above one thousandth and the calibrated one below ten to the minus twelve. Try setting t U E equal to r U E, a perfectly matched phone: the base-station-only residual then drops to about zero. This calibration is a textbook teaching model, plain matrix algebra, not a toolbox function.

## S8 Animation A3: the F D D trap (target 70 s)
[Screen] Animation A3: a frequency-selective channel curve with two shaded bands, first close, then far apart.

ANI: So why not use the uplink channel everywhere? "In frequency division duplex, the uplink and the downlink sit on different frequencies." Move far enough apart in frequency, past the coherence bandwidth, meaning the span over which the channel stays about the same, and the fades going up tell you little about the fades coming down.

Worked example, for the sixth learning goal. A common F D D band, band n one, puts the uplink at nineteen twenty to nineteen eighty megahertz and the downlink at twenty-one ten to twenty-one seventy, one hundred ninety megahertz apart. Using the map-of-the-link convention, coherence bandwidth is about one over five times the delay spread: with the demo's thirty nanoseconds, six or seven megahertz. Even one over the delay spread is only thirty-three. The gap is far beyond either, so the two directions fade independently. The phone has to measure the C S I R S and report it. Even in T D D, the base station never hears the interference around the phone, which is one reason phones still report.

[PAUSE — self-check] Your uplink sounding is on one carrier, and the downlink estimate on another, and they disagree even with perfect radios. What's the cause?

ANI: It's F D D. Different frequencies give different fades, so there's no free reciprocity.

## S9 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: S R S goes up on a comb, so the base station can measure the uplink. C S I R S comes down, so the phone can measure and report. In T D D the air is reciprocal, and the uplink channel is the plain transpose of the downlink. Radios break that, because each node's transmit and receive chains differ, so calibrate both ends. In F D D there's no free reciprocity, so the phone reports. Next, in lecture eleven, we run a whole link and count the blocks that fail.

---
## Notes for Showrunner
- **Learning goals (6 of 6).** LG1: 96 SRS REs (16 RB × 12 / 2), and 48 at KTC 4. LG2: 52 CSI-RS REs, and 156 for the row 1 / density three Try. LG3: an LS ratio by hand (0.6 + 0.8j), because the demo has no estimator. LG4: path-gain sizes and the transpose residual. LG5: residuals 0.204 / 0.629 / 2.3e-16, rechecked in Python. LG6: band n1's 190 MHz duplex gap vs 1/(5·30 ns) ≈ 6.7 MHz (P00b convention) and 1/(30 ns) ≈ 33 MHz.
- **Numbers that need M's run.** The 96 SRS REs use the 38.211 C_SRS = 3 row (m_SRS = 16 RB) from memory, so the table value is unverified. TDL-C has 24 taps, also from memory. The B3 residual near zero assumes the swapped object reuses the same path gains, which the demo calls "same seed, same object" and is unverified.
- **Rule of thumb (v2).** The coherence-bandwidth scale now cites P00b's stated convention, 1/(5·τ_rms), which is the same one lecture 07 uses. One over the delay spread is kept only as the looser bound.
- **Plan vs fixed demo.** The plan's B3 sets `NormalizeChannelOutputs = false` before the swap, and B2 shows a ZP grid with an OFDM LS estimate. The fixed demo keeps `NormalizeChannelOutputs = true`, compares path gains (which this flag shouldn't touch, though that's unverified), uses NZP only, and does no estimation. The narration follows the demo.
- **Untaught terms (U = 3).** Antenna port (S2), comb (S3) and CDM (S4) are defined at first use. TDD, FDD, LS estimate, coherence bandwidth, NZP and ZP are defined too.
- **Lyric quotes.** All are verbatim from the certified box, checked by script: the SRS definition, the invariant, the radios lines, the CSI-RS line, the NZP / ZP lines and the FDD line. No hook, chorus, intro, outro or survivor line is quoted. The LS line ("falls out", logged PG-13) is paraphrased, not quoted.
- **Cross-references.** Back to lecture nine (beams); forward to lecture eleven (One in Ten).
