---
name: waterfall-lint
version: 1.0.0
description: Sequential multi-critic QA loop that scrubs a finished artifact until critics run dry. Critics run one at a time, each finding is fact-checked against ground truth before any fix, confirmed defects are fixed at class level (a validator, lint, or test, not just the instance), accepted warts go in a ledger every later critic sees, and the loop stops after two consecutive passes find nothing new. Companion to critic-gauntlet, which delivers a one-shot parallel verdict; waterfall-lint iteratively removes defects with fixes between passes. Rubrics ship for client-facing reports, working papers, and site launches.
---

# Waterfall Lint

For finished artifacts where shipping a defect costs credibility with a real reader: a client-facing report, a paper about to be submitted, a marketing site going live. Runs AI critics sequentially against the artifact, fixing between passes, so each critic spends its attention on the residue the previous critics and fixes left behind.

Two plain sentences: each pass, one critic reads the current artifact and returns falsifiable defects; you fact-check each against receipts, fix the confirmed ones at class level, queue wart candidates for the operator, and hand the updated artifact to the next critic. Stop after two consecutive passes produce zero new confirmed defects.

## How this differs from critic-gauntlet (and why both exist)

[critic-gauntlet](https://github.com/alexmakarski/critic-gauntlet) is this skill's sibling. The split is VERDICT versus SCRUB. The gauntlet delivers a one-shot independent verdict: critics run in parallel so no critic anchors another, and convergence math binds the outcome. That is the right shape whenever the output is a judgment someone must accept or overrule: should this architecture ship, should this paper be submitted, should this article publish.

waterfall-lint answers a different question: "remove every findable defect from this artifact." Critics run sequentially because the artifact changes between passes; a parallel run would pay five critics to find the same top defects five times. There is no voting and no convergence math; RECEIPTS decide every finding, one at a time, and the loop ends on dryness, not on a verdict.

Choosing between them: if you are going to fix everything findable anyway, scrub (waterfall-lint). If you need an independent judgment on whether the thing should ship at all, verdict (gauntlet). They compose: gauntlet verdict first when ship/no-ship is genuinely open, then a waterfall scrub of the surviving artifact; or scrub first and gauntlet last as the formal gate on the cleaned artifact. Do not run both shapes for the same job on the same draft. And never use waterfall-lint to evaluate proposals, architectures, or strategies; a choice between shapes is verdict territory.

## Roster and default order

Five critics, run one per pass, strongest finders first. The paid-API cost of a critic is trivial (cents); the expensive unit is YOUR fix-and-verify cycle per pass, so front-load the critics most likely to empty the defect pool early.

1. **Codex CLI.** Specification-bug anchor. In the review runs that produced this skill, the strongest single finder.
2. **DeepSeek** (US-hosted Fireworks by default). Distinct training lineage; in those same runs it found confirmed defects AFTER three consecutive Codex passes had gone quiet. Strong on arithmetic reconciliation and misattribution.
3. **Claude `gauntlet-critic` subagent.** Operational-nuance anchor. Spawn least-privilege, never as `general-purpose`; see "The blast-radius rule". The agent definition ships in this repo's `agents/` folder.
4. **Grok** (xAI API). Privacy / policy / jurisdictional angles. Higher noise.
5. **Gemini** (Google AI Studio API). Distribution-blind-spot sweeper. Highest noise.

Only the Claude subagent requires no extra credentials. Run whichever subset you have keys for, but the method depends on lens diversity: two critics from different model families beat three from the same one. Reorder or truncate per run if you have evidence; the stopping rule usually ends the loop before pass 5. A run that reaches two dry passes at pass 3 does not owe passes 4 and 5.

**Billing guardrail (Claude Code subscribers).** The Claude critic is a subagent inside your Claude Code session, not an API call. It does NOT read `ANTHROPIC_API_KEY` and must never be "fixed" by setting one: setting `ANTHROPIC_API_KEY` in the environment routes ALL of Claude Code to API billing instead of your subscription. If this critic fails on infra errors, retry once, then skip to the next critic in the roster. The other critics use other vendors' keys (`XAI_API_KEY`, `GEMINI_API_KEY`, `DEEPSEEK_API_KEY`) or Codex's own CLI auth, none of which touch Anthropic billing.

## The blast-radius rule

**Every agent this skill spawns runs least-privilege: `Read, Grep, Glob, Write` and nothing else. Codex runs `--sandbox read-only`.**

Inherited from critic-gauntlet, where it was learned the hard way: in one real round, two critics spawned with full toolbelts edited a project document, made two git commits authored as the user, pushed to the shared main branch, and filed five tickets in a live tracker. Their briefs asked for a critique file and one line of confirmation.

Why this skill is the worse place for such an overreach: waterfall-lint runs critics against an artifact that is being REPAIRED between passes, and the whole method depends on each pass measuring a known artifact state. A critic that "helpfully" fixes a defect it found has corrupted the experiment: the next pass measures a page nobody logged a change to, the loop log lies, and dryness becomes meaningless. A critic that commits has done it to the repository.

1. **Never spawn a critic as `general-purpose`.** Use `gauntlet-critic`, scoped to `Read, Grep, Glob, Write`: no shell, so no `git`; no MCP, so no external service. If the agent definition is missing from your setup, install it from this repo's `agents/gauntlet-critic.md` before running a pass; do not substitute `general-purpose` "just this once".
2. **Never run Codex with `workspace-write`.** Under `--sandbox read-only` it cannot write its own critique, so the harness captures stdout and writes the file.
3. **The critic reports, the loop fixes.** Class-level fixes happen between passes, by a human deciding the class. That separation is the method, not etiquette.
4. **Check repo state after each pass.** `git status` and `git log --oneline -5`. Unexpected commits are a skill bug.

Residual hole, stated so nobody assumes it is closed: a critic still holds `Write`, because writing the critique is the job. This reduces blast radius; it does not prove containment.

## What you need before invoking

1. **The artifact** in reviewable text form. For rendered reports and sites: the page text the reader actually sees, not internal source data. For papers and articles: the draft. For code: the diff plus the user-visible output.
2. **The receipts**: whatever ground truth findings will be fact-checked against. For a report: the raw source data or appendix. A finding that cannot be checked against receipts cannot be confirmed, only judged.
3. **A work folder**: for example `<project>/reviews/wfl-<YYYY-MM-DD>/`. Holds briefs, artifact snapshots, critiques, fact-check logs, the wart ledger, and the loop log.
4. **The rubric** for the artifact class from `rubrics/` (see "Rubric doctrine" below).

## The loop (one critic = one pass = one round number N)

### Step 0 (once, before any critic): deterministic pre-pass

Run every mechanical check that exists for the artifact class BEFORE spending a critic on it: test suites and validators for code and reports; a crawl for websites (broken links, missing or duplicate titles and metas, heading structure, schema, image alts, noindex state, and on any replatform the old-to-new URL redirect map); reference and figure-number checks for papers. Critics are for defects that need judgment; paying one to find a missing meta description violates the skill's own class-fix philosophy at the front door. Findings from Step 0 skip the fact-check gate (they are their own receipts) and go straight to fixes. Log the pre-pass and its tooling in `loop-log.md` as pass 0.

### Step 1: Snapshot the artifact

Copy the CURRENT artifact text to `<work-folder>/proposal-v<N>.md`. The file name is inherited from the sibling skill's scripts; here it means "the artifact as of this pass." After pass 1 this snapshot must include every verified fix from prior passes: never hand a critic a stale artifact, and never hand it an unverified fix.

### Step 2: Author the brief

Copy `rubrics/<artifact-class>.brief-template.md`, fill the placeholders, save as `<work-folder>/brief-v<N>.md`. Three inline requirements, because the critics see ONLY brief + artifact (by design, see Step 3):

- **Wart ledger inline.** Paste the current `warts.md` content into the brief's accepted-warts block verbatim. This is the mechanism that stops critic 4 from re-flagging what the operator accepted after critic 1.
- **Refuted ledger inline.** Paste the current `refuted.md` content into the brief's already-refuted block. One line per finding: the claim, and the receipt that refutes it. Warts are real defects the operator accepted; refutations are findings that were never real. Both recur, and each needs its own do-not-flag list, because "the operator accepted this" and "the receipts say you are wrong" are different instructions to a critic.
- **Prior-pass summary inline.** One line per prior pass: critic, confirmed count, refuted count. Counts only. Never the critique text.

The two ledgers are the ONLY memory that crosses a pass boundary, and both are yours, receipt-backed, and one line per entry.

### Step 3: Run ONE critic

Invocation templates below, with `--mode qa` for the API scripts. Run in background; do not start the next pass while this one is unfixed.

**Exception for artifacts that are not yet nearly clean.** One-critic-per-pass assumes you are removing residue from a nearly clean artifact. When a single lens still returns double-digit confirmed defects, fixing between passes buys nothing: the next critic reads a page carrying the same defect population anyway, and you pay the fix-and-verify cycle once per critic. So when defect density is high, run the remaining critics TOGETHER against one artifact snapshot, then pool, fact-check, and group into classes before fixing. Measured on a real run: the solo first pass and the pooled second pass overlapped almost not at all, and the defect classes only became visible with the whole pool in hand.

What preserves the sequential benefit without the sequential cost: an ALREADY-FOUND ledger in the brief, one line per confirmed defect, alongside the wart and refuted ledgers. Critics then spend attention on residue. Do not skip it; without it you pay several critics to re-find the top defect.

**The artifact a critic reads must be what the READER sees.** On one real run, the page-to-text extractor silently skipped every `<svg>`, so no critic saw any chart on any report, and two of them then reported a rendered table as missing. Verify the extraction against the rendered page before spending a pass on it.

### Step 4: Liveness gate

Success conditions: the critique file exists, is a real multi-section critique (not an error payload), exit code 0 for the script critics. On failure: retry once. On second failure: SKIP to the next critic in the roster and record the skip in the loop log. QA differs from verdicts here: a lost critic costs coverage, not validity, so the loop continues instead of halting. Note the reduced coverage in the final loop log.

### Step 5: Fact-check gate (binding; the step that makes the loop safe)

Every finding is verified against receipts BEFORE any fix. Doctrine origin: on a real run, one critic asserted the same false claim two passes running; it was wrong both times, and the first "fix" over-obeyed it. External critics get fact-checked, always.

Write `<work-folder>/factcheck-v<N>.md` with one verdict per finding:

- **CONFIRMED**: the receipts support it. Goes to triage.
- **REFUTED**: the receipts contradict it. Log the receipt that refutes it (this is also the critic-calibration record). No fix. Append a one-line entry to `refuted.md` so the next brief carries it: refutations recur across critics because the reasoning that produces them is plausible. On one run, the same "the page's arithmetic is wrong" finding was flagged by two critics and refuted twice by the same receipt, which showed the page accurately quoting a source who did the arithmetic wrong.
- **WART-CANDIDATE**: real but arguably acceptable (cost/benefit, by-design, out of scope). Queued for the operator. The agent NEVER accepts a wart on its own; wart acceptance is the operator's call, in session or in a morning batch. Accepted warts enter `warts.md` with date and one-line reason.

### Step 6: Fix at class level

For every CONFIRMED defect, in priority order (BLOCKER first):

1. Fix the instance.
2. Convert the class: a deterministic validator, lint, or test where expressible; a prompt rule only when determinism is impossible (a prompt rule is probabilistic; in one measured case an LLM violated a freshly added prompt rule on its first re-drive, and the phrase family became a deterministic lint instead). An instance-only fix requires an explicit one-line justification in the loop log.
3. If the class fix is too large for this loop, fix the instance, file a ticket in your tracker, and log the defect as OPEN-CLASS.

This step is what makes "slower per artifact, better product faster" true. The validators absorb defect classes, later artifacts arrive cleaner, passes go dry sooner, and the loop cheapens itself toward a plain validator suite. If confirmed-defect counts are NOT declining across artifacts over time, the loop is patching instances, not classes; treat that as the loop's own failure signal.

Class-fix caution for prose artifacts: deterministic class conversion works for phrase families, counts, and structure, but semantic qualities cannot be linted. Never lint tone or meaning; for prose, a "class fix" usually lands in the house checklist, the voice doc, or the generation prompt, not a semantic linter.

### Step 7: Verify, then advance

Run the test suite / re-render / re-drive as appropriate. A fix nobody verified does not exist. Then update `loop-log.md` (pass number, critic, findings by verdict, fixes shipped, version numbers) and return to Step 1 for the next critic.

### Stopping rule

A pass is DRY when it yields zero NEW confirmed defects (refuted findings, re-flagged warts, and wart escalations do not count). Stop when either:

- two consecutive passes are dry, or
- the roster is exhausted.

Never stop because a pass was merely "mostly clean," and never run a fixed number of passes as ritual when the loop went dry early. An artifact class may also opt out of the dry-pass rule entirely and make the operator the gate (every instance gets linted, the loop stops when the operator says so); that is a deliberate policy choice, not a default.

**Dryness measures the critic you just ran, not the artifact.** Learned on a real run where confirmed defects went 20, then 8, then 33 across three passes. The 33 was not regression: the first critic reads for specification bugs, the second for arithmetic and misattribution, the third for cross-document contradiction. Each went comparatively quiet on the classes the next one found in bulk.

So two dry passes from two critics with the SAME lens is a weaker signal than the rule implies, and the roster order matters more than it looks. Two practical consequences:

- Do not stop on two dry passes from adjacent critics if a lens on the roster has not run yet. Note explicitly in the loop log which lenses have and have not been spent.
- A rising defect count on a later pass is evidence about COVERAGE, not about the artifact getting worse. Record it that way, or the log will read as though the work went backwards.

The honest version of the stopping rule: stop when two consecutive passes are dry AND the remaining unrun critics offer no lens the run has not already seen.

## Raw outputs and the operator

All critiques and fact-check logs are saved verbatim in the work folder, always. When the operator is present in session, surface each pass's critique verbatim before fixing. In autonomous runs (night loops), leave the files and a loop-log summary; the operator reads raw critiques from the folder, and WART-CANDIDATEs wait for them regardless of mode.

## Rubric doctrine: per artifact class, not per artifact type

A rubric is defined by ARTIFACT CLASS plus AUDIENCE, not by the specific report or document. Evidence: the review week that produced this skill ran ONE brief (skeptical-operator falsification) across three different report types unchanged, and it worked on all three; what differed per report lived in the receipts and the wart ledger, which are inputs to the loop, not rubric text. Write a new rubric only when the artifact class or the reader changes (client-facing report vs academic paper vs public site), not when the document type changes within a class. Type nuance that genuinely matters goes in the brief's placeholder fields for that run, not in a new rubric file.

Shipped rubrics:

- `rubrics/client-report.brief-template.md`: client-facing intelligence or analytics reports, reader = skeptical operator applying a compliance-grade evidentiary bar.
- `rubrics/paper.brief-template.md`: working papers before submission (SSRN / Zenodo / journal tier), reader = referee looking for a reason to desk-reject. Data-sovereignty rule: external API critics see ONLY the anonymized paper and its stated public sources, never raw data or identity-bearing files.
- `rubrics/site-launch.brief-template.md`: public marketing site going properly live, reader = skeptical prospective buyer plus a defamation and regulatory eye. Link caveat: link findings from critics reading markdown are moot when links live in the rendered page; verify against the rendered site.

To write your own, see `rubrics/AUTHORING.md`.

## Critic invocation reference

### Claude critic subagent prompt template (`subagent_type: "gauntlet-critic"`)

```
You are an independent QA critic for <artifact-title> pass <N>.

READ EXACTLY TWO FILES: brief-v<N>.md and proposal-v<N>.md. The work folder
also contains earlier passes (critique-v*.md, factcheck-v*.md, loop-log.md,
proposal-v<earlier>.md). Do NOT open any of them. The artifact was regenerated
after those passes, so they describe text that no longer exists, and a finding
that quotes them is a finding against a page nobody can read. Everything you
legitimately need from earlier passes is already summarized in the brief.

STEP 1: Read <work-folder>/brief-v<N>.md in full.

STEP 2: Read <work-folder>/proposal-v<N>.md (the artifact under review).

STEP 3: Write your critique to <work-folder>/critique-v<N>-claude.md with this header:

# Critique v<N>: Claude (gauntlet-critic subagent) <date>

Model: Claude via gauntlet-critic subagent type, waterfall-lint QA brief.
Brief location: brief-v<N>.md in this folder.

---

Then follow the brief's output format exactly.

STEP 4: After writing, output ONE LINE: 'Critique written to <path>, N defects (X blocker / Y should / Z nice), keep-or-cut: <verdict>'

POSTURE:
- Adversarial. Falsify the artifact from its own pages.
- Every defect carries an exact quote. No quote, no finding.
- Every quote must appear in proposal-v<N>.md. If you cannot find it there, the defect does not exist.
- Do not re-flag the brief's accepted warts or its already-refuted findings.
- No em-dashes or double-dashes. Use periods, commas, colons.
- Lead with the strongest defect, no sympathetic opener.

SCOPE (hard):
- Write exactly ONE file, the critique path above. Nothing else, anywhere.
- Do not modify the artifact, the brief, any other critique, or any project doc.
- Do NOT fix anything. This skill fixes defects at class level BETWEEN passes,
  deliberately, with a human deciding the class fix. A critic that patches the
  artifact destroys the very thing the next pass is supposed to measure.
- Do NOT do adjacent work. If you spot a bug, a stale doc, or an unfiled ticket,
  that goes IN YOUR CRITIQUE as a finding. Reporting it is your job; acting on
  it is not.
```

### Codex CLI invocation

```bash
codex exec --sandbox read-only --skip-git-repo-check --cd <work-folder> "<same prompt template, but: print the critique to STDOUT, write no files>" </dev/null > <work-folder>/critique-v<N>-codex.raw 2>&1
```

`</dev/null` is required; codex exec hangs on stdin without it.

Codex and the Claude subagent both run INSIDE the work folder, so unlike the API critics they can read every earlier critique, fact-check log, and artifact snapshot in it. The read-exactly-two-files instruction at the top of the prompt template is the only thing stopping them from READING those, so do not trim it when you paste the template. Note what that instruction is and is not: it is a prompt, so it constrains attention, not capability. Contamination control is a prompt; blast-radius control is the sandbox. Do not confuse the two, and never rely on wording to stop a WRITE. If a filesystem critic returns a finding whose quote is not in `proposal-v<N>.md`, treat it as contaminated and discard it at the fact-check gate rather than chasing the receipt.

### API critics (Grok / Gemini / DeepSeek)

```bash
<skill-folder>/grok-critic.sh     <work-folder> <N> --mode qa
<skill-folder>/gemini-critic.sh   <work-folder> <N> --mode qa
<skill-folder>/deepseek-critic.sh <work-folder> <N> --mode qa
```

The scripts are forked from critic-gauntlet's with ONE deliberate divergence (same key resolution, same model pins, same endpoint policy including DeepSeek's US-hosted Fireworks default and PRC opt-in); they load `modes/qa.system.txt` from THIS skill's directory.

