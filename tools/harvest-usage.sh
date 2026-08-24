#!/bin/sh
#
# Harvest aggregate token usage and cost from Claude Code session transcripts (0026, FR10).
#
# Committed rather than run once in a conversation so that 0037 and 0036 can re-run the same
# method against later sessions instead of re-deriving it. The figures it produced on 2026-08-24
# are recorded, with their verdict, in MEASUREMENT.md.
#
# PRIVACY (0026's data-privacy NFR): this reads full conversation transcripts and its output is
# published in a public repo, so it emits ONLY aggregate numbers, skill names and session id
# prefixes. It never reads or prints message text, file contents, or any path it was not given.
# tests/measurement.test.sh asserts both halves: that a sentinel string in a fixture's message
# text does not reach the output, and that every output line stays inside a character set too
# narrow for prose.
#
# THE ONE THING THAT IS NOT OBVIOUS: a single API response is written to the transcript as
# SEVERAL lines — one per content block — and every one of them repeats the same complete `usage`
# object. Summing lines overcounts cost by roughly 2.2x on a real session. A turn is therefore a
# distinct `message.id`, and the first line carrying an id wins.
#
# Usage:
#   tools/harvest-usage.sh <transcript-dir> [--since YYYY-MM-DD] [--until YYYY-MM-DD]
#                          [--sessions] [--exclude <session-id-prefix>]
#
#   --since / --until  keep turns whose UTC timestamp date falls in the range, inclusive
#   --sessions         one row per session as well as the per-skill table
#   --exclude          drop a session by id prefix, repeatable; for the in-flight session that
#                      produced the harvest, whose own cost is not yet complete
#
# Requires: sh and python3. No packages — a one-directory JSON read does not earn a dependency.

set -eu

