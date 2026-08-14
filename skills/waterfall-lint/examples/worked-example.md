# Worked example: a three-pass site-launch scrub

A condensed but structurally faithful run, synthesized from real production runs with the client details replaced. The artifact is the marketing site of a fictional company, "Lakemont Analytics", going live: four pages (home, product, pricing, about). Rubric: `site-launch`. Roster available this run: Codex, DeepSeek, Claude subagent.

Work folder:

```
lakemont/reviews/wfl-2026-08-10/
```

## Pass 0: deterministic pre-pass

Before any critic: a crawl (broken links, titles, metas, heading structure, image alts, noindex state) plus the site's own build checks.

Findings: 2 broken internal links, 1 duplicate meta description, the pricing page still `noindex` from staging. These are their own receipts, so they skip the fact-check gate and go straight to fixes.

`loop-log.md` after pass 0:

```
## Pass 0 (mechanical), 2026-08-10
Tooling: site crawl (linkchecker + custom meta audit), npm run build
Findings: 4 (2 broken links, 1 dup meta, 1 stale noindex). All fixed, re-crawled clean.
Class conversions: noindex check added to CI (blocks deploy if any public page is noindex).
```

Note the class fix: the stale `noindex` did not just get flipped; a CI check now makes the class impossible.

## Pass 1: Codex

`proposal-v1.md` is the rendered page text of all four pages, extracted and spot-checked against the browser (charts and tables present, not skipped by the extractor). `brief-v1.md` is the site-launch template with the placeholders filled; wart and refuted ledgers both read "None yet."

Codex returns 6 findings. The fact-check gate (`factcheck-v1.md`) verifies each against receipts: the cited sources, the rendered site, the company's own numbers.

```
# Fact-check v1 (Codex), 2026-08-10

1. "Teams cut reporting time by 62%" (home) vs "reduce reporting effort by
   up to 62%" (product). Stated as a flat fact on home, hedged on product.
   Receipt: the case study says "up to 62%, n=1 customer". CONFIRMED, BLOCKER.
2. Pricing table says "unlimited seats" on Growth; FAQ says Growth caps at 25.
   Receipt: current price book, Growth = 25 seats. CONFIRMED, BLOCKER.
3. "SOC 2 certified" (about). Receipt: report is SOC 2 Type I, attestation not
   certification, and Type II is in progress. CONFIRMED, SHOULD.
4. "Founded by ex-Google engineers" called unverifiable. Receipt: founders'
   verified employment history. REFUTED, logged to refuted.md.
5. Home hero chart "has no y-axis units". Receipt: rendered page shows units;
   the extractor's text form drops axis labels. REFUTED (CHECK-RENDERED class),
   logged to refuted.md.
6. Blog teaser dated 2025 on an otherwise-2026 site. Real, but the operator may
   accept (the post is genuinely from 2025). WART-CANDIDATE, queued.
```

Fixes, at class level:

- Finding 1: instance fixed, and a claims lint added: every statistic on a public page must carry its qualifier ("up to", the n, or a source link); the lint greps built pages for a maintained list of bare-stat patterns.
- Finding 2: instance fixed, and the price book becomes the single source: pricing page and FAQ now render from one data file, so they cannot diverge again.
- Finding 3: instance fixed (wording: "SOC 2 Type I attested; Type II in progress"). Instance-only, justified in the log: one string, no class to convert.

Operator (in session) accepts finding 6 as a wart: "the 2025 date is accurate, leave it." Into `warts.md`:

```
2026-08-10 Blog teaser dated 2025: accurate date, post is from 2025. Accepted.
```

`refuted.md`:

```
"ex-Google unverifiable" (Codex p1): founders' employment history verifies it.
"hero chart missing y-axis units" (Codex p1): units render; extractor drops axis labels.
```

Verify: rebuild, re-crawl, both lints green. Snapshot refreshed for pass 2.

## Pass 2: DeepSeek

`brief-v2.md` now carries both ledgers inline plus the prior-pass summary ("Pass 1, Codex: 3 confirmed, 2 refuted"). DeepSeek reads the FIXED site.

4 findings: two are new CONFIRMED arithmetic defects Codex never touched (the ROI calculator's example output does not recompute from its own inputs; the pricing page's annual discount says 20% but the numbers imply 17%), one re-derives the already-refuted y-axis claim (killed instantly by the refuted ledger entry, no receipt-chasing), one is a WART-CANDIDATE the operator declines to accept (fix shipped instead).

The arithmetic class gets a real conversion: a test now recomputes every displayed derived number on the pricing and calculator pages from their inputs at build time.

## Pass 3: Claude subagent

Reads the twice-fixed site with both ledgers. Returns 1 finding: a cross-page contradiction in how the free trial is described (14 days on home, "two weeks, card required" on pricing, no card mention elsewhere). CONFIRMED, SHOULD; fixed, and trial terms join the single-source data file from pass 1's fix.

Not a dry pass (one new confirmed defect), but the trajectory is right: 3 confirmed, then 2, then 1, with each critic finding a different class (claims and consistency, arithmetic, cross-page contradiction).

## Pass 4: Codex again (lens already spent) goes dry. Pass 5: DeepSeek, dry.

Two consecutive dry passes, and every available lens has run at least once. Stop.

Final `loop-log.md` totals: 4 mechanical + 6 confirmed across three critic passes, 3 refuted (all caught by receipts before any fix), 1 accepted wart, 4 class conversions (CI noindex check, claims lint, single-source pricing data, derived-number recompute test). The next Lakemont-style launch starts with all four validators already in place, which is the point: the loop's output is not just a clean site, it is a cheaper next loop.
