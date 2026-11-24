# Track 03 "Find Me in the Noise" — lecture notes

Companion to [`track03_demo.m`](track03_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Prereqs (used here, not taught here).** CRC and LLR (soft bits) are taught in T04. A *polar code* is the error-correcting code 5G uses for control and broadcast (PBCH/BCH); it is not covered in the album, so treat nrBCH / nrBCHDecode as a box. *Lmax* is the number of SSB candidates in a 5 ms burst (4, 8 or 64; B5). B1–B4 use Lmax = 8 (Case A above 3 GHz); B5's generator uses Case A at or below 3 GHz, which is Lmax = 4. *Recording note:* the plan speaks B3 before B2; B3 runs standalone, so record it first.

## Cold open (plan S1)

ANI: A phone switches on knowing nothing: no cell ID, no timing, not even where the frame starts. Today's question is how it finds a cell in the noise. The answer takes four steps, each unlocking the next: PSS, SSS, DM-RS, MIB.

## B1. Build one block by hand

**Key idea.** The phone does not yet know the cell ID or the frame timing; this tile is what it will search for. An SS/PBCH block is a 240-by-4 tile assembled from four known pieces: PSS, SSS, PBCH and PBCH DM-RS, with fixed lengths 127, 127, 432 and 144. There is no nrSSBConfig (that page is 404); the burst lives later on nrWavegenSSBurstConfig / nrDLCarrierConfig.SSBurst.

**Math.**

SSB tile: $240$ subcarriers $\times$ $4$ OFDM symbols.
PSS/SSS: $127$ symbols each (PSS on SSB symbol 0, subcarriers $56\ldots 182$; SSS on symbol 2).
PBCH: $432$ QPSK symbols; PBCH DM-RS: $144$ symbols; BCH codeword $E=864$ bits.

**Lyric** (certified spelling):

> L8: It's four symbols long and two hundred forty subcarriers tall.
> L9: Symbol zero holds the primary sync, a hundred twenty-seven tones in the middle.
> L10: Symbol two holds the secondary sync, the same width,
> L13: and every fourth tone of it is a reference signal.
> L60: Build one block from N R PSS, N R SSS, N R PBCH and its reference signal.

**What the output or plot shows.** Printed lengths, placement asserts, and a colour map of one SSB (PSS, SSS, PBCH, DM-RS).

**Check your understanding.** Is an SSB one library object you construct with nrSSBConfig?

**Answer.** No. That function does not exist. You build the 240-by-4 tile from the PSS, SSS, PBCH and DM-RS primitives, and the burst is configured later on the downlink carrier.

**Animation cue A2** (lines L8–L13). SSB layout: 4 symbols × 240 subcarriers; PSS and SSS 127 wide; PBCH 576 REs = 432 + 144 — Build the block layer by layer: PSS in symbol 0, SSS in symbol 2, PBCH fills symbols 1 and 3 plus the edges of symbol 2, then the DM-RS dots every 4th tone.

## B2. Find the cell: PSS in time, then SSS

**Key idea.** It correlates three PSS hypotheses against the received waveform; the tallest peak gives N_ID^(2) and a sample offset. After demodulating at that offset, a 336-entry SSS search completes N_ID^(1) and the PCI. At 10 dB with no multipath, the timing may land one sample off the planted delay.

**Math.**

$$\mathrm{PCI}=3N_{\mathrm{ID}}^{(1)}+N_{\mathrm{ID}}^{(2)},\quad N_{\mathrm{ID}}^{(2)}\in\{0,1,2\},\ N_{\mathrm{ID}}^{(1)}\in\{0,\ldots,335\}.$$
Three PSS correlations, then 336 SSS scores (not 1008 PCI hypotheses). The planted delay in this demo is D = 333 samples; the assert allows plus or minus 1.

**Lyric** (certified spelling):

> L28: Correlate the samples with each primary sequence.
> L29: The tallest peak tells you two things at once:
> L30: where the block begins, and which of the three you heard.
> L31: Then take the secondary sync and try all three hundred thirty-six.
> L62: N R Timing Estimate should find the shift.

**What the output or plot shows.** Printed PCI, N_ID^(1), N_ID^(2) and timing next to the known pci = 397 and D = 333, with a VERIFY comment on the plus-or-minus-1-sample window. A new figure draws the three PSS correlation curves with the planted D marked: the "find" made visible. Assert messages now name the step that failed (PSS timing, PSS ID, SSS ID).

**Check your understanding.** After the PSS peak has given you N_ID^(2), how many SSS hypotheses do you still need to search?

**Answer.** 336, the values of N_ID^(1). Searching all 1008 PCIs would redo work the PSS already finished.

## B3. The trap: three cells, one PSS

**Key idea.** PCI = 3*N_ID^(1) + N_ID^(2) is a bijection onto 0..1007. Cells 0, 3 and 6 therefore share one PSS, and only the SSS tells them apart. A search that stopped after the PSS would merge them. There are only three PSS sequences, not 1008.

**Math.**

The map $(N_{\mathrm{ID}}^{(1)},N_{\mathrm{ID}}^{(2)})\mapsto 3N_{\mathrm{ID}}^{(1)}+N_{\mathrm{ID}}^{(2)}$ hits each integer in $0\ldots 1007$ exactly once ($336\times 3=1008$).
$$\texttt{nrPSS}(0)=\texttt{nrPSS}(3)=\texttt{nrPSS}(6),\qquad \texttt{nrSSS}(0)\ne\texttt{nrSSS}(3).$$

**Lyric** (certified spelling):

> L33: Here's the trap: cells zero, three and six sing the same primary sequence.
> L35: Only the secondary pulls them apart.

**What the output or plot shows.** The invariant assert over all 1008 values, plus the three-cell PSS/SSS counterexample printed as a one-line confirmation.

**Check your understanding.** Do 1008 physical cell IDs mean 1008 different PSS sequences?

**Answer.** No. There are three PSS sequences, one for each N_ID^(2). The SSS carries the rest of the identity.

**Animation cue A1** (lines L20 / L22–L23). PCI = 3·N_ID(1) + N_ID(2); 336 × 3 = 1008, a bijection — A 336-row × 3-column lattice of cells, each labelled with its PCI. Highlight 397 at row 132, column 1. Then show column 0 lighting up rows 0, 1, 2 as PCIs 0, 3, 6, which share a PSS.

## B4. Which beam found me: DM-RS index and MIB

**Key idea.** After the PCI is known, eight PBCH DM-RS hypotheses (ibar_SSB = 0..7 when Lmax = 8) give the three LSBs of the SSB index, which is the beam that found the phone. A one-tap channel from those DM-RS symbols then lets PBCH / BCH decode the MIB and check its CRC. The official nrBCHDecode example compares bit2int(lsbofsfn, 4) to mod(sfn, 16). *Correction:* with Lmax = 4, ibar_SSB = i_SSB + 4·n_hf (TS 38.211 §7.4.1.4.1), so the DM-RS carries two SSB-index bits **and** the half-frame bit, not "only two LSBs."

**Math.**

For $L_{\max}=8$, $\bar{i}_{\mathrm{SSB}}=v=(\mathrm{SSB\ index}\bmod 8)$.
BCH CRC must pass, and the decoded 24 MIB bits must equal the bits that were encoded. SFN 113 in the 38.212 bit order (4th LSB first) predicts a 4-bit nibble that the demo prints beside the toolbox field.

**Lyric** (certified spelling):

> L51: With more than four blocks, its reference signal comes in eight versions,
> L52: and the one that matches gives the low three bits of the block index,
> L54: Decode it and check the CRC.
> L63: Decode the master block and check every bit.

**What the output or plot shows.** Printed vHat, a passing CRC, a MIB match, and two printed conventions for the SFN LSBs (spec bit order vs the documented bit2int example). The toolbox convention is printed, not asserted, so a run can confirm it. Both SFN lines are tagged `[aside]`: a toolbox-convention check for M's run, not lecture content.

**Check your understanding.** Why not skip the DM-RS search and decode PBCH against a guessed scrambling?

**Answer.** The DM-RS hypotheses carry the SSB-index LSBs, which also select the PBCH scrambling. The wrong v descrambles the wrong way and the CRC fails.

## B5. The burst: Cases and the 20 ms count

**Key idea.** A cell does not send one SSB; it sends a burst of candidate blocks in the first 5 ms of a period (here 20 ms). Cases A to G in TS 38.213 clause 4.1 give the first-symbol indexes and Lmax (4, 8 or 64). Case A at or below 3 GHz has Lmax = 4 at first symbols 2, 8, 16, 22; with Period = 20 that pattern appears once in 20 ms. PDSCH and PDCCH are disabled. R2024b docs confirm nrDLCarrierConfig's default CSI-RS is disabled, and a CORESET carries nothing without a PDCCH, so only the SSB is on air. *Try (corrected):* set `Period = 5` or `TransmittedBlocks = [1 0 0 0]` and write down the occupied-symbol list first. `expected` is now derived from TransmittedBlocks and Period, and both lists print, so a correct prediction passes.

**Math.**

Half-frame length in symbols: $14\cdot 2^{\mu}\cdot 5$. Every candidate block of four symbols must end inside that half frame.
Case A, $L_{\max}=4$, 20 ms: occupied symbols $\{2,3,4,5\}\cup\{8,\ldots,11\}\cup\{16,\ldots,19\}\cup\{22,\ldots,25\}$.

**Lyric** (certified spelling):

> L43: Blocks come in a burst, all inside half a frame, five milliseconds.
> L46: Case A through Case G name the patterns, picked by spacing and band.
> L47: A phone that knows nothing may assume the burst returns every twenty milliseconds.
> L64: Then predict which symbols light up in twenty milliseconds, and count them.

**What the output or plot shows.** A printed table of cases (SCS, Lmax, last block end), then a generator check that the occupied symbols match the Case A list and nothing else, with expected and measured lists printed. The leftover-signal VERIFY is resolved (docs) and is now a NOTE.

**Check your understanding.** If Period = 20 ms, should you expect a new Case A burst every 5 ms?

**Answer.** No. The candidates sit in the first 5 ms of each 20 ms period. The other 15 ms of the period are silent for SSB.

**Animation cue A3** (lines L43 / L47). Case A: blocks at symbols 2, 8, 16, 22 within a 5 ms half frame; repeat every 20 ms — A 20 ms timeline with the first half frame zoomed. Four 4-symbol blocks light up, then the line stays dark until 20 ms.


## Recap (plan S8)

ANI: Four steps, four printed results. PSS gives N_ID(2) and the timing. SSS gives N_ID(1), so PCI = 3·N_ID(1) + N_ID(2). PBCH DM-RS gives the SSB-index bits, the beam that found you. And BCH gives the MIB, with a CRC. Remember the trap: cells 0, 3 and 6 share one PSS, and only the SSS tells them apart.
