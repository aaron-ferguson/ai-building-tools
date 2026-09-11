---
id: "0148"
title: Make the internal-name guard red rather than green when its own pattern will not compile
type: bug
next: develop
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
claimed_by: "ceb2"
claimed_at: 2026-09-11T01:55:56Z
touches:
  - tests/measurement.test.sh
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
