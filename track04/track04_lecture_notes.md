# Track 04 "Every Check Agrees" — lecture notes

Companion to [`track04_demo.m`](track04_demo.m). Sit the two files side by side: headings and beat IDs match.

Clean / PG. Lyric quotations are verbatim from the certified lyric box (certified spelling, never the phonetic box). Equations use the Greek μ. The MATLAB scripts have not been run (this box has no MATLAB).

**Prereqs / terms.** Comes after T03 in the D2 order (T03 → T04 → T05). LLR is defined in B3. *Rate matching* (consumed in T05, next in D2 order): the transmitter picks which of the N coded bits to send, reading a circular buffer from a redundancy-version start point; this demo sends all N bits and skips it.

## Cold open (plan S1, D2-adjusted)

ANI: Last time, the broadcast block arrived with a CRC on it. This time we learn how a data block survives the noise. The answer is a code with thousands of small parity checks. The receiver solves it by passing numbers back and forth until every check is satisfied.

*Why two graphs:* LDPC decodes in parallel and scales to long blocks; BG2 serves small or low-rate blocks, BG1 large, high-rate ones.

## B1. Which base graph? (`nrDLSCHInfo`)

**Key idea.** NR LDPC has two base graphs. BG2 is the short-or-low-rate graph; BG1 is the large, higher-rate graph. The hand rule from TS 38.212 §7.2.2 is: use BG2 if A <= 292, or A <= 3824 and R <= 0.67, or R <= 0.25; otherwise BG1. The toolbox field info.BGN should match that rule.

**Math.**

BG2 if $A\le 292$, or $A\le 3824$ and $R\le 0.67$, or $R\le 0.25$; else BG1.
Five check points: (200, 0.5)->2, (3000, 0.6)->2, (3000, 0.8)->1, (8000, 0.2)->2, (8000, 0.5)->1.

**Lyric** (certified spelling):

> L28: Here's the exact rule. Base graph two if the payload is at most two hundred ninety-two bits,
> L29: or at most three thousand eight hundred twenty-four with a rate at most point six seven,
> L30: or any size with a rate at most one quarter.
> L31: Otherwise, base graph one.
> L63: Close the book. Ask N R DLSCH Info for a block size and a rate,
> L64: and read the base graph it picked. Did you guess right?

**What the output or plot shows.** A printed table of A, R, the hand-rule graph and info.BGN, with each row asserted against the rule.

**Check your understanding.** Why is (3000, 0.6) BG2 but (3000, 0.8) BG1?

**Answer.** Both have A between 293 and 3824, so the rate threshold 0.67 decides: 0.6 is at most 0.67 (BG2), 0.8 is above it (BG1).

## B2. Lift, segment, encode (`nrCodeBlockSegmentLDPC`, `nrLDPCEncode`)

**Key idea.** The base graph is lifted by a factor Zc so that K = 22*Zc (BG1) or 10*Zc (BG2), and the encoded block is N = 66*Zc or 50*Zc. A CRC is attached first. If the CRC'd word is longer than one code-block capacity, it is split. The demo prints info.C rather than asserting a segmentation formula (that formula was not confirmed from the opened spec pages this round).

**Math.**

BG1: $K=22Z_c$, $N=66Z_c$. BG2: $K=10Z_c$, $N=50Z_c$.
At $Z_c=384$: BG1 has $K=8448$, $N=25344$; BG2 has $K=3840$, $N=19200$.
The demo asserts $N=66Z_c$ or $50Z_c$ for whatever $Z_c$ the run picks, and prints $\texttt{info.C}$ for $A=10000$ (expected to split).

**Lyric** (certified spelling):

> L32: The lifting size Z comes from eight sets, and the biggest Z is three hundred eighty-four.
> L33: Base graph one takes twenty-two Z information bits, and base graph two takes ten Z.
> L36: gets cut into code blocks, each with its own twenty-four bit CRC.
> L46: The encoder writes sixty-six Z bits on graph one, fifty Z on graph two,
> L65: Code a block with N R LDPC Encode, turn the bits into soft values, add noise,

**What the output or plot shows.** Printed Zc, K, N for one BG1 and one BG2 payload, the N = 66 Zc or 50 Zc asserts, and a split example with info.C printed.

**Check your understanding.** If a payload is 'just under' one code-block capacity, why might it still split?

**Answer.** A CRC is attached first, so the word the segmenter sees is longer than A. Forgetting those CRC bits is the usual surprise.

