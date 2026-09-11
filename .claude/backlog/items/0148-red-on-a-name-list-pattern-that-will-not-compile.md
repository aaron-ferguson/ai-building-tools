---
id: "0148"
title: Make the internal-name guard red rather than green when its own pattern will not compile
type: bug
next: verify
status: in-progress
qa_level: unit
close_by: verify
size: s
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0143", "0118", "0095"]
expects:
  - tests/measurement.test.sh
claimed_by: "541b"
claimed_at: 2026-09-11T02:12:13Z
touches:
---

## Problem

**One malformed entry in the machine-local name list silently disables the whole internal-name
guard, and the suite still reports `0 failed`.** Found verifying `0143`, which added the guard.

The check is one `elif` on the search's exit status:

```sh
elif named=$(git -C "$ROOT" grep -inE "${EXEMPT_PREFIX}($(names_pattern "$NAMES_FILE"))"); then
```

`git grep` exits **1** for *no match* and **128** for *a pattern it cannot compile*, and the `elif`
cannot tell them apart — both are simply non-zero, so both fall through to the `else` branch, which
reports `ok  no tracked file publishes a configured internal organisation or client name`.

Reproduced against a worktree at `4dbd220`, with a synthetic list and a real leak present in the
tracked set:

```
$ printf '%s\n' 'Zorp(tech' > list
$ printf 'the Zorptech profile treats it as canonical\n' > fixture-leak.md && git add fixture-leak.md
$ PRIVATE_NAMES_FILE=list tests/measurement.test.sh
Privacy & data NFR — no internal organisation or client name in any tracked file
fatal: command line, '(^|[^<{$])(Zorp(tech)': parentheses not balanced
  ok   no tracked file publishes a configured internal organisation or client name

121 passed, 0 failed
```

The leak is in the tree, the guard did not look, and the tally says the repo is clean. `fatal:` goes
to stderr, so nothing in the summary a session or `tools/release` step 5 reads shows it.

**This is the same defect class the guard's own comment records, one branch over.** `0143`'s build
found `elif named=$(git grep … | cut …)` reading `cut`'s status instead of the search's, and split the
statement — the fix was right and the remaining `elif` still conflates two of the search's own
statuses. The list is hand-maintained prose, so an entry holding `(`, `)`, `+`, `?`, `{` or `[` is a
plausible real name, not a contrived one.

Not a defect in `0143`'s acceptance criteria — none of them covers a malformed list — which is why
this is its own row rather than a hand-back.

## Functional requirements

- **FR1** — The guard distinguishes *no match* from *the pattern did not compile*: it captures the
  search's own status and treats `128` (or any status that is neither 0 nor 1) as a failure, not as a
  clean tree.
- **FR2** — The failure names the **line number in the list** and the compiler's complaint, and
  **never the entry's text** — the entry is one of the names the Security NFR of `0143` withholds, so
  the diagnostic that makes this fixable must not publish it. `git grep`'s own `fatal:` echoes the
  whole pattern and so cannot be forwarded.
- **FR3** — A falsification control drives an assembled malformed entry through a synthetic list of
  its own, on `0143`'s reasoning: a control that only runs where a real list happens to hold a bad
  entry never runs.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Security | The diagnostic prints the list's line number, never the entry; `git grep`'s `fatal:` text is suppressed rather than forwarded, since it interpolates the pattern. How this would red: a case asserting the failure output does not contain the assembled entry. | `security-conventions.md` |
| Privacy & data | The check keeps reporting file and line without the matched token on the ordinary leak path. How this would red: `0143`'s AC6 case, which must stay green. | `data-privacy-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a configured list holding an entry that is not a valid ERE, when
  `tests/measurement.test.sh` runs, then the file reports a failure and a non-zero exit. Red-making
  input: today's guard, which reports `0 failed` on exactly this list.
- [ ] AC2 — Given that same run, when its output is read, then it names the list's line number and
  does not contain the malformed entry's text. Red-making mutation: forwarding `git grep`'s `fatal:`,
  which echoes the pattern and therefore every name in the list.
- [ ] AC3 — Given a well-formed list and no leak in the tracked set, when the test runs, then the
  check still reports the clean-tree `ok` and the file reports `0 failed`. Red-making mutation:
  treating status 1 as an error, which reds every clean run.
- [ ] AC4 — Given a well-formed list and a leak in the tracked set, when the test runs, then it fails
  naming file and line and withholding the token. Red-making mutation: reordering the new branch
  ahead of the match branch, which would swallow real leaks.
- [ ] AC5 — Given `for t in tests/*.test.sh; do "$t" || true; done`, when it runs, then every file
  reports `0 failed`.

## QA plan

