# Track 05 "Say It Again" — lecture notes

Companion to [`track05_demo.m`](track05_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Prereqs.** D2 order: T04 "Check Bits" comes before this track, so LDPC, CRC and LLRs (soft bits) are already taught. *Rate matching*: selecting / repeating bits from the LDPC mother codeword's circular buffer so the output is exactly G bits; a *redundancy version (RV)* is a start point in that buffer (not covered in depth). *HARQ* resends the same block and soft-combines; *link adaptation* chooses the MCS. They are separate jobs.

## Cold open (plan S1, D2-adjusted)

ANI: Last time a block arrived with a CRC, and the check failed. Today's question is what the sender does next. It doesn't start over. It says the same block again, coded differently, and the receiver adds the two tries together.

## B1. How big is a block? (`nrTBS`)

**Key idea.** Start from the failure in B3: a block that fails must be resent unchanged, so first we need its size. The transport-block size is not simply 'the number of PDSCH bits.' It is computed (TS 38.214 §5.1.3.2) from a quantized $N_{\text{info}}=N_{RE}\,R\,Q_m\,\upsilon$, with a lookup table only for $N_{\text{info}}\le 3824$. Its inputs are the modulation, the layer count, the allocated PRBs, the reserved-RE count (NREPerPRB) and the target code rate. The CRC length then follows from that TBS: 24 bits if A > 3824, else 16. G is the coded payload the rate matcher will emit; TBS is the information word.

**Math.**

$$\mathrm{TBS}=\texttt{nrTBS}(\text{mod},\,N_{\mathrm{lay}},\,N_{\mathrm{PRB}},\,N_{\mathrm{RE/PRB}},\,R),$$
with $N_{\mathrm{PRB}}=\lvert\mathrm{PRBSet}\rvert$ and $N_{\mathrm{RE/PRB}}$ from $\texttt{nrPDSCHIndices}$ info (DM-RS already reserved).
$$L_{\mathrm{CRC}}=24\text{ if }A>3824,\ \text{else }16 \quad\text{(TS 38.212 §7.2.1)}.$$

**Lyric** (certified spelling):

> L8: A transport block is a bag of bits handed down from above.
> L15: Ask N R TBS how big a block can be.
> L16: Give it the modulation, the layers, the resource blocks,
> L17: the resource elements per block, and the target code rate.

**What the output or plot shows.** Printed NREPerPRB, G, TBS and CRC length. *Predict first:* 24 × 132 × 2 × 0.48 ≈ 3041, so N_info′ = 3040 and the table gives TBS = 3104 (static estimate in the checks). The assert checks that G exceeds the TBS.

**Check your understanding.** Should nPRB be the BWP size or the number of allocated PRBs, and why does NREPerPRB matter?

**Answer.** nPRB is numel(PRBSet), the allocated PRBs, not necessarily the whole BWP. NREPerPRB already subtracts reserved REs such as DM-RS; using 12*14 would over-count.

## B2. The MCS table (`nrPDSCHMCSTables`)

**Key idea.** The MCS table is the agreed menu: each row names a modulation and a target code rate, and those two numbers go straight into nrTBS. A higher MCS on the same allocation must produce a larger TBS. Choosing the row is link adaptation, not retransmission. nrPDSCHMCSTables is R2024a. *Try (corrected):* change the two MCSIndex values to 9 and 10 (the QPSK → 16QAM boundary of QAM64Table) and predict whether the TBS jumps when the modulation doubles (hint: compare Qm·R for the two rows). Stay in QAM64Table; the 256-QAM table is the common mistake.

**Math.**

Pick a low row and a high row of $\texttt{nrPDSCHMCSTables.QAM64Table}$. On the same 24-PRB allocation, $\mathrm{TBS}_{\mathrm{high}}>\mathrm{TBS}_{\mathrm{low}}$ is asserted.

**Lyric** (certified spelling):

> L20: Pick the M C S index, and the table hands you two things:
> L21: how many bits ride on each symbol, and what share of the bits is message.
> L22: Push it higher on a quiet channel. Back off when it's loud.

**What the output or plot shows.** Two printed rows (MCS index, modulation, target rate) and two TBS values, with the ordering asserted.

**Check your understanding.** If you jump to a higher MCS row without changing the allocation, what must happen to the TBS?

**Answer.** It must get larger. A retransmission of the same block (B3, B4) is not allowed to change that TBS; only a new MCS selection on a new block is.

## B3. Fail, retransmit, combine (`nrDLSCH` / `nrDLSCHDecoder`)

**Key idea.** A failed block is not thrown away. The transmitter sends a new redundancy version of the same transport block (RV 0, then RV 2 here), and the decoder soft-combines the two observations. The decoder's TransportBlockLength is a property, not a step argument. Skeleton: **encode (RV) → add noise → decode into the same buffer.** The script scans `snrList = -3:0.5:4` dB on a fixed noise seed, resetting the soft buffer each time, and keeps the first SNR where RV 0 fails and RV 0+2 passes. That outcome is then asserted. If no SNR qualifies, it prints a warning instead. *Try:* `snrList = 4` or `snrList = -4` to see the warning path.

**Math.**

HARQ process 0, RV sequence $0$ then $2$, same $\mathrm{TBS}$ and same $\texttt{setTransportBlock}$ contents.
Decoder call shape: $\texttt{dec(soft, mod, nlayers, rv, harqID)}$, with $\texttt{dec.TransportBlockLength}=\mathrm{TBS}$ set beforehand.

**Lyric** (certified spelling):

> L33: On a NACK the sender sends the same block again,
> L35: a redundancy version, zero through three.
> L37: N R DLSCH Decoder keeps a soft buffer for every HARQ process,
> L71: Code it at redundancy version zero, add enough noise that it fails, and decode it.
> L72: Send version two. Decode again with the same buffer.
> L73: If it passes now, you just heard soft combining work.

**What the output or plot shows.** Printed blkerr after RV 0 alone and after RV 0+2 combined at the chosen SNR, with the fail-then-pass asserted.

**Check your understanding.** Why must you not call setTransportBlock again for the retransmission?

**Answer.** That would be a different information word. A retransmission is a new coding of the same transport block; only the RV changes.

**Animation cue A1** (lines L33–L35). A retransmission sends the same block, but reads the coded bits from a different start point (redundancy version 0–3) — The coded block drawn as a ring, with four start markers labelled rv 0, 1, 2 and 3 at schematic positions, not to scale. Each try reads an arc from its marker. Show the order 0, then 2. The k0 positions are UNVERIFIED this round (T05 md §10), so no fractions are shown.

**Animation cue A2** (lines L36–L38). The receiver keeps the first try's soft bits and adds the next try's — Two rows of soft-bit bars, uncertain grey and confident colour, summed bit by bit. The sum's bars are taller, so more cross the confidence line, and a CRC lamp turns green.

## B4. What never changes, and why not max MCS

**Key idea.** A retransmission is a new coding of the same information word, so the TBS (and the HARQ process contents) must not change when only the RV changes. *Talk-only (no code here):* picking the maximum MCS every time would make the first attempt fail more often and would not grow the TBS on the retry. T11's BLER curves measure that trade.

**Math.**

The two coded words $\mathrm{cw}(\mathrm{RV}=0)$ and $\mathrm{cw}(\mathrm{RV}=2)$ differ, but $\mathrm{TBS}$ stays put. Changing the target rate would be a new block, not a retransmission.

**Lyric** (certified spelling):

> L41: Here's what stays fixed: the transport block size never changes on a retransmission.
> L42: Only the version changes.
> L52: So why not always pick the highest index?
> L55: A lower index can land the first time and move more data in the end.

**What the output or plot shows.** Three tested facts replace the old tautological TBS assert. The encoder still holds the original block (`getTransportBlock`). The two coded words differ. The combined decode from B3 returns the original block. A contrast print shows a new target rate giving a different TBS, which is a new block.

**Check your understanding.** Can you 'fix' a failed high-MCS block by sending a larger TBS on the retransmission?

**Answer.** No. The TBS is locked when the process is opened. The retry only changes the redundancy version.

## B5. Where the DM-RS sits (`nrPDSCHDMRSConfig`)

**Key idea.** The phone has to know where the pilots sit before it can estimate the channel. Type-A PDSCH puts the first DM-RS on symbol 2 or 3, and DMRSAdditionalPosition = 0..3 adds extra DM-RS symbols whose places depend on the allocation length (TS 38.211 tables). B1 used the default AdditionalPosition = 0. The B5 loop now recomputes NREPerPRB and TBS for each setting, so the reservation cost is visible (static estimate: 132/120/108/96 REs per PRB → TBS 3104/2792/2472/2216).

**Math.**

For mapping type A, the first DM-RS symbol is $2$ or $3$ (0-based). Extra positions are printed, not predicted, because they depend on the grant length.

**Lyric** (certified spelling):

> L61: Demodulation reference signals ride inside the allocation.
> L62: In mapping type A the first one sits on symbol two or three of the slot,
> L63: and you can add up to three more for a channel that moves fast.
> L64: N R PDSCH DMRS Config holds those choices,

**What the output or plot shows.** A printed map of DM-RS symbols, NREPerPRB and TBS as AdditionalPosition goes from 0 to 3, with an assert that the first symbol is 2 or 3.

**Check your understanding.** If you shorten the grant to four symbols, what happens to the extra DM-RS positions?

**Answer.** Some of them no longer fit. Extra DM-RS is not a fixed symbol list independent of the allocation length.


## Recap (plan S8)

ANI: Three things to keep. The block size is a function of modulation, layers, PRBs, REs per PRB and code rate. A retransmission is a new version of the same block, so that size is locked. And every pilot you add takes REs away from the block. The script ends with these four lines printed: TBS = f(…), TBS locked across RVs, soft-combining in one HARQ buffer, and DM-RS reserving REs.
