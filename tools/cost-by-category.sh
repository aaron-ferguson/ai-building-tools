#!/bin/sh
#
# What a turn of each category COSTS, on the same pinned set `tools/classify-turns.sh` counts
# (0085, from 0073's figures).
#
# WHY THIS EXISTS. `0073` published shares of TURNS: the backlog protocol is 34.3% of every turn
# in the suite. Nobody had measured what a turn of each category costs, and the two are not the
# same question. A protocol turn is a short command and a short result; a work turn is a file
# read, an edit and a test run. If protocol turns were cheap turns, removing nine of them would
# save far less than the turn share suggests and the reduction would be aimed at the wrong
# denominator while looking rigorous. This script is what settles that, in committed code, before
# any prediction is accepted.
#
# THE ANSWER IT GIVES, AND WHY IT IS NOT THE INTUITIVE ONE. In a cached agentic loop the dominant
# per-turn cost is re-reading the context, and that is very nearly category-blind: every turn pays
# for the whole conversation so far whatever it does with it. A short command does not buy a
# cheap turn. What differs by category is output tokens, which are the minority of the bill.
#
# WHY THE PARSING IS DUPLICATED from tools/harvest-usage.sh and tools/classify-turns.sh. Both are
# pinned as reproducers of published tables (`0051`, `0073`), and a refactor of either puts those
# figures at risk to save about eighty lines. The turn-dedup rule, the marker detection and the
# classification patterns are copied deliberately. All three files state the same two facts: a
# turn is a distinct `message.id`, and the skill marker arrives in either tag order after a
# `/clear`. CHANGE ONE, CHANGE ALL THREE.
#
# PRIVACY (0073's data-privacy NFR, which this script inherits). It reads shell command strings
# and edit payloads, so it is one of the two scripts that could publish one. It emits ONLY
# category names, counts and aggregate token and dollar figures. `tests/cost-by-category.test.sh`
# asserts that against a fixture planting a sentinel in a message, in an edit payload and inside
# a shell command.
#
# Usage:
#   tools/cost-by-category.sh <transcript-dir> [--since YYYY-MM-DD] [--until YYYY-MM-DD]
#                             [--exclude <session-id-prefix>]
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
import json, os, re, sys, glob, collections

CATEGORIES = ("mechanism", "orientation", "work", "narration", "other")
PRECEDENCE = ("work", "mechanism", "orientation", "other")

MECHANISM = re.compile(r"""
      backlog/(claim|close|next|hand)
    | \./(claim|close|next)\b
    | \.lock\b
    | (queue|done|findings|ranking|ranking-history|scheduled)\.md
    | config\.yml
    | git\s+(commit|add|status|diff|log|stash|restore|rev-parse|push|pull|fetch|worktree|show|branch|checkout|rm|mv)
""", re.X | re.I)

# The one split this script adds to 0073's: the backlog protocol and the git bookkeeping around it
# are two different fixes, and only the first is this backlog's cost to remove.
GIT_ONLY = re.compile(r"git\s+", re.I)
BACKLOG  = re.compile(r"""
      backlog/(claim|close|next|hand)
    | \./(claim|close|next)\b
    | \.lock\b
    | (queue|done|findings|ranking|ranking-history|scheduled)\.md
    | config\.yml
""", re.X | re.I)

TESTS = re.compile(r"(\.test\.sh|\btests?/|\bnpm\s+(test|run\s+test)|\bpytest\b|\bjest\b|\bgo\s+test\b)", re.I)
WRITES = re.compile(r"""
      sed\s+-i
    | \btee\b
    | >>?\s*[\w./~-]
    | <<\s*'?[A-Za-z]
    | \b(mv|cp|rm|mkdir|touch|chmod|ln|patch)\s
""", re.X | re.I)
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

WRITE_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
READ_TOOLS = {"Read", "Glob", "Grep", "ToolSearch", "WebFetch", "WebSearch", "Skill"}

RATES = {
    "claude-opus-5":   (5.00, 25.00),
    "claude-opus-4-8": (5.00, 25.00),
    "claude-sonnet-5": (3.00, 15.00),
    "claude-haiku-4-5": (1.00, 5.00),
}
CACHE_READ_MULT = 0.1
CACHE_WRITE_5M_MULT = 1.25
CACHE_WRITE_1H_MULT = 2.0
M = 1_000_000

