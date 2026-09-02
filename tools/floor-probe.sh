#!/bin/sh
#
# What a session's STARTUP FLOOR costs under a given tool surface, and what removing part of that
# surface saves.
#
# WHY THIS EXISTS. `0073` published the floor -- 58,060 tokens, 44.4% of an end-of-session context
# -- and attributed 13,724 of it to this project's own prose, leaving ~44,336 as "the harness".
# Nobody had measured inside that block, so "trim the tool surface" was a proposal resting on an
# assumption about a number that had never been read. This repo's own history is that an unread
# number is a wrong number: `0009` modelled a 66% saving and observed 14.5%.
#
# WHAT IT MEASURES. The floor is the FIRST turn's context -- `input + cache_read + cache_creation`
# of the first assistant response -- which is the same definition `tools/classify-turns.sh` uses,
# deliberately, so the two are comparable. Everything a session loads before it acts is in it:
# the harness system prompt, every tool definition, the skill listing, the MCP tool names and
# server instructions, and whatever `CLAUDE.md` imports.
#
# WHY A DIFFERENCE AND NOT A BREAKDOWN. Nothing reports the size of a tool definition. What can be
# measured is a whole floor, so each component is read as the difference between two floors that
# differ only in that component. That makes every figure here a subtraction between two OBSERVED
# runs rather than an estimate, at the cost of needing a run per configuration.
#
# TWO MODES.
#   --run   launches N sessions per configuration and measures them. Needs the `claude` CLI.
#   --read  reads back an already-run, pinned set of session ids from a transcript store. This is
#           the mode a published figure is reproduced with, for the same reason every other recipe
#           in MEASUREMENT.md pins an id set: a date window on a live store decays silently.
#
# WHY THE PARSING IS DUPLICATED from tools/harvest-usage.sh, tools/classify-turns.sh and
# tools/cost-by-category.sh: those three are pinned reproducers of published tables and a refactor
# puts those figures at risk to save a few lines. All four state the same fact -- a turn is a
# distinct `message.id`. This script needs only the first turn, so it stops at it.
#
# PRIVACY (inherited from 0073's data-privacy NFR). This repo is public and transcripts hold prose,
# edit payloads and shell commands. This script emits ONLY configuration labels, counts and
# aggregate token figures. `tests/floor-probe.test.sh` asserts that against a sentinel fixture.
#
# Usage:
#   tools/floor-probe.sh --read <transcript-store> --config <label>:<sid>,<sid>... [--config ...]
#   tools/floor-probe.sh --run [--reps N] [--prompt TEXT] --config <label>:<cli-args> [--config ...]
#
# The FIRST --config is the baseline; every other is reported as a saving against it.
#
# Requires: sh, python3 (and the `claude` CLI for --run).

set -eu

exec python3 - "$@" <<'PY'
import glob, json, os, subprocess, sys

BANNER = "usage: floor-probe.sh --read <store> --config <label>:<sid>,<sid>...\n" \
         "       floor-probe.sh --run [--reps N] [--prompt TEXT] --config <label>:<cli-args>"


def die(msg):
    sys.stderr.write("floor-probe: %s\n%s\n" % (msg, BANNER))
    sys.exit(2)


def parse_args(argv):
    mode = store = None
    reps = 3
    prompt = "Reply with exactly: ok"
    configs = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--read":
            if mode:
                die("--read and --run are exclusive")
            mode = "read"
            i += 1
            if i >= len(argv):
                die("--read needs a transcript store directory")
            store = argv[i]
        elif a == "--run":
            if mode:
                die("--read and --run are exclusive")
            mode = "run"
        elif a == "--reps":
            i += 1
            if i >= len(argv) or not argv[i].isdigit() or int(argv[i]) < 1:
                die("--reps needs a positive integer")
            reps = int(argv[i])
        elif a == "--prompt":
            i += 1
            if i >= len(argv):
                die("--prompt needs text")
            prompt = argv[i]
        elif a == "--config":
            i += 1
            if i >= len(argv) or ":" not in argv[i]:
                die("--config needs <label>:<value>")
            label, _, rest = argv[i].partition(":")
            if not label or not rest:
                die("--config needs a non-empty label and value")
            configs.append((label, rest))
        elif a in ("-h", "--help"):
            print(BANNER)
            sys.exit(0)
        else:
            die("unknown argument: %s" % a)
        i += 1
    if not mode:
        die("one of --read or --run is required")
    if not configs:
        die("at least one --config is required")
    return mode, store, reps, prompt, configs


