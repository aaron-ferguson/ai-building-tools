# Findings — parked, not yet placed

**One or two lines each, dated.** A buffer, not a second backlog: it holds findings whose home is
**not local and not yet decided** — a possible row, a suspected skill or convention problem, a cost
pattern nobody has named yet.

**If a finding's home is obvious, write it there instead and do not park it.** A mechanism goes in a
comment beside the code, a rule goes in a test that fails, a unit of work goes to `queue` as a row.
Parking those is how a session ends with nothing written down *and* a growing file.

Format: `- YYYY-MM-DD — **what happened.** why it might matter (pointer: file, item id)`

**The date goes outside the bold, and this is load-bearing.** Every sweeper and `./next --findings`
find entries by line shape, so an entry whose date sits inside the `**` is skipped and nobody ever
notices — two such entries once made `MEASUREMENT.md` publish 26 findings in one sentence and 28 two
paragraphs later. Readers match `^- (\*\*)?20[0-9]{2}-` to tolerate the drift; writers use the
canonical form so as not to add to it. **Entry order is not guaranteed** — sessions have appended at
both ends — so a sweep reads to the end rather than stopping at the first entry outside its window.

**Emptying this file is `queue`'s and `retro`'s job and their skills carry the rules**: who takes
which entries, what is expired unprocessed, and why a sweeper removes only what it processed. The
normal state of this file is empty, and **if it has grown, that is itself the finding**.

---


- 2026-09-09 (retro) — **Step 2 forbids the destination work that Step 1 requires, for the
  *absorbed* disposition specifically.** Step 2 says to present a *provisional* destination and wait,
  because checking one properly is wasted on a finding the user rejects; Step 1 says a deferral must
  name a destination you have opened, since a wrong pointer costs the next pass full price. For
  *landed* those coexist — the file is obvious and the grep can wait. For *absorbed* the row **is**
  the destination, and there is no way to propose "this already has a home" without having opened the
  item to know it does. This pass opened five item files before the gate and found the proposal
  materially changed by two of them: `0043` turned out to be the right home for a finding proposed as
  a new row, and `0118` already owned half of another. Both readings are defensible and the skill
  does not say which wins (pointer: `skills/retro/SKILL.md` Steps 1 and 2).
- 2026-09-09 (retro) — **`retro` Step 4 tells a session to file a row and never says how to claim the
  id, and `next_id` alone is not enough to get it right.** Filing six rows this pass, an id was
  written into a skill file and a commit message from the neighbourhood of `config.yml`'s `next_id`
  without reading `items/` — and it collided with `0141`, a row created earlier the same day. The
  bump was correct; the *reading* of it was not, and nothing in the step prompts the check. `queue`
  Step 2 owns id allocation and `retro` files rows without citing it, which is the cited-never-
  restated rule failing by omission rather than by drift: no rule was restated, so nothing looks
  wrong (pointer: `skills/retro/SKILL.md` Step 4 *Filed*, `skills/queue/SKILL.md` Step 2,
  `.claude/backlog/config.yml` `next_id`).
- 2026-09-09 — **an acceptance criterion asked for a red-making state that reaching would itself be
  the defect.** 0143 AC3 wanted the guard's redaction exemption proved by a tracked file carrying a
  wrapped internal name, so that dropping the exemption reds the repo — but any such file is a
  committed name, which the same item's Security NFR forbids. The two clauses are individually
  reasonable and jointly unsatisfiable, and nothing in `queue`'s AC form catches it: the AC names a
  red-making input, which is exactly what the form asks for. A privacy guard is the general case —
  its tree-level evidence is always the thing it exists to prevent — so the claim has to be carried
  by assembled samples and the substitution recorded beside the check (pointer: `skills/queue/SKILL.md`
  AC form, `tests/falsifiable-acs.test.sh`, item 0143 AC3).
- 2026-09-09 (verify) — **The entry above is wrong, and the general lesson is that an
  *unreachability* claim in build notes needs re-running exactly like a mutation table does.**
  `0143` AC3 was recorded as unsatisfiable at tree level, because reaching it "means COMMITTING a
  name". It does not: a throwaway `git worktree` plus `PRIVATE_NAMES_FILE` pointed at a **synthetic**
  list makes the fixture tracked without staging anything in the checkout and without any real name
  existing, and this pass drove AC3 both ways in about a minute — green on a wrapped placeholder,
  red on `EXEMPT_PREFIX=''`. `verify` Step 3 says "never trust a mutation you did not run" and
  `develop` Step 5 has nothing for the mirror case, so a *substitution* offered in place of a check
  reads as settled where a discharged mutation reads as re-runnable — and the build note went
  further, telling the QA pass to "read AC3 as satisfied by that control or bounce the
  substitution", i.e. naming the two options and not the one that was available. The recurring
  shape: an environment constraint stated as a construction constraint (pointer:
  `skills/verify/SKILL.md` Step 3, `skills/develop/SKILL.md` Step 5, item 0143 AC3).

- **2026-09-10 — `./claim <id>` makes no file-scope check, so an explicitly named ticket is claimed
  straight through a full collision.** `develop` Step 1 says to compare a candidate's `expects:`
  against every in-progress `touches:` before claiming, and the only thing that prints that
  comparison is `./next <stage>` — which reports it for the row *it* offers, not for the id you
  asked for. Invoked as `/develop 0130`, `./next develop` printed `CLAIMED FILES … 0131 [78c7]`
  about its own candidate `0142`, and `./claim 0130` then granted a row whose four `expects:` paths
  are the same four `0131` holds, with no warning of any kind. The claim was released a minute
  later, unused. Either `claim` owes the check for the id it is given, or `./next <stage> <id>`
  owes it for the id it is asked about — today neither does, and the session that follows the skill
  literally is the one that collides (pointer: `.claude/backlog/claim`,
  `skills/queue/templates/next`, `skills/develop/SKILL.md` Step 1).