CMD_ONLY = re.compile(
    r'^(?:\s*<command-(?:name|message|args)>[^<]*</command-(?:name|message|args)>)+\s*$')
CMD_NAME = re.compile(r'<command-name>\s*([^<]+?)\s*</command-name>')
WRAPPER = re.compile(r'<(local-command-caveat|local-command-stdout)>.*?</\1>', re.S)
SKILL_OF = re.compile(r'^/(?:ai-building-tools:)?(queue|design|develop|verify|retro|prototype)$')


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
    found = []
    for b in blocks:
        c = category_of_call(b)
        if c not in found:
            found.append(c)
    if not found:
        return "narration"
    for c in PRECEDENCE:
        if c in found:
            return c
    return "other"


def text_for(blocks):
    """Command strings and paths, joined. Used for matching ONLY and never emitted."""
    return " ".join(str((b.get("input") or {}).get("command")
                        or (b.get("input") or {}).get("file_path") or "") for b in blocks)


def mechanism_split(blocks):
    """`protocol` or `git`. A turn touching both is protocol: the backlog work is the reason the
    turn happened and the git call is what the protocol made it do."""
    t = text_for(blocks)
    if BACKLOG.search(t):
        return "protocol"
    if GIT_ONLY.search(t):
        return "git"
    return "protocol"


def text_of(content):
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


def context_of(u):
    return ((u.get("input_tokens", 0) or 0)
            + (u.get("cache_read_input_tokens", 0) or 0)
            + (u.get("cache_creation_input_tokens", 0) or 0))


def cost_of(usage, model):
    """(total, output-only) dollars, or None on a model with no published rate."""
    rates = RATES.get(model)
    if rates is None:
        return None
    inp, outp = rates
    creation = usage.get("cache_creation") or {}
    w1h = creation.get("ephemeral_1h_input_tokens", 0) or 0
    w5m = creation.get("ephemeral_5m_input_tokens", 0) or 0
    total_creation = usage.get("cache_creation_input_tokens", 0) or 0
    # Where the split is absent, price the whole write at the cheaper 5-minute rate: understate a
    # cost you cannot see rather than invent the expensive half.
    if w1h + w5m == 0:
        w5m = total_creation
    output_cost = (usage.get("output_tokens", 0) or 0) * outp / M
    input_cost = (
        (usage.get("input_tokens", 0) or 0) * inp
        + (usage.get("cache_read_input_tokens", 0) or 0) * inp * CACHE_READ_MULT
        + w5m * inp * CACHE_WRITE_5M_MULT
        + w1h * inp * CACHE_WRITE_1H_MULT
    ) / M
    return input_cost + output_cost, output_cost


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
                opts["exclude"].append(argv[i])
            else:
                opts[a[2:]] = argv[i]
        else:
            sys.exit("unknown argument: %s" % a)
        i += 1
    return opts