- **Why that level:** the guard is a shell assertion block in an existing suite file; every
  requirement is a case over an assembled list and a fixture tree.
- **Specific checks:**
  - Drive all four list/tree combinations — well-formed x {leak, clean} and malformed x {leak, clean}.
    The malformed-**with**-leak case is the one that is green today.
  - Use a `git worktree` and `PRIVATE_NAMES_FILE`, never the checkout's index or the real list: the
    fixture has to be *tracked* for `git grep` to see it, and staging one in the checkout puts a name
    in the shared index.
  - Assert the absence of the entry's text in the failure output, not merely the presence of the line
    number.

## Out of scope

- Widening the guard's reach to sessions that commit without running a suite — that is `0118`.
- Escaping or validating list entries as regexes rather than reporting them. A name is written to be
  matched literally, so `grep -F` semantics may be the better answer, but choosing that is a change to
  `0143`'s FR1 pattern contract and wants its own row if the build finds it cheaper than reporting.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-09-09 (verify, 94ea)** — Filed from `0143`'s verification. `0143` passed on all seven of its
  own criteria; this is the probe that went past them. The reproduction above was run in a throwaway
  worktree at `4dbd220` with a synthetic name, so no real name was staged, matched or printed.

- **2026-09-10 (develop, ceb2)** — Built. The search moved into `names_search`, the whole decision
  into `name_check_verdict`, and the diagnostic into `malformed_entry_report`. Four things this
  session learned that the ticket could not have said:

  - **`set -eu` is on in this file, and it kills the exact status this ticket exists to read.**
    `named=$(names_search "$L"); status=$?` never reaches the second statement: an assignment from a
    failing command substitution is a failing command, so the script exits 128 mid-suite with no
    tally at all. Every status capture here is written `status=0; x=$(cmd) || status=$?`, and
    `[ "$s" -le 1 ] && continue` had to become an `if`, since a false `&&` list also exits.
  - **No tool's error text can be forwarded, and `git grep` is not the worst offender.** FR2
    anticipated `fatal:` quoting the pattern once; this machine's `grep` is `ugrep`, which echoes
    the pattern on its own line *plus* a caret diagram beneath it. The complaint is therefore
    re-derived — the text after the quoted pattern's closing `':` in `git grep`'s own message — and
    dropped entirely when the entry survives in it anyway. Per-entry compilation is checked with
    `git grep -q ... -- <pathspec matching nothing>`: the compile happens before the walk, so the
    status is the entry's verdict and the tree is never touched.
  - **FR3's control, written the obvious way, passes while the defect is restored.** The first
    implementation put the controls on the two extracted helpers. Reverting only the *consumer* —
    `|| _status=$?` back to `|| _status=1` — reproduced the original silent green with the suite at
    `0 failed`, because the controls reached the helpers and nothing reached the branch. That is why
    the decision itself returns a verdict word: the control drives `name_check_verdict`, not the
    pieces under it. Parked as a conventions gap (`ai-building-conventions/FINDINGS.md`, 2026-09-10).
  - **The `leak` verdict is the one branch no synthetic list can reach**, since reaching it needs a
    tracked file to match and committing a name is the defect the guard exists to stop. Left
    unpinned, moving the uncompilable branch ahead of the match branch swallowed every real leak with
    the suite green. The control's list now names `EXEMPT_PREFIX`, a symbol this file defines, which
    is present in the tracked set by construction.

  **Mutation sweep, ten mutations plus a no-op control, each restored from the committed file**
  (`git checkout --` after the fix was committed, never over it): conflating 128 with no-match;
  `names_search` swallowing its status; forwarding `fatal:`; dropping the line number; treating
  no-match as an error; the uncompilable branch reporting clean; the absent-list branch deleted; the
  uncompilable branch ahead of the match branch; the leak detail printing the matched text; the leak
  branch reporting clean. Every one redded the case aimed at it and only that case. The control ran
  green at `129 passed, 0 failed`. **M8's first form was a bad mutation, not a passing guard** — it
  tested `!= 1 && != 0` ahead of the match branch, which is semantically a no-op; the green was the
  mutation's fault and the real reordering reds two cases.

  **Out of scope, as the ticket states:** the entries are still matched as regexes rather than
  literally. `grep -F` would make a malformed entry impossible, and would change `0143`'s FR1 pattern
  contract, so it stays a separate row if anyone wants it.

  **All four list/tree combinations were driven in a throwaway worktree with `PRIVATE_NAMES_FILE`**
  and an assembled name, never the checkout's index or a real list: well-formed x clean → `ok`, exit
  0; well-formed x leak → FAIL naming `fixture-leak.md:1`, token withheld; malformed x clean and
  malformed x leak → FAIL naming `list line 1: parentheses not balanced`, entry withheld. The
  worktree is removed.
