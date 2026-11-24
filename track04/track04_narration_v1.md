# Track 04 "Every Check Agrees": Ani's lecture narration (Writer, DRAFT v1)

- **Spoken words:** 1,438 (1,327 narration plus 111 read-aloud self-check questions). **Est. read time:** 9.6 min at 150 wpm, or about 10.6 min with about 10 s of silence at each of the 6 self-check pauses.
- **Budget (TIME_BUDGETS_v2, track 04):** min 7, typical 12, max 18 min. About 1.4 min under typical; no padding.
- **Spec:** NARRATION SPEC at the top of `lecture/track01/track01_narration_v1.md` (voice, structure, fill rules, spoken form, notation, numbering, count method).
- **Sources read:** `track04/track04_lyrics_prelim.md` (certified box, formerly T05), `lecture/track04/` demo_plan, demo.m, lecture_notes; `pedagogue/T04_DFMEA.md`, FIXES_v1, DECISIONS, TIME_BUDGETS_v2.
- Written 2026-11-18, America/New_York. Nothing was run and nothing was sent. Album numbers are used throughout (RENUMBER_MAP.md).

## Self-check map
- F1: the why-LDPC hook (S2).
- F2: the LLR is defined with its sign convention, plus an LLR pause (S5).
- F3: no puncturing step; rate matching points forward to 05 (S4, S6).
- F5: the staged wrong-but-valid W, with a pause (S6).
- F6: the filler mask and the SNR-axis caveat (S5).
- F8: predict the base graph before the columns print (S3).

---
## S1 Cold open (target 30 s)
[Screen] Ani at the desk.

ANI: In lecture 03, the broadcast block arrived with a C R C on it. This time we learn how a data block survives the noise. The answer is a code built from thousands of small parity checks. The receiver solves it by passing numbers back and forth until all the checks are met, and then it still asks the C R C whether the answer is the one that was sent.

## S2 Concept: parity checks and the base graph (target 150 s)
[Screen] Animation A2, the sparse matrix, then A1, the base graph lifting.

ANI: Why this code? 5G data blocks can be tens of thousands of bits long and must decode fast. L D P C codes suit that because their checks can be processed in parallel.

"Low-density parity check: a big matrix H that is almost all zeros." That's the parity-check matrix. "Every row is one check: the bits it touches must add to zero, mod two." "A codeword is any string of bits that passes every check at once." In symbols, on screen: H times the codeword, transposed, equals zero, mod two.

You can draw H as a picture called a Tanner graph. Bits go on one side, checks on the other, and a line joins a bit to a check wherever H has a one. The decoder works on that picture.

5G doesn't store H directly. It stores a small base graph and lifts it. Lifting means every entry of the base graph grows into a Z by Z block: either all zeros, or the identity matrix with its columns shifted. Z is the lifting size. "Base graph one is forty-six rows by sixty-eight columns." "Base graph two is forty-two by fifty-two." Base graph two is built for small blocks and low rates, and base graph one for large, high-rate blocks.

[PAUSE — self-check] Before the code runs: what has to be true of a string of bits for it to be a codeword?

ANI: It has to pass every row of H at once. Each check's bits add to zero, mod two.

## S3 Code beat B1: which base graph? (target 120 s)
[Screen] Demo section B1: the five payload and rate points first, then the rule and base-graph columns.

ANI: "Here's the exact rule. Base graph two if the payload is at most two hundred ninety-two bits," "or at most three thousand eight hundred twenty-four with a rate at most point six seven," "or any size with a rate at most one quarter." "Otherwise, base graph one."

The demo prints five payload and rate pairs first. Pause and pick a graph for each one before the answer columns appear.

[PAUSE — self-check] Three thousand bits at rate point eight, and eight thousand bits at rate point two. Which graph does each get?

ANI: Worked example, for the second learning goal. Three thousand at point eight: it's over two hundred ninety-two, the rate is above point six seven, and above one quarter, so no clause fits, and it gets base graph one. Eight thousand at point two: the rate is at most one quarter, so base graph two, even though the block is large. N R DLSCH Info reads back the same answers. The Try line puts the payload just either side of two hundred ninety-two. At rate point eight, two hundred ninety-two bits gets graph two, and two hundred ninety-three gets graph one.

## S4 Code beat B2: lift, segment, encode (target 140 s)
[Screen] Demo section B2.

ANI: "The lifting size Z comes from eight sets, and the biggest Z is three hundred eighty-four." "Base graph one takes twenty-two Z information bits, and base graph two takes ten Z."

