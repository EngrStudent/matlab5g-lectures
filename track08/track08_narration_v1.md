# Track 08 "Clusters and Angles": Ani's lecture narration (Writer, DRAFT v1)

- **Spoken words:** 1,384 (1,247 narration plus 137 read-aloud self-check questions). **Est. read time:** 9.2 min at 150 wpm, or about 10.2 min with about 10 s of silence at each of the 6 self-check pauses.
- **Budget (TIME_BUDGETS_v2, track 08):** min 7, typical 11, max 17 min. About 0.8 min under typical.
- **Spec:** NARRATION SPEC at the top of `lecture/track01/track01_narration_v1.md` (voice, structure, fill rules, spoken form, notation, numbering, count method).
- **Sources read:** `track08/track08_lyrics_prelim.md` (certified box), `lecture/track08/` demo_plan, demo.m, lecture_notes; `pedagogue/T08_DFMEA.md`, FIXES_v1, DECISIONS, TIME_BUDGETS_v2.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent. Album numbers are used throughout (RENUMBER_MAP.md).

## Self-check map
- F5: the cluster scatter and the CDL-D prediction (S3).
- F4: the Size legend and the path-gain size pause (S4).
- F3: the lecture 09 pointer (S4) and the steering vector as a preview (S6).
- F2: rank and SVD are defined, plus a singular-value pause (S6).
- F8: the s2/s1 commit (S6).
- F6: the named AngleScaling/AngleSpreads Try (S6).

---
## S1 Cold open (target 30 s)
[Screen] Ani at the desk.

ANI: In lecture 06, every echo had a time and a loudness. "Now every echo has a direction too." Once echoes have directions, an antenna array can tell them apart. Hold one question through this lecture: why can a two by two array still carry only one stream? By the end you'll be able to answer it from the geometry.

## S2 Concept: clusters and angles (target 140 s)
[Screen] A base station, a phone, and bundles of rays between them.

ANI: Why do angles matter? Because a multiple-antenna link, M I M O, can send several parallel streams, called layers, only if the paths look different at different antennas. Directions are what make them different.

"A clustered delay line model, C D L, is a list of clusters." "Each cluster has a delay, a power, and four angles:" Four terms, defined once. Azimuth is the horizontal angle, like a compass bearing. Zenith is the vertical angle, measured down from straight up. Each cluster has an azimuth and a zenith of departure at the base station, called A O D and Z O D, and an azimuth and a zenith of arrival at the phone, A O A and Z O A.

"Inside each cluster, twenty rays fan out around those mean angles." So a cluster is not one ray. It's a bundle. "Three G P P defines five of them, C D L A through C D L E," "C D L D is a line of sight profile, with a strong direct cluster." And as with the tapped delay lines, the delays are normalized: set the delay spread and the whole profile scales.

That's the first learning goal: a C D L model is clusters, each with a delay, a power, and four angles, and twenty rays per cluster.

## S3 Code beat B1: clusters and the channel object (target 110 s)
[Screen] Demo section B1: printed cluster table summary, then the delay-angle scatter.

ANI: The demo builds an N R CDL Channel with profile C D L A, thirty nanoseconds delay spread, at four gigahertz. As in lecture 06, a named profile's cluster table comes from the channel's info function. The script prints the number of clusters and the strongest one.

Then it draws what a tapped delay line can't: each cluster as a point, delay across, arrival azimuth up, marker size for power. Clusters spread across both time and direction.

[PAUSE — self-check] The Try line switches the profile to C D L D. Before you run it, predict what changes on the scatter.

ANI: A strong direct cluster appears, the line-of-sight path, standing well above the rest. T D L A never had one.

## S4 Code beat B2: the arrays live on the channel (target 120 s)
[Screen] Demo section B2 printout.

ANI: "In the toolbox, the arrays live on the channel, not on the carrier." Transmit Antenna Array and Receive Antenna Array are properties of the channel object. "Transmit Antenna Array and Receive Antenna Array take a size of five numbers:" "rows, columns, polarizations, then panel rows and panel columns." Polarization count is one or two.

Worked example, for the second learning goal. "The default is two by two, with two polarizations, on one panel, so eight elements." Two times two times two times one times one. The demo sets the transmit size to two, two, one, one, one: four elements. The receive size is two, one, one, one, one: two elements.

Then it draws one sample and prints the size of the path gains. The order is time, then path, then transmit element, then receive element. So one sample gives one, by the number of clusters, by four, by two. Change the array and every path gain the channel draws changes size with it.