**No prior-round context. Ever.** The gauntlet's scripts append round N-1 critiques to the prompt. That is correct there: the proposal is stable across rounds, so a prior critique is context about the same text. It is wrong here, and the waterfall copies have it removed. In a waterfall the artifact is REGENERATED between passes, so a prior critique describes a page that no longer exists. Measured on a real pass: 5 of one critic's 14 findings quoted the previous pass's draft, strings that were not in the artifact it was given. The prior critique outweighed the artifact in front of it.

The damage is worse than wasted findings. It manufactures fake convergence: two critics flagged the same defect, which a voting scheme would have scored as two independent confirmations. It was one finding counted twice, and the second sighting was of a page that had already been fixed. Contaminated critics are the reason this skill decides on receipts instead of votes, and removing the contamination is cheaper than compensating for it.

The two ledgers in the brief carry everything a later critic legitimately needs to know about earlier passes.

Data note: these three are third-party APIs. Text already written to be shown to its reader is fine to send; do NOT send raw source data containing anything the artifact itself would not disclose, and apply the paper rubric's data-sovereignty rule whenever this loop runs on research data.

## Files this skill writes (per run, in the work folder)

- `brief-v<N>.md`, `proposal-v<N>.md` per pass
- `critique-v<N>-<critic>.md` per pass
- `factcheck-v<N>.md` per pass
- `warts.md` (cumulative; operator-accepted only)
- `refuted.md` (cumulative; one line per receipt-refuted finding, pasted into every later brief)
- `loop-log.md` (cumulative; passes, verdict counts, fixes, class conversions, skips)

## Files this skill ships

- `SKILL.md` (this file)
- `grok-critic.sh`, `gemini-critic.sh`, `deepseek-critic.sh` (forked from critic-gauntlet; identical except the prior-round context block is removed, see "API critics" above)
- `modes/qa.system.txt`
- `rubrics/client-report.brief-template.md`, `rubrics/paper.brief-template.md`, `rubrics/site-launch.brief-template.md`, `rubrics/AUTHORING.md`
- `examples/worked-example.md`
- `.env.example`
- (repo root) `agents/gauntlet-critic.md`, the least-privilege critic agent definition

## Cost and timing

Per pass: Codex and Claude are subscription-included; each API critic is cents. Wall-clock per pass is dominated by the fix-and-verify cycle, not the critic (critics return in seconds to minutes). A full 5-pass run with real fixes is a working session or an overnight loop.

## Relationship to critic-gauntlet's scripts

The API scripts here fork the gauntlet's and must track its fixes (model pin bumps, key resolution changes) by hand; `diff` against the gauntlet's copies when either side changes. One block stays permanently divergent: the prior-round context block is removed here and stays in the gauntlet, because the two skills need opposite behavior. When diffing, expect that block plus the header comment above it, and never "resync" it back in.