**Rate matching (one line).** After encoding, rate matching reads the N coded bits from a circular buffer starting at an RV-dependent point and sends only as many as the slot carries; T05's HARQ redundancy versions are these start points.

**Animation cue A1** (lines L11–L12). Each base-graph entry lifts to a Z×Z block that is either a cyclically shifted identity or all zeros — A small 3×4 base graph whose entries expand into Z×Z tiles. A shifted-diagonal pattern appears where the entry is 1, and blank where it is 0. Shift values are schematic, since the table values were not read (T04 md §10).

## B3. Soft bits in, iterations out (`nrLDPCDecode`)

**LLR.** $\mathrm{LLR}=\log\frac{P(b=0)}{P(b=1)}$: the sign is the guess (+ means 0), the size is the confidence. For BPSK $x=1-2b$ in AWGN of variance $\sigma^2$, $\mathrm{LLR}=2y/\sigma^2$.

**Key idea.** The decoder sees log-likelihoods, not hard bits. At high SNR it finishes in fewer iterations and recovers the code block; at low SNR it uses the iteration budget and can still fail. The input here is a simple BPSK mapping plus noise, which is enough to see the trend. Iteration counts are printed, not asserted; the high-SNR block is asserted to match on non-filler positions (filler bits are −1 in the segmenter output and are not scored). This SNR is per coded BPSK bit without rate matching, so it is not the T05/T11 SNR axis.

**Math.**

$[out, actNumIter]=\texttt{nrLDPCDecode}(\mathrm{LLR},\,\mathrm{BGN},\,\mathrm{maxNumIter})$. $\mathrm{actNumIter}$ should fall as SNR rises.

**Lyric** (certified spelling):

> L56: It wants log-likelihood ratios: a sign for the guess, a size for the confidence.
> L57: Belief propagation is the default.
> L59: and with early termination it quits when every check is met,
> L60: or when it hits the iteration limit you gave it.
> L66: and hand them to N R LDPC Decode.
> L67: Read how many iterations it used. Then lower the noise and count again.

**What the output or plot shows.** A three-row SNR table (0, 4, 8 dB) of iteration counts and bit errors, with a high-SNR assert that the decoded bits match.

**Check your understanding.** If you feed 0/1 hard bits into nrLDPCDecode, what have you thrown away?

**Answer.** The reliability of each bit. The decoder is built for soft LLRs; hard bits are a degraded special case.

**Animation cue A3** (lines L58). Each round, bits and checks trade numbers (belief propagation on the Tanner graph) — A Tanner graph with bit nodes and check nodes. Messages flow as arrows, bit to check and back. A counter of satisfied checks climbs to all; the animation stops early at that point.

## B4. The trap: all checks pass, wrong word

**Key idea.** Every check can agree and still be the wrong word. An LDPC code has many valid codewords; a decoder that lands on a different one will see every parity check pass. The CRC is the outer test that still catches it. The demo stages the event: the decoder "lands" on a word W that differs from the sent CRC'd word A by one bit and is LDPC-encoded as-is, so W is a valid codeword.

**Math.**

$H\,c_W^T=0$ (all parity checks pass, read from `nrLDPCDecode`'s `finalParityChecks`), yet $\mathrm{CRC}(W)\ne 0$. Any single-bit error is detected by the CRC polynomial, so the receiver rejects W.

**Lyric** (certified spelling):

> L49: Now the trap. Every parity check can agree on the wrong word.
> L51: but a valid codeword is not always the codeword you sent.
> L52: That's why the CRC rides along, to catch the one that lies.

**What the output or plot shows.** "LDPC parity checks failing = 0" and "CRC err ≠ 0" for W, beside "CRC err = 0" for the true word A (both asserted).

**Check your understanding.** If every LDPC parity check passes, is the decoded word guaranteed to be the original message?

**Answer.** No. It is a valid codeword, not necessarily the one you sent. That is what the outer CRC is for.

**Animation cue A2** (lines L22 / L8). H·cᵀ = 0 (mod 2): every row's touched bits sum to zero — A row of H highlights the bits it touches. They sum mod 2 to 0 and the row lamp turns green. Then all rows light at once.


## Recap (plan S8)

ANI: An LDPC code is a sparse set of parity checks, H times the codeword equals zero. Five G lifts one of two base graphs by Z, and the payload size and rate pick the graph by an exact rule. The decoder trades soft beliefs between bits and checks until every check is met, and the CRC guards against a valid but wrong answer. Predict the base graph, encode, add noise, and count the iterations.

The script ends with the same four rules printed: BG choice, K and N per Zc, CRC before segmentation, CRC as the outer check.
