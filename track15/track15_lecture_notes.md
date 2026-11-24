# Track 15 "End to End" — lecture notes

Companion to [`track15_demo.m`](track15_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Not covered in the album** (named by the generator only): **BWP** (bandwidth part) — a contiguous block of the carrier's RBs that a UE is configured to use. **CORESET** — the time-frequency region where PDCCH is sent. **PDCCH** — the downlink control channel that carries scheduling grants (DCI). `cfg.PDSCH{1}` is an `nrWavegenPDSCHConfig` (generator config), not an `nrPDSCHConfig`.

## Cold open (plan S1, D2-adjusted list)

ANI: Fourteen lectures, fourteen pieces: a grid, a waveform, a sync block, a code, a shared channel, two channel models, an estimate, beams, sounding, a full link, position, orbit, and an imperfect radio. Today all of them go into one scenario.

## B1. One config, one waveform

**Key idea.** The album ends where a real stack starts: one downlink config and one call to nrWaveformGenerator. That object already holds the PDSCH, the DM-RS, the BWP and (optionally) an SSB. The lecture reads the generator's own ResourceGridInCarrier and the waveform length, rather than rebuilding a competing handmade grid.

**Math.**

NumSubframes = 10 should be 10 ms of samples at the generator's SampleRate. Occupied REs are whatever the config actually enabled (PDSCH, and nothing else once SSB is off and you have not added CSI-RS).

**Lyric** (certified spelling):

> L9: Start with N R DL Carrier Config: the spacing, the grid size, the band.
> L10: Put the sync burst and the shared channel into that same config,
> L11: and N R Waveform Generator hands back one waveform with everything in its place.

**What the output or plot shows.** Printed Nfft, sample rate, sample count, grid size and occupied-RE count, with a 10 ms length assert.

**Check your understanding.** Your handmade PDSCH-only grid disagrees with ResourceGridInCarrier. Who should you trust, and what might you have forgotten?

**Answer.** Trust the generator. A leftover CORESET, PSS or CSI-RS in the config will occupy REs your handmade grid never drew.

## B2. Make the radio real, in hardware order

**Key idea.** Impairments are not a bag you sprinkle in any order. One order is used by the code, these notes and the animation: Tx baseband IQ imbalance → Tx PA (memoryless nonlinearity) → channel (identity here) → receiver thermal noise → phase noise of the *receiver* local oscillator (hence after the noise). Putting thermal noise before the PA invents distortion the radio would not see. Mapping a single-port generator waveform onto a multi-element panel is not specified (VERIFY); this demo stays on a single antenna and does not invent a panel mapping.

**Math.**

Hardware order used here: IQ -> PA -> (identity channel) -> AWGN -> phase noise. Each stage has an on/off flag for B4.

**Lyric** (certified spelling):

> L13: Phase noise from Comm dot Phase Noise, an I Q imbalance from I Q imbal,
> L14: and the amplifier from Comm dot Memoryless Nonlinearity, backed off from its peak.
> L17: Then the air. N R CDL Channel, with a panel array on the transmit side,
> L19: Then the receiver's own noise, from Comm dot Thermal Noise.
> L48: The amplifier lives in the transmitter, so it only ever sees the transmitter's own waveform.
> L51: Every impairment goes where it happens in the hardware, nowhere else.

**What the output or plot shows.** A printed statement of that order, and a note that the waveform is single-port.

**Check your understanding.** Why is putting thermal noise before the PA a different (and usually wrong) radio?

**Answer.** The PA would then amplify the noise as if it were signal, and the compression would act on a noisier input than the receiver actually sees.

**Animation cue A1** (lines L47–L51). Each impairment goes where it happens in the hardware; a PA after the channel and noise compresses them too, so it models a different radio — A block chain: IQ → PA → channel → noise → Rx-LO phase noise (same order as the code). The PA block is dragged to the end. Fading and noise now pass through its compression curve, and an EVM meter jumps. The PA snaps back into place.

## B3. The plumbing invariant: all off, bits back

**Key idea.** With every impairment off, the bits that the generator put on the air must come back. The documented place to read the transmitted transport-block bits is info.WaveformResources.PDSCH(k).Resources(s).TransportBlock (API_VERIFY T15 fix). Do not rebuild a fallback bit source, and do not compare against a fresh randi block.

**Math.**

All-off: decode slot 0 against that TransportBlock field. $\texttt{blkerr}$ must be false and the bits must match. The invariant is allowed to fail once an impairment is turned on, and must return when it is turned back off.

**Lyric** (certified spelling):

> L28: On the far side, run it all backwards.
> L29: N R Timing Estimate finds the start. N R OFDM Demodulate gives back the grid.
> L34: Here's the invariant that keeps you honest:
> L35: turn every impairment off, give it a clean channel and plenty of signal,
> L36: and the chain must hand back exactly the bits you sent.
> L37: If it doesn't, the bug is in the plumbing, not the physics.
> L64: Open the toolbox. Build the whole chain with every impairment off, and check the bits come back.

**What the output or plot shows.** Printed PDSCH / resource index, TBS, blkerr and a bit-match flag. B3 now decodes the output of the same `radioChain` as B4, so the B2 flags drive the Try: all flags off → asserted bit-exact; any flag on → blkerr is printed and the invariant is allowed to fail.

**Check your understanding.** You compare the decoded bits to a new randi block of the same length and they disagree. Is the decoder broken?

**Answer.** Not necessarily. You compared against the wrong bits. Use the TransportBlock field the generator already stored.

## B4. One change at a time, then all together

**Key idea.** Turn on one impairment, measure EVM (or BLER), turn it off, then turn on the next. Independent residual EVMs should add in power, which is the Track 14 triangle reused as the album close. Finally turn them all on and compare the cascade to the rss of the parts. This is a diagnostic habit, not a claim that every radio is a linear sum of its bugs. Adding EVM percentages instead of rss-ing them is still the usual mistake.

**Math.**

$$\mathrm{EVM}_{\mathrm{all}}\stackrel{?}{\approx}\sqrt{\mathrm{EVM}_{\mathrm{IQ}}^2+\mathrm{EVM}_{\mathrm{PA}}^2+\mathrm{EVM}_{\mathrm{AWGN}}^2}.$$
A five-row table: IQ only, PA only, AWGN only, Rx phase noise only, and all four on (channel identity); then the rss of the four singles versus the cascade. The AWGN row is checked against T02's formula $\mathrm{EVM}\approx 100\sqrt{K_{\mathrm{occ}}/(N_{\mathrm{fft}}\,\mathrm{SNR})}$.

**Lyric** (certified spelling):

> L55: So change one thing at a time, and keep the random seeds fixed.
> L56: Turn on phase noise alone, then I Q imbalance alone, then both.
> L57: Remember that independent pieces add in power:
> L58: three percent and four percent make about five, not seven.
> L61: Then sweep the signal to noise ratio, and watch the waterfall move as each flaw comes in.
> L65: Turn on one impairment, and write down the E V M and the block error rate.

**What the output or plot shows.** Printed EVM for each single impairment and for the cascade, plus the rss prediction. Phase noise now has its own row, so "all on" really is every stage the chain has (the channel stays identity), and T02's noise-EVM prediction is printed next to the AWGN row.

**Check your understanding.** You leave every knob on, see a mess, and do not know which knob did it. What does this beat tell you to do first?

**Answer.** Turn them off, then on one at a time, measure, and only then turn them all on and compare to the rss of the parts.

**Animation cue A2** (lines L57–L58). Independent pieces add in power: sqrt(3² + 4²) = 5 — Reuse the T14 A3 right-triangle asset with a new label. No new render.


## Album recap (plan S6; one invariant per track, D2 order)

| Track | Invariant |
|---|---|
| P00a Grid and Waveform / P00b Map of the Link | Spoken foundations: sample counts and the map of the link (no song). |
| T01 Two to the Mu | SCS = 15·2^μ kHz; slot = 1/2^μ ms; a fixed time × bandwidth box holds the same number of REs at every μ. |
| T02 Copy the Tail | An echo shorter than the CP becomes one complex gain per tone; EVM grades it. |
| T03 Find Me in the Noise | PSS → timing and N_ID(2); SSS → N_ID(1); cell ID = 3·N_ID(1) + N_ID(2). |
| T04 Every Check Agrees | BG rule by (A, R); K = 22·Zc or 10·Zc; passing every LDPC check is not proof — the CRC is. |
| T05 Say It Again | HARQ resends the same TBS with a new RV and soft-combines. |
| T06 Taps in Time | Tap delays = normalized delays × delay spread; the first tap is not always the strongest; f_D = v/λ. |
| T07 Learn the Channel | Raw pilot ratio → interpolate → MMSE → csi-weighted soft bits. |
| T08 Clusters and Angles | Narrow angle spread on a tight array → high correlation → rank ≈ 1. |
| T09 Steer the Beam | A phase ramp steers; gain 10·log10 N at fixed power; d > λ/2 → grating lobes. |
| T10 Sound It Out | SRS up, CSI-RS down; TDD: H_ul = H_dlᵀ once both ends are calibrated. |
| T11 One in Ten | CQI targets 0.1 first-transmission BLER; HARQ lowers the residual; ~100 errors per point. |
| T12 How Far | 30 cm per ns; TDOA → hyperbolas; RTT cancels clocks; NLOS reads long. |
| T13 Signals from Orbit | RTT 4d/c transparent; LEO Doppler tens of kHz; pre-compensate from GNSS + ephemeris. |
| T14 Mirror Image | CPE + ICI; image at −k ≈ IRR dB down; EVMs add in power; back-off has an optimum. |
| T15 End to End | All off → bits back; then one flaw at a time; rss the parts. |

ANI (plan S6): That's the whole path. The numerology sets the grid. OFDM and the cyclic prefix make one tap per tone. The sync block names the cell, and the shared channel carries blocks with HARQ. LDPC protects them, pilots let us estimate the channel, and the channel models give delays, angles and polarizations. Beams, sounding, positioning and satellites stretch the same ideas. Real radios add flaws you can measure. Build the chain with everything off, check the bits come back, then add one flaw at a time.

Timing (resolved by M, 2026-11-18 4:55 PM EST): S6 album recap is 60–90 s; the S7 outro is a separate segment, not part of the recap window.