[PAUSE — self-check] Set a two by two panel on both sides, with one polarization. Predict the last two dimensions of the path-gain array before it prints.

ANI: Four and four. Lecture 09 builds arrays with the Phased Array System Toolbox and steers them; here, set the size on the channel.

## S5 Code beat B3: polarization and XPR (target 120 s)
[Screen] Demo section B3 printout.

ANI: "An antenna element can come in two polarizations." "A ray sent on one polarization leaks some power into the other." "The cross polarization ratio, X P R, says how much weaker that leak is." "Here's the invariant: it's a power ratio," "so the cross path is weaker, but never zero."

Worked example, for the third learning goal. C D L A's X P R is ten decibels. Ten decibels is a power ratio of ten to the power of ten over ten: ten. So the leak carries about a tenth of the co-polar power. The demo uses one dual-polarized element at each end, set to vertical and horizontal so the leak is easy to see. That gives a two by two channel: same polarization on the diagonal, leakage off it. The script prints the table's X P R next to the measured diagonal-to-off-diagonal power, from one draw. They should land in the same range, not match exactly.

The default slants are plus and minus forty-five degrees. With those, co-polar and cross-polar powers come out equal on average, which is why the demo switches to vertical and horizontal.

[PAUSE — self-check] The Try line switches to C D L C, whose table X P R is seven decibels. Predict the measured ratio as a plain number.

ANI: Ten to the point seven is about five. The leak now carries about a fifth of the power, so the two polarizations are less separate.

## S6 Code beat B4: correlation and the rank trap (target 170 s)
[Screen] Demo section B4 printout, then the singular-value comparison.

ANI: "So more antennas always mean more streams? Here's the counterexample." "Pack eight elements close together, and let every cluster arrive from nearly one angle." "Then every element hears almost the same signal with a fixed phase step."

Two terms make this precise. Spatial correlation measures how alike two elements' signals are, from zero for unrelated to one for identical up to a fixed phase. Rank is the number of usable parallel streams. You read it from the singular value decomposition, S V D, which splits the channel matrix into independent directions with a strength for each, the singular values. Rank is the count of singular values that aren't negligible.

[PAUSE — self-check] A two by two channel has singular values of three and point zero three. How many usable streams does it really offer?

ANI: One. The second direction is a hundred times weaker in amplitude, ten thousand times in power, so it's negligible in practice.

A preview of lecture 09. A plane wave from angle theta on a two-element array, half a wavelength apart, reaches the second element with a phase step of pi times the sine of theta. That pair of phases, one and that step, is the steering vector.

Worked example, for the fourth learning goal. The demo builds a toy channel from one direction, twenty degrees: the steering vector times its own conjugate transpose. Every column is the same direction. Its singular values are two and zero. One stream, however many elements. The script asserts the second value is essentially zero. "The columns of the channel matrix line up, and the matrix is close to rank one."

Then it draws a real C D L A two by two snapshot. It sums the path gains at one moment, which gives the channel at a single frequency, and ignores delay. It prints the ratio of the second singular value to the first, for the toy and for the C D L A draw.

[PAUSE — self-check] Before it prints: will the C D L A ratio be near zero, like the toy, or clearly above it?

ANI: Clearly above it. C D L A's clusters arrive over a wide spread of angles, so the elements see different mixtures, and two streams are possible. "Spatial correlation depends on two things:" "how far apart the elements sit, measured in wavelengths," "and how wide the spread of angles is that the clusters arrive from."

[PAUSE — self-check] The Try line sets Angle Scaling to true and all four angle spreads to one degree. Predict what happens to the ratio of singular values.

ANI: It collapses toward the toy. Narrow spread means high correlation and near rank one. More antennas still give gain toward one direction, but not more streams. That answers the opening question.

## S7 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Four things to keep. A cluster is a bundle of twenty rays, not one ray, and C D L adds four angles to each delay and power. The arrays live on the channel object, with a five-number size. X P R is a finite power ratio: ten decibels is a tenth of the power, never zero. And a narrow angle spread on a tight array means high correlation and a channel close to rank one. Make the channel, shrink the angle spreads, and watch the second singular value fall.

---
## Notes for Showrunner
- The post-fix demo B4 compares a rank-1 toy with one CDL-A snapshot. It doesn't assert narrow vs wide correlation as the plan says; the narrow case is the Try.
- Lyric L62–63 says a phased array object can be handed to the channel, while the demo's B2 comment says a Phased Array ULA 'does not plug in here'. I avoided both claims; please have that checked.
- L72 is not quoted (tone note).