Worked example, for the third learning goal. At Z equals three hundred eighty-four, base graph one takes twenty-two times three hundred eighty-four, eight thousand four hundred forty-eight information bits, and writes sixty-six Z, twenty-five thousand three hundred forty-four coded bits. Base graph two takes ten Z, three thousand eight hundred forty bits, and writes fifty Z, nineteen thousand two hundred. The script asserts the sixty-six Z and fifty Z lengths for whatever Z its run picks.

Why sixty-six Z and not sixty-eight? "and the first two Z information bits are never sent at all." N R LDPC Encode already leaves them out. There's no extra puncturing step to write.

Order matters too. N R CRC Encode attaches the transport block's C R C first, then N R Code Block Segment LDPC splits anything too long. Each piece gets its own twenty-four bit C R C. So a payload just under the maximum block can still split once its C R C is added. The demo shows a ten thousand bit payload on graph one splitting into more than one block and prints the count.

[PAUSE — self-check] The Try line sets the payload to ten thousand bits. Before you run it, say whether the block splits, and why.

ANI: It splits. Ten thousand plus a twenty-four bit C R C is well over eight thousand four hundred forty-eight.

## S5 Animation A3 and code beat B3: decoding (target 150 s)
[Screen] Animation A3, then the B3 iterations printout.

ANI: "The decoder doesn't want hard ones and zeros." It wants soft bits: log-likelihood ratios, from the map-of-the-link lecture. An L L R is the log of the probability that the bit is zero over the probability that it's one. "a sign for the guess, a size for the confidence." In this demo, positive means zero.

For B P S K in Gaussian noise, the L L R is two times the received value over the noise variance. Worked example, for the fourth learning goal. Received value minus point three, noise variance point two five: two times minus point three over point two five is minus two point four. The decoder guesses one, with moderate confidence.

[PAUSE — self-check] Same noise variance, received value plus one point two. What does the decoder guess, and how confident is it?

ANI: Two times one point two over point two five is plus nine point six. It guesses zero, with high confidence.

The decoder is belief propagation, the default. Each round, bits and checks trade L L R values along the Tanner graph's lines. With early termination it quits as soon as every check is met, or when it hits the iteration limit you gave it.

The demo sends a small base graph two block at zero, four and eight decibels. The block carries filler bits, padding the segmenter adds, so the script gives fillers an L L R of zero and scores only real data. If the final assert trips, check that filler mask first. One more caution: this decibel axis is per coded bit with no rate matching, so it isn't the same axis as the error curves in lectures 05 and 11.

[PAUSE — self-check] Predict the trend: as the signal-to-noise ratio rises, does the iteration count rise, fall, or stay the same?

ANI: It falls. That's the fifth learning goal. At eight decibels the decoder finishes in a few iterations and the data bits come back exactly. The Try line lowers the iteration limit to two: watch success start to slip, even at high signal-to-noise ratio.

## S6 Code beat B4: the trap (target 110 s)
[Screen] Demo section B4 printout.

ANI: "Now the trap. Every parity check can agree on the wrong word." "The decoder stops early when the checks are all satisfied," "but a valid codeword is not always the codeword you sent."

The demo stages that event directly. The sender's word, with its C R C, is called A. The script makes a second word, W, by flipping one bit of A without recomputing the C R C, and encodes W. Because W came out of the encoder, it's a valid L D P C codeword. The decoder lands on W, and the printout shows zero failing parity checks. Then the C R C check runs. A passes. W fails.

[PAUSE — self-check] W passed every parity check. Why didn't its C R C pass too?

ANI: Because the C R C is computed over the message bits, not over the L D P C code. Flipping a message bit without recomputing the C R C leaves a mismatch, and the parity checks can't see it. "That's why the CRC rides along, to catch the one that lies." Change which bit is flipped, or flip two: the parity line stays at zero, and the C R C still rejects W.

One link forward. Rate matching picks which of the coded bits are actually sent, reading from a circular buffer, starting at one of four places. Those four starting points are the redundancy versions that lecture 05 uses when it sends a block again. This demo sends all the bits.

## S7 Recap (target 40 s)
[Screen] Ani, close-up.

ANI: Four rules to keep. Base graph two for small blocks, or for rates of at most point six seven under three thousand eight hundred twenty-four bits, or any rate at most one quarter; otherwise base graph one. Base graph one takes twenty-two Z and writes sixty-six Z; base graph two takes ten Z and writes fifty Z. The C R C goes on before segmentation. And passing every parity check is not proof: the C R C is the outer check. Predict the graph, encode, add noise, and count the iterations.

---
## Notes for Showrunner
- This follows the post-fix demo B4 (W passes all parity checks and fails the CRC), not plan S6.
- The plan's S7 'connects back to last track' is now a forward pointer to lecture 05 (D2 order).
- The C formula stays unquoted (UNVERIFIED in the plan).
- L04, the chorus, L77 and L78 are not quoted (avoid list). Other quotes are verbatim.
