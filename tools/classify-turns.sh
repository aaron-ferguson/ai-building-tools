#!/bin/sh
#
# Classify every turn in a set of session transcripts into what the turn was spent on (0073, FR2),
# and estimate how much of a session's context growth is its own prior turns (FR3).
#
# WHY THIS EXISTS. `MEASUREMENT.md` showed isolation cut the floor a session starts from and did
# nothing to the climb inside it: a develop session still averages 39 turns. Turns per session is
# therefore the remaining lever, and nothing said what the 39 turns were spent on. `0009` already
# paid for guessing once -- it modelled a 66% saving from a wrong premise and observed 14.5% -- so
# this classifies by committed code reading the transcripts rather than by a session reading them.
#
# PRIVACY (0073's data-privacy NFR). This is the one script in the repo that reads shell command
# strings and edit payloads, so it is the one that could publish one. It emits ONLY category
# counts, stage names and aggregate token figures. No command, path, message or payload it read
# reaches the output, and `tests/measurement.test.sh` asserts both halves against a fixture that
# plants a sentinel in a message, in an edit payload and inside a shell command.
#
# WHY THE PARSING IS DUPLICATED FROM tools/harvest-usage.sh RATHER THAN SHARED. That script is
# pinned by `0051` as the reproducer of this record's published tables, and a refactor of it puts
# those figures at risk to save about forty lines. The turn-dedup rule and the marker detection are
# copied deliberately, and both files state the same two facts: a turn is a distinct `message.id`,
# and the skill marker arrives in either tag order after a `/clear`.
#
# Usage:
#   tools/classify-turns.sh <transcript-dir> [--since YYYY-MM-DD] [--until YYYY-MM-DD]
#                           [--exclude <session-id-prefix>]
#
# Requires: sh and python3. No packages.

set -eu

