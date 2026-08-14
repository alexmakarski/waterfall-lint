# Waterfall-lint QA brief: {{SITE}} launch scrub, pass {{N}}

You are reviewing the public pages of {{SITE}} immediately before it goes properly live. The publisher is {{PUBLISHER-CONTEXT: who runs the site, what it sells or argues, house voice in one line}}. Assume two readers at once: a skeptical prospective buyer who will falsify marketing claims from the page before trusting the publisher, and a lawyer for any named company checking whether a claim about their client is defensible.

House rules that bind this artifact (inline because you may not be able to read other files):

{{HOUSE-RULES: paste the load-bearing lines from the voice doc / numeric-integrity rules / defamation checklist verbatim.}}

## Accepted warts (do NOT re-flag)

{{WART-LEDGER: paste warts.md content verbatim, or "None yet."}}

## Already refuted by receipts (do NOT re-flag)

Different from an accepted wart: these are not real defects. A previous critic reported each one, and the source data showed the page was right and the critic was wrong. The reasoning that produces them is plausible, which is why they recur. If you think a refutation is itself wrong, say so in one line and name the receipt you would check, but do not list it as a defect.

{{REFUTED-LEDGER: one line per refuted finding: the claim, and the receipt that refutes it. Or "None yet."}}

## Prior passes

You are seeing only the counts below, never the earlier critiques themselves. The pages were rebuilt after each pass, so an earlier critique describes text that no longer exists.

{{PRIOR-SUMMARY: one line per prior pass: critic, N confirmed defects, N refuted. Or "This is pass 1."}}

## Your job, for THE PAGES provided below

1. THE BOUNCE TRIGGER: the single statement or presentation most likely to make the skeptical buyer close the tab or distrust the publisher. An unverifiable stat, a claim two pages contradict, a slop pattern, or an overreach about a named company. Quote it exactly and name the page.
2. LAUNCH OR HOLD: one word (Launch / Hold) with a one-sentence justification. "Hold" means a BLOCKER below must be fixed first.
3. Additional falsifiable defects, each with an exact quote, the page it appears on, and a BLOCKER / SHOULD / NICE tag, in descending severity. Classes to check, none mandatory to find:
   - numeric integrity: statistics that do not reconcile with their cited source, with other pages, or with themselves; precision theater (fake-precise numbers with no source)
   - named-company exposure: claims about a real company that are stated as fact but sourced as inference; anything a lawyer could call unverifiable
   - regulatory exposure: earnings, results, or outcome claims that read as guarantees
   - internal contradiction: promises, prices, counts, or positioning that differ across pages
   - slop patterns: filler passages, hedged non-claims, template residue, placeholder text, stale dates
   - voice drift: passages that break the house voice rules quoted above
   - CTA and flow: dead ends, mismatched CTA promises. CAVEAT: if you are reading markdown or extracted text, link targets may live in the rendered page; flag link findings as CHECK-RENDERED rather than BLOCKER
4. Wart escalations (optional, one line each).

Do not pad: if the site is clean beyond the bounce trigger, say so.

Be specific and adversarial. Quote exactly, with page names. Do not invent content that is not in the text. Findings will be fact-checked against sources and the rendered site before any fix ships.

The pages follow.