if [ $# -lt 1 ]; then
  echo "usage: $0 <transcript-dir> [--since YYYY-MM-DD] [--until YYYY-MM-DD] [--sessions] [--exclude <prefix>]" >&2
  exit 2
fi

DIR="$1"; shift
[ -d "$DIR" ] || { echo "no such transcript directory: $DIR" >&2; exit 2; }

exec python3 - "$DIR" "$@" <<'PY'
import json, os, re, sys, glob

# Per-million-token list rates, and the cache multipliers that apply to the input rate.
# Source: the claude-api skill's model table and shared/prompt-caching.md, read 2026-08-24.
# Cache read is 0.1x input; a 5-minute cache write is 1.25x input; a 1-hour cache write is 2x.
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

# A command marker only counts when the whole user message IS a command block. The same tag
# appears inside tool inputs and outputs in any session that has grepped a transcript, and one
# of those false positives would silently re-attribute every turn after it. The tags arrive in
# either order — `<command-message>` before `<command-name>` for a plugin skill, the reverse for
# a built-in — so the whole-message test is what does the work, not the position of the name.
CMD_ONLY = re.compile(
    r'^(?:\s*<command-(?:name|message|args)>[^<]*</command-(?:name|message|args)>)+\s*$')
CMD_NAME = re.compile(r'<command-name>\s*([^<]+?)\s*</command-name>')
WRAPPER = re.compile(r'<(local-command-caveat|local-command-stdout)>.*?</\1>', re.S)
SKILL_OF = re.compile(r'^/(?:ai-building-tools:)?(queue|design|develop|verify|retro|prototype)$')


def skill_from(marker):
    m = SKILL_OF.match(marker.strip())
    return m.group(1) if m else None


def text_of(content):
    """The user message as a plain string, for marker detection only. Never emitted."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        out = []
        for b in content:
            if isinstance(b, dict) and b.get("type") == "text":
                out.append(b.get("text", ""))
        return "\n".join(out)
    return ""


def cost_of(usage, model):
    rates = RATES.get(model)
    if rates is None:
        return None
    inp, outp = rates
    creation = usage.get("cache_creation") or {}
    w1h = creation.get("ephemeral_1h_input_tokens", 0) or 0
    w5m = creation.get("ephemeral_5m_input_tokens", 0) or 0
    total_creation = usage.get("cache_creation_input_tokens", 0) or 0
    # Where the split is absent, price the whole write at the cheaper 5-minute rate: a harvest
    # should understate a cost it cannot see rather than invent the expensive half.
    if w1h + w5m == 0:
        w5m = total_creation
    return (
        (usage.get("input_tokens", 0) or 0) * inp
        + (usage.get("cache_read_input_tokens", 0) or 0) * inp * CACHE_READ_MULT
        + w5m * inp * CACHE_WRITE_5M_MULT
        + w1h * inp * CACHE_WRITE_1H_MULT
        + (usage.get("output_tokens", 0) or 0) * outp
    ) / M


def context_of(usage):
    return ((usage.get("input_tokens", 0) or 0)
            + (usage.get("cache_read_input_tokens", 0) or 0)
            + (usage.get("cache_creation_input_tokens", 0) or 0))


def parse_args(argv):
    opts = {"since": None, "until": None, "sessions": False, "exclude": []}
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--sessions":
            opts["sessions"] = True
        elif a in ("--since", "--until", "--exclude"):
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


def harvest_session(path, opts):
    """One session: turns deduplicated by message id, split by the skill in force at the time."""
    per_skill = {}
    current = "unmarked"
    seen = set()
    unpriced = 0
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
            body = WRAPPER.sub("", text_of(d.get("message", {}).get("content"))).strip()
            if body and CMD_ONLY.match(body):
                names = CMD_NAME.findall(body)
                # Last marker wins: a session opens `/clear` then the skill, in that order.
                for name in reversed(names):
                    s = skill_from(name)
                    if s:
                        current = s
                        break
            continue
        if kind != "assistant":
            continue
        msg = d.get("message", {})
        usage = msg.get("usage")
        if not usage:
            continue
        mid = msg.get("id")
        if mid in seen:          # same response, another content block, same usage object
            continue
        seen.add(mid)
        day = (d.get("timestamp") or "")[:10]
        if opts["since"] and day and day < opts["since"]:
            continue
        if opts["until"] and day and day > opts["until"]:
            continue
        cost = cost_of(usage, msg.get("model"))
        if cost is None:
            unpriced += 1
            continue
        row = per_skill.setdefault(current, {"turns": 0, "cost": 0.0, "ctx": 0, "out": 0,
                                             "read": 0, "write": 0, "days": set()})
        row["turns"] += 1
        row["cost"] += cost
        row["ctx"] += context_of(usage)
        row["out"] += usage.get("output_tokens", 0) or 0
        row["read"] += usage.get("cache_read_input_tokens", 0) or 0
        row["write"] += usage.get("cache_creation_input_tokens", 0) or 0
        if day:
            row["days"].add(day)
    return per_skill, unpriced


def blank():
    return {"turns": 0, "cost": 0.0, "ctx": 0, "out": 0, "read": 0, "write": 0,
            "days": set(), "sessions": 0}


def add(dst, src):
    for k in ("turns", "cost", "ctx", "out", "read", "write"):
        dst[k] += src[k]
    dst["days"] |= src["days"]


def row(name, r):
    turns = r["turns"] or 1
    return "%-10s| %6d | %7d | %10.2f | %8.4f | %12d | %10d" % (
        name[:10], r.get("sessions", 0), r["turns"], r["cost"], r["cost"] / turns,
        r["ctx"], r["ctx"] // turns)


directory = sys.argv[1]
opts = parse_args(sys.argv[2:])

totals, by_skill, session_rows = blank(), {}, []
unpriced_total = 0
for path in sorted(glob.glob(os.path.join(directory, "*.jsonl"))):
    sid = os.path.basename(path).split("-")[0]
    if any(sid.startswith(x) or x.startswith(sid) for x in opts["exclude"]):
        continue
    per_skill, unpriced = harvest_session(path, opts)
    unpriced_total += unpriced
    if not per_skill:
        continue
    merged = blank()
    for name, r in per_skill.items():
        add(merged, r)
        s = by_skill.setdefault(name, blank())
        add(s, r)
        s["sessions"] += 1
    add(totals, merged)
    totals["sessions"] += 1
    merged["sessions"] = 1
    session_rows.append((sid, "/".join(sorted(per_skill)), merged))

print("HARVEST of %d sessions" % totals["sessions"])
print("RANGE %s to %s" % (min(totals["days"]) if totals["days"] else "none",
                          max(totals["days"]) if totals["days"] else "none"))
print("RATES per million: opus 5 in 5.00 out 25.00, cache read 0.1x in, write 1.25x in at 5m and 2.0x at 1h")
print("")
print("%-10s| %6s | %7s | %10s | %8s | %12s | %10s"
      % ("SKILL", "SESSNS", "TURNS", "COST USD", "USD/TURN", "CONTEXT TOK", "CTX/TURN"))
for name in sorted(by_skill, key=lambda n: -by_skill[n]["cost"]):
    print(row(name, by_skill[name]))
print(row("TOTAL", totals))
if unpriced_total:
    print("UNPRICED turns on a model with no published rate: %d" % unpriced_total)

# Where the context money actually goes. Isolation trades cache READS, at 0.1x input, for cache
# WRITES at 1.25x-2x — so a fall in context per turn does not buy a proportional fall in cost,
# and this block is what shows that rather than asserting it.
print("")
print("%-10s| %12s | %12s | %12s | %8s | %8s"
      % ("SKILL", "READ TOK", "WRITE TOK", "OUTPUT TOK", "READ PCT", "OUT PCT"))
for name in sorted(by_skill, key=lambda n: -by_skill[n]["cost"]) + ["TOTAL"]:
    r = totals if name == "TOTAL" else by_skill[name]
    ctx_tok = r["ctx"] or 1
    cost_usd = r["cost"] or 1.0
    print("%-10s| %12d | %12d | %12d | %7.1f%% | %7.1f%%"
          % (name[:10], r["read"], r["write"], r["out"],
             100.0 * r["read"] / ctx_tok, 100.0 * (r["out"] * 25.0 / M) / cost_usd))

if opts["sessions"]:
    print("")
    print("%-10s| %6s | %7s | %10s | %8s | %12s | %10s"
          % ("SESSION", "SESSNS", "TURNS", "COST USD", "USD/TURN", "CONTEXT TOK", "CTX/TURN"))
    for sid, skills, r in sorted(session_rows, key=lambda x: -x[2]["cost"]):
        print(row(sid, r) + " | " + skills)
PY
