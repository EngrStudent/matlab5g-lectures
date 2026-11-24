# Track 07 "Learn the Channel" — lecture notes

Companion to [`track07_demo.m`](track07_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Prereqs / terms.** D2 order puts T06 "Taps in Time" just before this track, so the TDL channel (delay profile, delay spread, path gains, path filters) is already taught; here it is a black-box "some multipath". The LDPC decoder that consumes these soft bits is T04. MMSE: the estimator that minimises mean-squared error (assumed background).

## Cold open (plan S1)

ANI: The grid went out clean, and it came back bent. Every tone got a gain and a twist on the way. To undo that, the receiver first has to measure it. Today we estimate a channel from a handful of known symbols, then undo it without making the noise worse.

## B1. Pilots and the raw ratio (`nrPDSCHDMRS`, `nrExtractResources`)

**Key idea.** The phone does not start with a full grid of known symbols. It only knows the DM-RS. The raw ratio Y_p / X_p on those pilot REs is the starting picture of H; everything else is interpolation and averaging. A single noisy ratio is not yet a channel estimate. Without H, every tone's constellation is rotated and scaled, so coherent detection needs H first.

*Try (corrected).* Change `DMRSAdditionalPosition` to 0 or 2 to change pilot density in time. Halving the PRB allocation only narrows the band; DM-RS density per PRB is fixed by the DM-RS type.

**Math.**

$$H_p = Y_p / X_p \quad\text{on the DM-RS REs only.}$$

**Lyric** (certified spelling):

> L7: The sender plants symbols you already know: the demodulation reference signals.
> L8: At those spots, what you receive is the channel times the known pilot, plus noise.
> L9: Divide what you got by what was sent, and you have a raw guess of the channel there.
> L59: Run a slot through a fading channel. Pull the pilots out of the grid with N R Extract Resources.

**What the output or plot shows.** A print of the DM-RS RE count and the mean and standard deviation of |raw H|, plus a scatter plot of those raw ratios.

**Check your understanding.** Why can't the phone form Y/X on every PDSCH RE and call that the estimate?

**Answer.** It does not yet know the data symbols X on those REs. Only the pilots are known in advance.

## B2. Average, interpolate, grade (`nrChannelEstimate` vs `nrPerfectChannelEstimate`)

**Key idea.** A useful estimate averages neighbouring pilots and interpolates the gaps so that every PDSCH RE has an H. nrChannelEstimate is the toolbox path from a reference-signal grid to that picture. Its pre-interpolation estimator is commonly described as least squares, but that internal name is not on the documentation page (VERIFY). Score the estimate on the data REs, not only on the pilots.

**Math.**

Compare $\texttt{nrChannelEstimate}$ to $\texttt{nrPerfectChannelEstimate}$ when path gains are available. Residual error should be judged on the PDSCH REs that will actually be equalized.

**Lyric** (certified spelling):

> L27: N R Channel Estimate takes an averaging window,
> L28: F pilots wide in frequency and T pilots wide in time, odd numbers both.
> L29: Leave them at zero, and it picks the window from its own noise estimate.
> L31: and hands you the estimate, the noise variance, and the window it used.
> L60: Estimate with the window at zero, then with a wide window,
> L61: and compare both to the perfect estimate.

**What the output or plot shows.** Printed noise variance, mean |Hest|, the RMS difference to `nrPerfectChannelEstimate` on data REs and on pilot REs, and a |H| vs subcarrier overlay of estimate and perfect.

**Check your understanding.** If you only score the estimate on the pilot REs, what error have you hidden?

**Answer.** Interpolation error on the data REs you actually equalize.

**Animation cue A1** (lines L8–L12). At pilots Y = H·X + N, so Ĥ = Y/X there; elsewhere interpolate — A grid with pilot dots. Each pilot's Ĥ pops out as a ratio, then a smooth surface fills in between them.

**Animation cue A2** (lines L32–L33). Averaging helps only while H is nearly flat across the window — A sliding window over two curves. On a flat channel the noisy points average onto the true curve. On a rippling channel the same window flattens the ripple, so the bias grows.

## B3. Zero forcing vs MMSE (`nrEqualizeMMSE`)

**Key idea.** Zero forcing divides out H and also boosts the noise wherever |H| is small. MMSE shrinks those gains on purpose, so the residual error is usually smaller when the estimate or the SNR is imperfect. On a strong RE the two are almost the same. nrEqualizeMMSE's signature is documented; the exact textbook Wiener formula is not on the page (VERIFY). Compare residual EVMs rather than asserting an algebraic form.

**Math.**

ZF: $\hat{X}=Y/\hat{H}$.
MMSE: $\texttt{nrEqualizeMMSE}(Y,\hat{H},\sigma^2)$. Compare $\mathrm{EVM}_{\mathrm{ZF}}$ and $\mathrm{EVM}_{\mathrm{MMSE}}$ on the same symbols.

**Lyric** (certified spelling):

> L43: Now undo it. Zero forcing just divides by the channel.
> L44: But here's the counterexample: on a tone in a deep fade, the channel is almost zero,
> L47: It multiplies by the conjugate of the channel over its power plus the noise variance.
> L52: N R Equalize MMSE takes the received symbols, the channel estimate, and the noise variance,

**What the output or plot shows.** Printed EVM after ZF and after MMSE on the same PDSCH symbols (TDL-C 300 ns, 12 dB, so some tones fade), plus a per-RE |error| vs |H| scatter where ZF errors blow up at small |H|.

**Check your understanding.** Is MMSE better than ZF on every resource element?

**Answer.** No. It is better on average, especially where |H| is small or the SNR is modest. On a strong RE the two almost agree.

**Animation cue A3** (lines L45–L49). ZF: x̂ = Y/H; MMSE: x̂ = H*·Y/(\ — H\

## B4. Soft bits out

**Key idea.** The decoder does not want equalized symbols, it wants soft bits whose magnitude is a confidence. nrPDSCHDecode takes the MMSE-equalized symbols plus a noise variance and returns LLRs; weighting them by the equalizer's `csi` output marks faded REs as less reliable. These LLRs are what the T04 LDPC decoder consumes (the demo's payload is random bits standing in for a codeword, so it counts raw bit errors).

**Math.**

Soft-bit count should equal $G$ from $\texttt{nrPDSCHIndices}$. A wrong noise variance still produces bits, but with the wrong confidences.

**Lyric** (certified spelling):

> L53: and gives back the equalized symbols with a reliability for each one.
> L56: Then the demodulator turns the equalized symbols into soft bits for the decoder from last time.

**What the output or plot shows.** Bit errors from the equalized soft bits versus decoding the raw, unequalized symbols (asserted: equalized < raw), mean |LLR|, and an LLR histogram.

**Check your understanding.** What happens if you throw away the noise variance or the channel estimate and decode as if every symbol were equally reliable?

**Answer.** The decoder loses its ability to trust strong REs more than faded or noisy ones, and performance drops, especially on a frequency-selective channel.


## Recap (plan S7)

ANI: Known pilots give a raw ratio, received over sent. Average while the channel stays flat, then interpolate to cover the grid. Equalize with MMSE, because it backs off where the channel fades instead of amplifying noise. Then pass soft bits on to the decoder. Run a slot through a fading channel, try both windows, and see whether the constellation clouds tighten.

Script closing print: raw ratio → interpolate → equalize → soft bits; reused in T11's full link.