def floor_of(path):
    """The first assistant turn's context: input + cache_read + cache_creation.

    Only the first turn is read. A session that recorded no assistant turn has no floor and is
    reported as missing rather than counted as zero -- a zero would drag a mean toward a figure
    no run produced.
    """
    with open(path) as fh:
        for line in fh:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if d.get("type") != "assistant":
                continue
            u = (d.get("message") or {}).get("usage")
            if not u:
                continue
            return (u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0)
                    + u.get("cache_creation_input_tokens", 0))
    return None


def read_mode(store, configs):
    if not os.path.isdir(store):
        die("no such transcript store: %s" % os.path.basename(store.rstrip("/")))
    out = []
    for label, sids in configs:
        floors = []
        for sid in sids.split(","):
            sid = sid.strip()
            if not sid:
                die("empty session id in --config %s" % label)
            matches = glob.glob(os.path.join(store, sid + "*.jsonl"))
            # Refuse rather than guess (CONCURRENCY.md, The three scripts). Silently dropping a
            # session publishes a mean over a denominator the recipe does not name.
            if len(matches) != 1:
                die("session %s matches %d transcripts in the store; expected exactly 1"
                    % (sid[:8], len(matches)))
            f = floor_of(matches[0])
            if f is None:
                die("session %s recorded no assistant turn, so it has no floor" % sid[:8])
            floors.append(f)
        out.append((label, floors))
    return out


def run_mode(reps, prompt, configs):
    out = []
    for label, cli in configs:
        floors = []
        for _ in range(reps):
            cmd = ["claude", "-p", prompt, "--output-format", "json"] + cli.split()
            try:
                res = subprocess.run(cmd, capture_output=True, text=True, stdin=subprocess.DEVNULL)
            except OSError:
                die("cannot launch the claude CLI; --run needs it on PATH")
            if res.returncode != 0:
                die("configuration %s exited %d" % (label, res.returncode))
            try:
                d = json.loads(res.stdout)
            except ValueError:
                die("configuration %s produced no JSON result" % label)
            # The result JSON carries the session's FINAL usage, not its first turn's, so the
            # floor is read back from the transcript. Reading it from here instead reports the end
            # context and overstates every floor by the whole climb -- observed, 108k for a 47k
            # floor, which is why this indirection exists.
            sid = d.get("session_id", "")
            store = os.path.expanduser("~/.claude/projects")
            matches = glob.glob(os.path.join(store, "*", sid + "*.jsonl"))
            if len(matches) != 1:
                die("cannot locate the transcript for a session just run under %s" % label)
            f = floor_of(matches[0])
            if f is None:
                die("a session just run under %s recorded no assistant turn" % label)
            floors.append(f)
            sys.stderr.write("floor-probe: %s %s %d\n" % (label, sid[:8], f))
        out.append((label, floors))
    return out


def report(rows):
    print("STARTUP FLOOR by tool surface. The floor is the context of the first turn.")
    print("%-18s | %8s | %9s | %11s | %9s" % ("CONFIG", "RUNS", "MEAN", "SAVING", "PCT"))
    base = sum(rows[0][1]) / float(len(rows[0][1]))
    for label, floors in rows:
        mean = sum(floors) / float(len(floors))
        saving = base - mean
        print("%-18s | %8d | %9d | %11d | %8.1f%%"
              % (label[:18], len(floors), round(mean), round(saving),
                 100.0 * saving / base if base else 0.0))
    print()
    print("Baseline is the first configuration. SAVING is tokens removed from the floor, and")
    print("so from every later turn: a prefix token removed is removed for the whole session.")


mode, store, reps, prompt, configs = parse_args(sys.argv[1:])
report(read_mode(store, configs) if mode == "read" else run_mode(reps, prompt, configs))
PY