if [ $# -lt 1 ]; then
  echo "usage: $0 <transcript-dir> [--since YYYY-MM-DD] [--until YYYY-MM-DD] [--exclude <prefix>]" >&2
  exit 2
fi

DIR="$1"; shift
[ -d "$DIR" ] || { echo "no such transcript directory: $DIR" >&2; exit 2; }

exec python3 - "$DIR" "$@" <<'PY'
import json, os, re, sys, glob

CATEGORIES = ("mechanism", "orientation", "work", "narration", "other")
# A turn whose tool calls span more than one category is decided by this order, most specific
# first: a turn that edited the change is work whatever else it also read.
PRECEDENCE = ("work", "mechanism", "orientation", "other")

# --- what a turn was spent on -----------------------------------------------------------------
#
# Almost every tool call in the recorded sessions is Bash -- 1,741 of 1,787 in the pinned window --
# because the sessions ran with file reads and edits going through the shell. So the classifier is
# mostly a reading of command strings, and the rules are applied in the order written below.

# The backlog protocol and the git bookkeeping around it, read or written either way.
MECHANISM = re.compile(r"""
      backlog/(claim|close|next|hand)   # the scripts that make a claim durable
    | \./(claim|close|next)\b
    | \.lock\b
    | (queue|done|findings|ranking|ranking-history|scheduled)\.md
    | config\.yml
    | git\s+(commit|add|status|diff|log|stash|restore|rev-parse|push|pull|fetch|worktree|show|branch|checkout|rm|mv)
""", re.X | re.I)

# What a mechanism turn was actually running. `mechanism` being the largest category does not on
# its own aim a reduction: the backlog protocol and the git bookkeeping around it are two
# different fixes. First match wins, in the order written.
MECHANISM_PARTS = (
    ("backlog script", re.compile(r"backlog/(claim|close|next|hand)|\./(claim|close|next)\b", re.I)),
    ("lock",           re.compile(r"\.lock\b", re.I)),
    ("queue file",     re.compile(r"queue\.md", re.I)),
    ("other backlog",  re.compile(r"(done|findings|ranking|ranking-history|scheduled)\.md|config\.yml", re.I)),
    ("git write",      re.compile(r"git\s+(commit|add|rm|mv|push)", re.I)),
    ("git inspect",    re.compile(r"git\s+", re.I)),
)

# Running the suite, or any test, is work on the change rather than orientation about it.
TESTS = re.compile(r"(\.test\.sh|\btests?/|\bnpm\s+(test|run\s+test)|\bpytest\b|\bjest\b|\bgo\s+test\b)", re.I)

# Write-shaped: the command changes a file rather than reporting on one.
WRITES = re.compile(r"""
      sed\s+-i
    | \btee\b
    | >>?\s*[\w./~-]
    | <<\s*'?[A-Za-z]        # a heredoc, which is how a file gets written in a shell session
    | \b(mv|cp|rm|mkdir|touch|chmod|ln|patch)\s
""", re.X | re.I)

# The files a session reads to orient itself: the skill it is running, the conventions it cites,
# the template it copies, the ticket it is working.
ORIENT = re.compile(r"""
      skill\.md
    | conventions
    | templates?/
    | backlog/items
    | references/
    | (readme|claude|measurement|source|license)\.md
    | plugin\.json | marketplace\.json
    | \.claude/(skills|agents|settings)
""", re.X | re.I)

# Tool names that are a read or a write whatever their arguments say.
WRITE_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
READ_TOOLS = {"Read", "Glob", "Grep", "ToolSearch", "WebFetch", "WebSearch", "Skill"}


def category_of_command(cmd):
    if TESTS.search(cmd):
        return "work"
    if MECHANISM.search(cmd):
        return "mechanism"
    if WRITES.search(cmd):
        return "work"
    if ORIENT.search(cmd):
        return "orientation"
    return "other"


def category_of_call(block):
    name = block.get("name") or ""
    args = block.get("input") or {}
    if name == "Bash":
        return category_of_command(str(args.get("command") or ""))
    if name in WRITE_TOOLS:
        return "work"
    if name in READ_TOOLS:
        target = str(args.get("file_path") or args.get("path") or args.get("pattern") or "")
        if MECHANISM.search(target):
            return "mechanism"
        return "orientation"
    return "other"


def category_of_turn(blocks):
    """The turn's category, and whether its calls spanned more than one."""
    found = []
    for b in blocks:
        c = category_of_call(b)
        if c not in found:
            found.append(c)
    if not found:
        return "narration", False
    for c in PRECEDENCE:
        if c in found:
            return c, len(found) > 1
    return "other", len(found) > 1


def mechanism_part_of(blocks):
    """Which part of the mechanism a turn ran, or None. First pattern in MECHANISM_PARTS wins."""
    text = " ".join(str((b.get("input") or {}).get("command")
                        or (b.get("input") or {}).get("file_path") or "")
                    for b in blocks)
    for name, pattern in MECHANISM_PARTS:
        if pattern.search(text):
            return name
    return None


# --- the same turn accounting as tools/harvest-usage.sh ----------------------------------------

CMD_ONLY = re.compile(
    r'^(?:\s*<command-(?:name|message|args)>[^<]*</command-(?:name|message|args)>)+\s*$')
CMD_NAME = re.compile(r'<command-name>\s*([^<]+?)\s*</command-name>')
WRAPPER = re.compile(r'<(local-command-caveat|local-command-stdout)>.*?</\1>', re.S)
SKILL_OF = re.compile(r'^/(?:ai-building-tools:)?(queue|design|develop|verify|retro|prototype)$')


def text_of(content):
    """The user message as a plain string, for marker detection only. Never emitted."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(b.get("text", "") for b in content
                         if isinstance(b, dict) and b.get("type") == "text")
    return ""


def marker_skill(message):
    body = WRAPPER.sub("", text_of(message.get("content"))).strip()
    if not body or not CMD_ONLY.match(body):
        return None
    for name in reversed(CMD_NAME.findall(body)):
        m = SKILL_OF.match(name.strip())
        if m:
            return m.group(1)
    return None


def context_of(usage):
    return ((usage.get("input_tokens", 0) or 0)
            + (usage.get("cache_read_input_tokens", 0) or 0)
            + (usage.get("cache_creation_input_tokens", 0) or 0))


def blank():
    row = {"turns": 0, "sessions": 0, "mixed": 0, "growth": 0, "own": 0}
    row.update({c: 0 for c in CATEGORIES})
    row.update({"part:" + name: 0 for name, _ in MECHANISM_PARTS})
    row.update({"floorsess": 0, "floor": 0, "end": 0})
    return row


# Accumulated by the driver, once per session, not by add_into -- which runs once per STAGE
# within a session and would count a floor twice for a session that changed stage.
DRIVER_OWNED = ("sessions", "floorsess", "floor", "end")


def add_into(dst, src):
    for key in list(src):
        if key not in DRIVER_OWNED:
            dst[key] += src[key]


def parse_args(argv):
    opts = {"since": None, "until": None, "exclude": []}
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in ("--since", "--until", "--exclude"):
            i += 1
            if i >= len(argv):
                sys.exit("%s needs a value" % a)
            if a == "--exclude":
                # An empty prefix matches every session id, so `--exclude ''` -- one shell-quoting
                # slip on a command that carries twelve of these -- silently excluded the whole
                # pinned set and reported zeros. Refuse it rather than classify nothing.
                if not argv[i]:
                    sys.exit("--exclude needs a non-empty value")
                opts["exclude"].append(argv[i])
            else:
                opts[a[2:]] = argv[i]
        else:
            sys.exit("unknown argument: %s" % a)
        i += 1
    return opts


def read_turns(path, opts):
    """The session's turns in transcript order, each one response with ALL of its blocks.

    THE ONE THING THAT IS NOT OBVIOUS, and the reason this is a pass of its own. A single API
    response is written to the transcript as SEVERAL lines, one per content block, each repeating
    the same complete `usage` object -- so cost must count a `message.id` once, which is what
    `tools/harvest-usage.sh` does. Classification needs the opposite of that: the text block comes
    FIRST and the tool calls follow on later lines, so keeping only the first line of an id sees no
    tool call at all and reads the turn as narration. Against the real pinned set that reported
    84.5% narration and not one mixed turn, both figures plausible enough to publish. Usage is
    therefore taken from the first line of an id and blocks are UNIONED across all of them.
    """
    turns = []
    index = {}
    stage = "unmarked"
    for line in open(path, errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
        except ValueError:
            # A transcript being written to right now ends in a partial line. Skipping it loses at
            # most the turn in flight, which a pinned run excludes anyway; raising would make every
            # run against a live store fail.
            continue
        kind = d.get("type")
        if kind == "user":
            stage = marker_skill(d.get("message", {})) or stage
            continue
        if kind != "assistant" or d.get("isSidechain"):
            continue
        msg = d.get("message", {})
        usage = msg.get("usage")
        if not usage:
            continue
        day = (d.get("timestamp") or "")[:10]
        if opts["since"] and day and day < opts["since"]:
            continue
        if opts["until"] and day and day > opts["until"]:
            continue
        mid = msg.get("id")
        blocks = [b for b in (msg.get("content") or [])
                  if isinstance(b, dict) and b.get("type") == "tool_use"]
        if mid in index:
            index[mid]["blocks"].extend(blocks)
            continue
        turn = {"stage": stage, "usage": usage, "blocks": blocks}
        index[mid] = turn
        turns.append(turn)
    return turns


def floor_and_end(turns):
    """The session's startup floor, its end context, and the stage in force at its first turn.

    The floor is what the session had loaded before it did anything: the system prompt, the tool
    definitions, the skill file it is running, and whatever its CLAUDE.md imports. The climb is
    everything after. The two halves answer different questions -- loading less acts on the floor,
    taking fewer turns acts on the climb -- and a reduction aimed without both is aimed at
    whichever half was published.
    """
    if not turns:
        return None
    return (turns[0]["stage"], context_of(turns[0]["usage"]), context_of(turns[-1]["usage"]))


def classify_session(path, opts):
    """One session, classified and accounted per stage.

    The context-growth estimator walks the turns in transcript order. A turn's context is
    `input + cache_read + cache_creation`, so the rise from one turn to the next is what the
    conversation appended in between -- the previous response, plus whatever came back to it.
    `own` accumulates the previous turn's output tokens against that rise, and only rises are
    counted: a fall means the context was pruned or the session resumed, which the estimator
    cannot attribute and must not net out.
    """
    per_stage = {}
    prev_ctx = None
    prev_out = 0
    for turn in read_turns(path, opts):
        usage = turn["usage"]
        row = per_stage.setdefault(turn["stage"], blank())
        cat, mixed = category_of_turn(turn["blocks"])
        row["turns"] += 1
        row[cat] += 1
        if mixed:
            row["mixed"] += 1
        if cat == "mechanism":
            part = mechanism_part_of(turn["blocks"])
            if part:
                row["part:" + part] += 1
        ctx = context_of(usage)
        if prev_ctx is not None and ctx > prev_ctx:
            row["growth"] += ctx - prev_ctx
            row["own"] += prev_out
        prev_ctx = ctx
        prev_out = usage.get("output_tokens", 0) or 0
    return per_stage


directory = sys.argv[1]
opts = parse_args(sys.argv[2:])

totals, by_stage = blank(), {}
for path in sorted(glob.glob(os.path.join(directory, "*.jsonl"))):
    sid = os.path.basename(path).split("-")[0]
    if any(sid.startswith(x) or x.startswith(sid) for x in opts["exclude"]):
        continue
    per_stage = classify_session(path, opts)
    if not per_stage:
        continue
    fe = floor_and_end(read_turns(path, opts))
    if fe:
        # Attributed to the stage in force at the FIRST turn, because a floor is paid once at
        # session start. That is a different denominator from the turn tables above, so a session
        # that changed stage mid-run counts here under one stage and there under two.
        first_stage, floor, end = fe
        fr = by_stage.setdefault(first_stage, blank())
        fr["floorsess"] += 1
        fr["floor"] += floor
        fr["end"] += end
        totals["floorsess"] += 1
        totals["floor"] += floor
        totals["end"] += end
    for name, r in per_stage.items():
        stage_row = by_stage.setdefault(name, blank())
        add_into(stage_row, r)
        stage_row["sessions"] += 1
        add_into(totals, r)
    totals["sessions"] += 1

# A run that classified nothing must not look like a run. An empty store, a mistyped date window
# and an over-broad exclusion all used to print a fully formatted table of zeros and exit 0 --
# a reproduction recipe whose typo reads as a successful reproduction, which is the failure this
# record exists to make impossible (`0009`).
if not totals["sessions"]:
    sys.exit("no sessions matched: nothing to classify in %s" % directory)

order = sorted(by_stage, key=lambda n: -by_stage[n]["turns"])

print("CLASSIFY of %d sessions" % totals["sessions"])
print("CATEGORIES %s" % " ".join(CATEGORIES))
print("PRECEDENCE %s, for a turn whose tool calls span more than one" % " ".join(PRECEDENCE))
print("")

HEAD = "%-10s| %6s | %6s | %11s | %9s | %11s | %6s | %9s | %6s | %5s"
ROW = "%-10s| %6d | %6d | %11.1f | %8.1f%% | %10.1f%% | %5.1f%% | %8.1f%% | %5.1f%% | %4.1f%%"
print(HEAD % ("STAGE", "SESSNS", "TURNS", "TURNS/SESSN", "MECHANISM", "ORIENTATION",
              "WORK", "NARRATION", "OTHER", "MIXED"))
for name in order + ["TOTAL"]:
    r = totals if name == "TOTAL" else by_stage[name]
    sessions = r["sessions"] or 1
    turns = r["turns"] or 1
    pct = lambda k: 100.0 * r[k] / turns
    print(ROW % (name[:10], r["sessions"], r["turns"], float(r["turns"]) / sessions,
                 pct("mechanism"), pct("orientation"), pct("work"), pct("narration"),
                 pct("other"), pct("mixed")))

# What the largest category is made of, so a reduction has something to aim at rather than a
# category name. Shares are of the mechanism turns, not of all turns.
print("")
print("MECHANISM COMPOSITION, as a share of the mechanism turns")
PHEAD = "%-10s| %9s | " + " | ".join(["%14s"] * len(MECHANISM_PARTS))
PROW = "%-10s| %9d | " + " | ".join(["%13.1f%%"] * len(MECHANISM_PARTS))
print(PHEAD % (("STAGE", "MECH TURNS") + tuple(n.upper() for n, _ in MECHANISM_PARTS)))
for name in order + ["TOTAL"]:
    r = totals if name == "TOTAL" else by_stage[name]
    mech = r["mechanism"] or 1
    print(PROW % ((name[:10], r["mechanism"])
                  + tuple(100.0 * r["part:" + n] / mech for n, _ in MECHANISM_PARTS)))

# The floor a session starts from, against the climb inside it.
print("")
print("STARTUP FLOOR against the climb, per session")
print("%-10s| %6s | %11s | %11s | %11s | %9s" % ("STAGE", "SESSNS", "FLOOR TOK", "END TOK",
                                                 "CLIMB TOK", "FLOOR PCT"))
for name in sorted(by_stage, key=lambda n: -by_stage[n]["floorsess"]) + ["TOTAL"]:
    r = totals if name == "TOTAL" else by_stage[name]
    n = r["floorsess"]
    if not n:
        continue
    floor, end = r["floor"] // n, r["end"] // n
    print("%-10s| %6d | %11d | %11d | %11d | %8.1f%%" % (name[:10], n, floor, end, end - floor,
                                                         100.0 * floor / max(end, 1)))

# Where the context growth inside a session comes from. OWN PCT is the estimate FR3 asks for: the
# share of the rise attributable to the session talking to itself, against everything else that
# landed in the window -- files it read, tool output, and what the human typed.
print("")
GHEAD = "%-10s| %12s | %12s | %8s | %9s"
print(GHEAD % ("STAGE", "GROWTH TOK", "OWN OUT TOK", "OWN PCT", "OTHER PCT"))
for name in order + ["TOTAL"]:
    r = totals if name == "TOTAL" else by_stage[name]
    growth = r["growth"] or 1
    own = 100.0 * r["own"] / growth
    print("%-10s| %12d | %12d | %7.1f%% | %8.1f%%" % (name[:10], r["growth"], r["own"],
                                                      own, 100.0 - own))
PY
