# Track 14 "Mirror Image" — lecture notes

Companion to [`track14_demo.m`](track14_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Units / terms.** Phase-noise level: dBc/Hz at a frequency offset (here −60 dBc/Hz at 10 kHz). IIP3: input third-order intercept point, in dBm (1 Ω reference). AM/AM, AM/PM: amplitude-dependent gain and phase. kTB: thermal noise power, k·T·B (−174 dBm/Hz at 290 K). IRR: image-rejection ratio, wanted/image power in dB. EVM budget: T02's 38.104 limit (8 % for 64-QAM) is what these flaws spend.

## Cold open (plan S1)

ANI: No real radio is perfect. Oscillators drift, mixers are slightly unbalanced, and amplifiers compress near the top of their range. Today we add each flaw on purpose, measure it, and learn the one rule for combining them.

## B1. Baseline and phase noise

**Key idea.** A clean OFDM grid has essentially zero EVM. Oscillator phase noise has a slow part, the common phase error (CPE) that rotates a whole symbol together and can be removed per symbol, and a fast part, inter-carrier interference (ICI) that leaks each subcarrier into its neighbours and is not removed by the CPE fix (the residual). Both differ from the image leak of B2. comm.PhaseNoise is the documented Communications Toolbox model. Score EVM against a limit only after removing a common phase if the noise is slow.

**Math.**

Baseline EVM is numerical zero with Windowing = 0. After phase noise, a per-symbol common-phase correction $e^{-j\hat{\theta}_\ell}$ should take most of a slow wander back off.

**Lyric** (certified spelling):

> L8: Comm dot Phase Noise models it with a level in decibels relative to the carrier per hertz,
> L10: The default is minus eighty at two kilohertz and minus a hundred at twenty kilohertz.
> L11: In OFDM, the slow part of that wander turns every subcarrier in a symbol
> L12: by the same angle, a common phase error, and a receiver can track it.
> L62: Open the toolbox. Make a sixty-four QAM waveform and measure its EVM with Comm dot E V M.

**What the output or plot shows.** Printed clean-round-trip EVM, then EVM with phase noise before and after the CPE fix, plus a constellation you can inspect in the figure windows from later beats.

**Check your understanding.** Every constellation is rotated. Is that automatically IQ imbalance?

**Answer.** No. A slow common phase (this beat) rotates a whole symbol together. IQ imbalance (B2) leaks a conjugate image onto the mirror subcarrier.

**Animation cue A1** (lines L11–L13). Slow phase wander rotates every subcarrier in a symbol by the same angle (CPE). Fast wander leaks each subcarrier into its neighbours — A constellation that rotates rigidly symbol by symbol, then is counter-rotated back to a still cloud. A second panel shows subcarrier spikes smearing into their neighbours, and that smear stays.

## B2. IQ imbalance: the image at −k

**Key idea.** An amplitude and phase mismatch between the I and Q rails leaks a complex-conjugate image onto the mirror subcarrier -k. iqimbal(x, A, P) is the documented model. For A = 0.5 dB and P = 2 deg, the image-rejection ratio is 29.46 dB and the EVM is 3.37% (API_VERIFY; official algorithm). The image is not at +k and not at DC.

**Math.**

Amplitude ratio $g=10^{A/20}$. Image-rejection ratio
$$\mathrm{IRR}=\frac{g^2+2g\cos P+1}{g^2-2g\cos P+1},\qquad \mathrm{IRR_{dB}}=10\log_{10}(\mathrm{IRR}),\quad \mathrm{EVM}=100/\sqrt{\mathrm{IRR}}.$$
For $A=0.5\,\mathrm{dB}$, $P=2^{\circ}$: $\mathrm{IRR}=29.46\,\mathrm{dB}$, $\mathrm{EVM}=3.37\%$.
(A first draft of the demo used $g=10^{0.5A/20}$ and would have given 32.91 dB / 2.26%; that factor is wrong for this official pairing and was corrected.)

**Lyric** (certified spelling):

> L16: Now split the signal into its two halves, in phase and quadrature.
> L17: They're supposed to match in gain, and sit exactly ninety degrees apart.
> L22: What you send on subcarrier k shows up again, faint, on minus k.
> L27: I Q imbal applies it: an amplitude imbalance in decibels,
> L29: Comm dot I Q Imbalance Compensator estimates it and takes it back out.

**What the output or plot shows.** Printed predicted IRR and EVM, asserted against 29.46 dB and 3.37%, plus a one-tone probe on row 60 (253 subcarriers *below* DC) whose image is printed on the mirror row 566 (253 above DC). The wanted/mirror ratio is asserted within 0.5 dB of the predicted IRR, and a one-symbol spectrum shows both spikes.

**Check your understanding.** You fill only subcarrier +k and look for the IQ leak at +k or at DC. Where should you look?

**Answer.** At the mirror subcarrier -k. That is where the conjugate image lands.

**Animation cue A2** (lines L22). IQ gain and phase mismatch puts an image of subcarrier k at −k — A spectrum with a single spike at +k. As the gain and phase mismatch sliders move, a faint mirror spike rises at −k. When the sliders return to match, it fades.

## B3. Independent impairments add in power

**Key idea.** When two impairments are independent and small, their residual EVMs add in power: EVM_tot^2 ≈ EVM_1^2 + EVM_2^2. That is the triangle this lecture will reuse in Track 15. Phase noise (after the B1 CPE fix, so only its ICI part remains) plus IQ imbalance is a clean pair to test it on. Adding the percentages themselves (3 + 4 is not 5) is the usual mistake.

**Math.**

$$\mathrm{EVM}_{\mathrm{tot}}\approx \sqrt{\mathrm{EVM}_1^2+\mathrm{EVM}_2^2}=\mathrm{hypot}(\mathrm{EVM}_1,\mathrm{EVM}_2).$$

**Lyric** (certified spelling):

> L51: Error vector magnitude ties it together. Take each received symbol, subtract the ideal one, and square the error.
> L55: Here's the invariant: independent impairments add in power, not in percent.
> L56: Three percent from one and four percent from another make five, not seven.
> L63: Measure with phase noise alone, then I Q imbalance alone, then both.
> L64: Square each piece, add the squares, and take the root.

**What the output or plot shows.** Printed EVM of phase noise alone, IQ alone, the cascade, and the rss prediction of the two singles.

**Check your understanding.** Two impairments measure 3% and 4% EVM alone. About what cascade EVM should you predict if they add in power?

**Answer.** 5%, the hypotenuse, not 7%.

## B4. The amplifier and the back-off U-curve

**Key idea.** An amplifier close to saturation bends the constellation (compression, AM/AM and AM/PM). Backing off the input cleans the EVM up, but eventually the signal falls toward the noise floor and EVM rises again: a U-curve. comm.MemorylessNonlinearity models the amplifier; the drive is set in absolute dBm against IIP3 = 10 dBm, and a fixed −50 dBm noise floor (standing in for the whole receive chain, raised above kTB ≈ −102 dBm in 15.36 MHz so both arms fit one sweep) is added after it. (v1 used comm.ThermalNoise at 290 K with an unset drive level, so the noise arm could be invisible.) 'More back-off is always cleaner' forgets the noise floor.

**Math.**

Sweep a relative input gain over a range that includes both compression and a noise-floor rise. The minimum of that U is a demo result, not a predicted number, and is printed.

**Lyric** (certified spelling):

> L30: Then the power amplifier. Near the top of its range, the gain compresses
> L32: Comm dot Memoryless Nonlinearity models that, with a cubic polynomial by default,
> L34: OFDM has big peaks, so you back the amplifier off to keep those peaks out of compression.
> L44: Every decibel of back-off lowers the distortion,
> L47: Error vector magnitude falls, bottoms out, and rises again.
> L48: The best operating point sits at the bottom of that curve, not at either end.

**What the output or plot shows.** A printed sweep of EVM vs absolute input power (−30 … +6 dBm), the minimum and its distance below IIP3, and a U-curve plot. Back-off is moving *left* on that axis. Try: `noiseFloor_dBm = -Inf` removes the left arm.

**Check your understanding.** You keep backing off 'to be safe' and the EVM gets worse, not better. What did you run into?

**Answer.** The noise floor. Once the amplifier is linear enough, further back-off just buries the signal in thermal noise.

**Animation cue A3** (lines L55–L56). Independent errors add in power: sqrt(3² + 4²) = 5 — Two perpendicular error arrows, 3 and 4, forming a right triangle with a hypotenuse of 5. Beside it, a "3 + 4 = 7" bar is crossed out.


## Recap (plan S7)

ANI: Phase noise gives a common rotation you can track, plus leakage you can't. I Q imbalance puts a mirror image at minus k. Amplifier compression trades against noise, so the best back-off sits in the middle. Independent errors add in power, so square, add, and take the root. Build a sixty-four QAM slot, add one flaw at a time, and check the sum of squares.

Script closing print: CPE vs ICI; image at −k at ≈ IRR; EVMs add in power; back-off has an optimum.