def read_turns(path, opts):
    """Turns in transcript order. Usage from the FIRST line of a message id, blocks UNIONED across
    all of them: one API response is written as several lines each repeating the whole usage
    object, so cost must count an id once while classification must see every block (0073)."""
    turns, index, stage = [], {}, "unmarked"
    for line in open(path, errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
        except ValueError:
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
        turn = {"stage": stage, "usage": usage, "blocks": blocks, "model": msg.get("model")}
        index[mid] = turn
        turns.append(turn)
    return turns


def blank():
    return {"n": 0, "cost": 0.0, "outcost": 0.0, "ctx": 0, "out": 0, "marg": 0, "mn": 0, "later": 0}


def main():
    opts = parse_args(sys.argv[2:])
    store = sys.argv[1]
    by = collections.defaultdict(blank)
    stage_rows = collections.defaultdict(blank)
    stage_sessions = collections.Counter()
    stage_turns = collections.Counter()
    sessions = unpriced = 0

    for path in sorted(glob.glob(os.path.join(store, "*.jsonl"))):
        sid = os.path.basename(path)[:-6]
        if any(sid.startswith(x) for x in opts["exclude"]):
            continue
        turns = read_turns(path, opts)
        if not turns:
            continue
        sessions += 1
        T = len(turns)
        seen = set()
        for i, t in enumerate(turns):
            cat = category_of_turn(t["blocks"])
            bucket = cat
            if cat == "mechanism":
                bucket = mechanism_split(t["blocks"])
            st = t["stage"]
            if st not in seen:
                stage_sessions[st] += 1
                seen.add(st)
            stage_turns[st] += 1

            priced = cost_of(t["usage"], t["model"])
            if priced is None:
                unpriced += 1
                total_c = out_c = 0.0
            else:
                total_c, out_c = priced

            # The rise from this turn to the next is what this turn appended: its own output and
            # its tool results. Attributed to THIS turn, not the next -- the off-by-one that would
            # credit every footprint to the following category.
            rise = 0
            if i + 1 < T:
                rise = context_of(turns[i + 1]["usage"]) - context_of(t["usage"])
                rise = rise if rise > 0 else 0

            for key in (bucket, "TOTAL"):
                r = by[key]
                r["n"] += 1
                r["cost"] += total_c
                r["outcost"] += out_c
                r["ctx"] += context_of(t["usage"])
                r["out"] += t["usage"].get("output_tokens", 0) or 0
                r["later"] += T - i - 1
                if rise:
                    r["marg"] += rise
                    r["mn"] += 1

            key = (st, "protocol" if bucket == "protocol" else "rest")
            r = stage_rows[key]
            r["n"] += 1
            r["cost"] += total_c

    if not sessions:
        sys.exit("no sessions matched")

    tot = by["TOTAL"]
    print("COST BY CATEGORY of %d sessions, %d turns" % (sessions, tot["n"]))
    print("`mechanism` is split: `protocol` is this backlog's own cost, `git` is what any project pays")
    print()
    print("%-12s %6s %8s %10s %8s %9s %9s %9s" % (
        "bucket", "turns", "turn%", "$ total", "$ %", "$/turn", "ctx/turn", "marg/turn"))
    order = [k for k in ("protocol", "git", "work", "orientation", "narration", "other") if by[k]["n"]]
    for key in order + ["TOTAL"]:
        r = by[key]
        n = r["n"] or 1
        mn = r["mn"] or 1
        print("%-12s %6d %7.1f%% %10.4f %7.1f%% %9.4f %9.0f %9.0f" % (
            key, r["n"], 100.0 * r["n"] / tot["n"], r["cost"],
            100.0 * r["cost"] / (tot["cost"] or 1), r["cost"] / n, r["ctx"] / n, r["marg"] / mn))

    print()
    print("WHAT REMOVING ONE TURN SAVES: its own billed request, plus the cache reads every later")
    print("turn no longer pays for what it appended. The second term is why a fusion pays twice.")
    print("%-12s %12s %16s %14s" % ("bucket", "$ own/turn", "$ compound/turn", "$ total/turn"))
    for key in order + ["TOTAL"]:
        r = by[key]
        n = r["n"] or 1
        mn = r["mn"] or 1
        own = r["cost"] / n
        comp = (r["marg"] / mn) * (r["later"] / n) * 5.00 * CACHE_READ_MULT / M
        print("%-12s %12.4f %16.4f %14.4f" % (key, own, comp, own + comp))

    print()
    print("PER STAGE: protocol turns and what they cost, per session")
    print("%-10s %7s %7s %11s %11s %12s %11s" % (
        "stage", "sessns", "turns", "turns/sessn", "prot/sessn", "$/session", "prot $ %"))
    for st in sorted(stage_sessions, key=lambda s: -stage_sessions[s]):
        ns = stage_sessions[st] or 1
        p, rest = stage_rows[(st, "protocol")], stage_rows[(st, "rest")]
        total = p["cost"] + rest["cost"]
        print("%-10s %7d %7d %11.1f %11.1f %12.2f %10.1f%%" % (
            st, stage_sessions[st], stage_turns[st], stage_turns[st] / ns, p["n"] / ns,
            total / ns, 100.0 * p["cost"] / (total or 1)))

    if unpriced:
        print()
        print("UNPRICED turns on a model with no published rate: %d" % unpriced)


main()
PY
