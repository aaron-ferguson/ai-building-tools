#!/bin/sh
#
# The sprint estimate ledger: write an estimate before the work, pair it with the actual after,
# and derive the next estimate from what accumulated (0135).
#
# WHY THIS IS A SCRIPT AND NOT PROSE IN THE SKILL. Every other cost figure in this repo is an
# actual. An estimate that is never scored cannot improve, and a supervisor asked to score one by
# hand writes down the half it remembers. The two modes here are the two halves:
#
#   estimate   what this sprint is expected to cost, in tickets, wall-clock, tokens and dollars,
#              derived from LEDGER.md's recorded actuals where any exist and from MEASUREMENT.md's
#              per-skill table where none do. A figure with no prior on either side is LABELLED as
#              having none rather than printed like a derived one -- as at 2026-09-10 wall-clock is
#              exactly that figure, because MEASUREMENT.md records no elapsed time at all.
#
#   record     the same four figures as actuals, appended to LEDGER.md beside the estimate, plus
#              the three model checks the ledger exists to make falsifiable: a develop gate's
#              observed cost against config.yml's linear prediction for that ticket count, verify
#              cost per ticket for batched and unbatched sessions, and findings parked.
#
# PROVENANCE IS THE POINT, NOT A DECORATION. Every figure carries the source it was read from and
# the stamp it was true at, and BOTH SIDES OF EVERY RATIO carry one. A pinned numerator over a live
# denominator decays silently while the arithmetic on the page stays self-consistent and every
# citation still resolves -- the defect MEASUREMENT.md shipped and 0051 repaired. That is why a
# ratio is written as three lines here and never as one.
#
# PRIVACY (0135's data-privacy NFR, and 0026's before it): the ledger is committed to a public
# repo. This reads run logs and, through tools/harvest-usage.sh, full conversation transcripts, and
# it emits ONLY aggregate numbers, stage names, file paths it was given, and session-id prefixes.
# It never reads or prints message text. tests/sprint-ledger.test.sh asserts both halves against a
# fixture transcript carrying a sentinel string.
#
# WALL-CLOCK COMES FROM THE RUN LOG'S OWN TIMESTAMPS AND NOTHING IS ADDED TO PRODUCE IT. Every
# event already carries a UTC stamp, and the first and last of them bracket the run. The key is
# read as `ts`, `at` or `timestamp` because the skill's Step 5 requires a stamp and does not name
# the field; pinning a fourth name here would be new instrumentation, which FR2 forbids.
#
# Usage:
#   tools/sprint-ledger.sh estimate --ledger <LEDGER.md> --measurement <MEASUREMENT.md>
#                                   --config <config.yml> --tickets N
#                                   [--develop-gates N] [--verify-sessions N] [--retro]
#
#   tools/sprint-ledger.sh record   --ledger <LEDGER.md> --run <run-log.jsonl>
#                                   --transcripts <dir> --measurement <MEASUREMENT.md>
#                                   --config <config.yml>
#                                   --estimate-tickets N --estimate-wall <N|no-prior>
#                                   --estimate-tokens N --estimate-usd N
#                                   --estimate-source <string>
#
# Requires: sh and python3. No packages -- consistent with tools/harvest-usage.sh.

set -eu

if [ $# -lt 1 ]; then
  echo "usage: $0 estimate|record --ledger <path> ..." >&2
  exit 2
fi

HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

exec python3 - "$HERE" "$@" <<'PY'
import json, os, re, subprocess, sys
from datetime import datetime, timezone

HERE = sys.argv[1]
HARVEST = os.path.join(HERE, "harvest-usage.sh")

FIGURES = ["tickets", "wall_clock_min", "tokens", "usd"]
NO_PRIOR = "no prior"


def die(msg):
    sys.exit("sprint-ledger: %s" % msg)


def now_stamp():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# --- MEASUREMENT.md -----------------------------------------------------------------------------
# The per-skill table is the prior for everything but wall-clock. Both halves of each mean come
# from the SAME row -- cost and sessions, turns and sessions -- so neither side of the division can
# go stale while the other does not.
SKILL_ROW = re.compile(
    r"^\|\s*(develop|verify|queue|retro|design)\s*\|\s*([\d,]+)\s*\|\s*([\d,]+)\s*\|"
    r"\s*\$?([\d.,]+)\s*\|\s*\$?([\d.,]+)\s*\|\s*([\d,]+)\s*\|")


def num(s):
    return float(s.replace(",", "").replace("$", ""))


def read_measurement(path):
    """{stage: {usd_per_session, turns_per_session, ctx_per_turn}}, plus the record's own stamp."""
    if not os.path.exists(path):
        die("no measurement record at %s" % path)
    text = open(path, errors="replace").read()
    m = re.search(r"Recorded\s+(\d{4}-\d{2}-\d{2})", text)
    stamp = m.group(1) if m else "unstamped"
    stages = {}
    for line in text.splitlines():
        m = SKILL_ROW.match(line)
        if not m:
            continue
        stage, sessions, turns, cost, _cost_per_turn, ctx_per_turn = m.groups()
        if stage in stages:          # the first table wins; later ones restate it
            continue
        sessions, turns = num(sessions), num(turns)
        if sessions <= 0:
            continue
        stages[stage] = {
            "usd_per_session": num(cost) / sessions,
            "turns_per_session": turns / sessions,
            "ctx_per_turn": num(ctx_per_turn),
        }
    if not stages:
        die("no per-skill table found in %s" % path)
    return stages, "MEASUREMENT.md per-skill table, recorded %s" % stamp


# --- config.yml ---------------------------------------------------------------------------------
def read_config(path):
    """stage_budget_usd's base and per_extra_ticket, and the stamp its comment carries."""
    if not os.path.exists(path):
        die("no config at %s" % path)
    text = open(path, errors="replace").read()
    m = re.search(r"as at\s+(\d{4}-\d{2}-\d{2})", text)
    stamp = m.group(1) if m else "unstamped"
    base, extra = {}, {}
    section = None
    for line in text.splitlines():
        if re.match(r"^stage_budget_usd:", line):
            section = "base"
            continue
        if section and re.match(r"^\S", line):
            section = None
            continue
        if section is None:
            continue
        if re.match(r"^\s+per_extra_ticket:", line):
            section = "extra"
            continue
        m = re.match(r"^\s+(\w+):\s*([\d.]+)", line)
        if m:
            (extra if section == "extra" else base)[m.group(1)] = float(m.group(2))
    return base, extra, "config.yml stage_budget_usd, as at %s" % stamp


# --- LEDGER.md ----------------------------------------------------------------------------------
# A recorded sprint is a `## sprint` heading followed by a four-row table. Read back as
# {figure: actual}; a figure whose actual is not a number is simply absent, which is how a sprint
# that could not measure something stays a legitimate row rather than poisoning the mean.
def read_ledger(path):
    if not os.path.exists(path):
        return []
    sprints, current = [], None
    for line in open(path, errors="replace"):
        if line.startswith("## sprint "):
            current = {}
            sprints.append(current)
            continue
        if current is None:
            continue
        m = re.match(r"^\|\s*(\w+)\s*\|([^|]*)\|([^|]*)\|", line)
        if not m:
            continue
        figure, _est, actual = m.group(1), m.group(2).strip(), m.group(3).strip()
        if figure not in FIGURES:
            continue
        try:
            current[figure] = float(actual)
        except ValueError:
            pass
    return [s for s in sprints if s]


# --- the estimate -------------------------------------------------------------------------------
def estimate(opts):
    stages, meas_src = read_measurement(opts["measurement"])
    sprints = read_ledger(opts["ledger"])
    stamp = now_stamp()
    tickets = opts["tickets"]
    gates = opts["develop_gates"]
    verify_sessions = opts["verify_sessions"]

    # Per-ticket means from the recorded history. Both sides of the division are read from the same
    # set of sprint blocks at the same moment, so neither can be pinned while the other is live.
    hist = {}
    total_tickets = sum(s.get("tickets", 0) for s in sprints if "tickets" in s)
    if sprints and total_tickets > 0:
        for figure in ("wall_clock_min", "tokens", "usd"):
            have = [s for s in sprints if figure in s and "tickets" in s]
            denom = sum(s["tickets"] for s in have)
            if have and denom > 0:
                hist[figure] = sum(s[figure] for s in have) / denom
    ledger_src = "LEDGER.md %d recorded sprint(s) over %d ticket(s)" % (
        len(sprints), int(total_tickets))

    lines = []

    def emit(figure, value, source):
        if value is None:
            lines.append("ESTIMATE  %-15s %-12s source: %s @ %s" % (figure, NO_PRIOR, source, stamp))
        elif figure in ("tickets", "tokens", "wall_clock_min"):
            lines.append("ESTIMATE  %-15s %-12d source: %s @ %s" % (figure, round(value), source, stamp))
        else:
            lines.append("ESTIMATE  %-15s %-12.2f source: %s @ %s" % (figure, value, source, stamp))

    emit("tickets", tickets, "confirmed scope")

    if "wall_clock_min" in hist:
        emit("wall_clock_min", hist["wall_clock_min"] * tickets, ledger_src)
    else:
        # The one figure the repo cannot source from anywhere. It is labelled rather than guessed,
        # because a proposal showing three derived figures where one is invented is worse than one
        # showing two and an admission.
        emit("wall_clock_min", None,
             "none -- MEASUREMENT.md records no elapsed time and LEDGER.md holds no recorded actual")

    plan = [("develop", gates, tickets - gates),
            ("verify", verify_sessions, tickets - verify_sessions)]
    if opts["retro"]:
        plan.append(("retro", 1, 0))

    for figure in ("tokens", "usd"):
        if figure in hist:
            emit(figure, hist[figure] * tickets, ledger_src)
        else:
            emit(figure, prior_total(figure, stages, plan), meas_src)

    return "\n".join(lines)


def prior_total(figure, stages, plan):
    """What `plan` costs at MEASUREMENT.md's per-session means. `plan` is (stage, sessions, extra
    tickets): a gate's saving is the startup floor and not the work, so a ticket beyond the first
    is charged at the same mean rather than at nothing."""
    total = 0.0
    for stage, n_sessions, n_extra in plan:
        s = stages.get(stage)
        if not s:
            continue
        per_session = (s["usd_per_session"] if figure == "usd"
                       else s["ctx_per_turn"] * s["turns_per_session"])
        total += per_session * (max(n_sessions, 0) + max(n_extra, 0))
    return total


# --- the run log --------------------------------------------------------------------------------
TS_KEYS = ("ts", "at", "timestamp")


def read_run(path):
    if not os.path.exists(path):
        die("no run log at %s" % path)
    events = []
    for line in open(path, errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except ValueError:
            # A log being appended to right now ends in a partial line. Losing the event in flight
            # is better than a harvest of a live run that cannot run at all.
            continue
    if not events:
        die("run log %s carries no events" % path)
    return events


def stamps_of(events):
    out = []
    for e in events:
        for k in TS_KEYS:
            if isinstance(e.get(k), str):
                out.append(e[k])
                break
    return out


def parse_ts(s):
    return datetime.strptime(s.replace("Z", "+0000"), "%Y-%m-%dT%H:%M:%S%z")


def wall_clock_minutes(events):
    ss = sorted(stamps_of(events))
    if len(ss) < 2:
        return None
    try:
        return (parse_ts(ss[-1]) - parse_ts(ss[0])).total_seconds() / 60.0
    except ValueError:
        return None


def ticket_ids(entry):
    """A run log writes `tickets` either as ids or as outcome objects. Both are read, because the
    supervisor's own fixtures in tests/sprint.test.sh already use both shapes."""
    out = []
    for t in entry.get("tickets") or []:
        if isinstance(t, str):
            out.append(t)
        elif isinstance(t, dict) and isinstance(t.get("id"), str):
            out.append(t["id"])
    return out


def sessions_of(events):
    """[(stage, session_id, [ticket ids])] in dispatch order, one per stage session."""
    out, seen = [], set()
    for e in events:
        sid = e.get("session_id")
        if not isinstance(sid, str) or sid in seen:
            continue
        seen.add(sid)
        out.append([e.get("stage"), sid, ticket_ids(e)])
    # An outcome names the tickets a dispatch may only have predicted; the later, truer list wins.
    by_sid = {row[1]: row for row in out}
    for e in outcomes_of(events):
        ids = ticket_ids(e)
        row = by_sid.get(e.get("session_id"))
        if row and ids:
            row[2] = ids
    return out


def outcomes_of(events):
    return [e for e in events
            if e.get("event") == "outcome" and isinstance(e.get("session_id"), str)]


def harvest(transcripts, session_ids):
    """(usd, context tokens) over exactly these sessions. Shelling out rather than reimporting the
    pricing: two copies of the rate table is the divergence a single source exists to prevent."""
    if not session_ids:
        return 0.0, 0
    cmd = [HARVEST, transcripts]
    for sid in session_ids:
        cmd += ["--session", sid]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    except OSError as exc:
        die("could not run %s: %s" % (HARVEST, exc))
    # Both of these once returned (0.0, 0), which is worse than refusing: the row below cites
    # harvest-usage.sh as the source of a number harvest-usage.sh never produced, and a false
    # citation is exactly the silent decay FR8 and this file's preamble exist to prevent.
    # NOT the empty store -- a real directory holding none of the run's sessions makes
    # harvest-usage.sh exit 0 with a TOTAL line reading 0.00, which is a MEASURED zero and is
    # recorded as one. Only a non-zero exit or an unparsable stdout reaches a die() here.
    if proc.returncode != 0:
        die("%s failed (exit %d) over %s: %s"
            % (os.path.basename(HARVEST), proc.returncode, transcripts,
               (proc.stderr or "").strip() or "no stderr"))
    for line in proc.stdout.splitlines():
        m = re.match(r"^TOTAL\s*\|\s*\d+\s*\|\s*\d+\s*\|\s*([\d.]+)\s*\|\s*[\d.]+\s*\|\s*(\d+)",
                     line)
        if m:
            return float(m.group(1)), int(m.group(2))
    # The output is quoted, not just counted: "printed no parsable TOTAL line" is unactionable on
    # its own, and a format change is the likeliest cause. Newlines collapse so the whole refusal
    # stays one line, and it is truncated because harvest output is unbounded.
    shown = "; ".join(proc.stdout.split("\n")).strip()
    die("%s exit 0 over %s but printed no parsable TOTAL line; its output was: %s"
        % (os.path.basename(HARVEST), transcripts, shown[:300] or "empty"))


# --- record -------------------------------------------------------------------------------------
def record(opts):
    events = read_run(opts["run"])
    base, extra, conf_src = read_config(opts["config"])
    stamp = now_stamp()
    log_name = os.path.basename(opts["run"])
    log_src = "%s event timestamps" % log_name
    outcome_src = "%s outcome events" % log_name
    harvest_src = "harvest-usage.sh over %d session id(s)"

    sessions = sessions_of(events)
    run_ids = [sid for _stage, sid, _t in sessions]
    all_tickets = sorted({t for _s, _i, ts in sessions for t in ts})

    usd, ctx = harvest(opts["transcripts"], run_ids)
    wall = wall_clock_minutes(events)
    run_id = next((e.get("run") or e.get("run_id") for e in events
                   if e.get("run") or e.get("run_id")), "unnamed")

    actual = {
        "tickets": len(all_tickets),
        "wall_clock_min": None if wall is None else round(wall),
        "tokens": ctx,
        "usd": usd,
    }
    est = {
        "tickets": opts["estimate_tickets"],
        "wall_clock_min": opts["estimate_wall"],
        "tokens": opts["estimate_tokens"],
        "usd": opts["estimate_usd"],
    }

    def cell(figure, value):
        if value is None:
            return "not measured"
        if isinstance(value, str):
            return value
        return "%.2f" % value if figure == "usd" else "%d" % round(value)

    out = []
    out.append("")
    out.append("## sprint %s -- ended %s" % (run_id, sorted(stamps_of(events))[-1]))
    out.append("")
    out.append("| Figure | Estimate | Actual | Estimate source |")
    out.append("|---|---|---|---|")
    for figure in FIGURES:
        src = "confirmed scope @ %s" % stamp if figure == "tickets" else opts["estimate_source"]
        out.append("| %s | %s | %s | %s |"
                   % (figure, cell(figure, est[figure]), cell(figure, actual[figure]), src))
    out.append("")

    # FR6 -- the linear gate model, made falsifiable. Predicted and observed sit on one line
    # precisely so that neither can be recorded without the other.
    for stage, sid, tickets in sessions:
        if stage != "develop" or len(tickets) < 1:
            continue
        n = len(tickets)
        predicted = base.get("develop", 0.0) + extra.get("develop", 0.0) * (n - 1)
        observed, _ = harvest(opts["transcripts"], [sid])
        out.append("GATE develop %d ticket(s) session %s: predicted USD %.2f (%s @ %s) "
                   "observed USD %.2f (%s @ %s)"
                   % (n, sid.split("-")[0], predicted, conf_src, stamp, observed,
                      harvest_src % 1, stamp))

    # FR7 -- verify cost per ticket, batched against unbatched. Written as three lines because both
    # sides of a ratio carry their own source and stamp; one line cannot hold four facts honestly.
    for stage, sid, tickets in sessions:
        if stage != "verify" or not tickets:
            continue
        n = len(tickets)
        observed, _ = harvest(opts["transcripts"], [sid])
        out.append("RATIO verify_usd_per_ticket %s session %s = %.2f"
                   % ("batched" if n > 1 else "unbatched", sid.split("-")[0], observed / n))
        out.append("  numerator USD %.2f (%s @ %s)" % (observed, harvest_src % 1, stamp))
        out.append("  denominator %d ticket(s) (%s @ %s)" % (n, outcome_src, stamp))

    # FR5 -- what the sprint parked, and what its retro did with the buffer.
    parked = sum(e.get("findings_parked", 0) or 0
                 for e in events if e.get("event") == "outcome")
    out.append("FINDINGS parked %d (%s @ %s)" % (parked, outcome_src, stamp))
    retro = [e for e in events if e.get("event") == "outcome" and e.get("stage") == "retro"]
    if retro:
        consumed = sum(e.get("findings_consumed", 0) or 0 for e in retro)
        produced = sum(len(ticket_ids(e)) for e in retro)
        out.append("RETRO consumed %d produced %d (%s @ %s)"
                   % (consumed, produced, outcome_src, stamp))
    out.append("")

    block = "\n".join(out)
    with open(opts["ledger"], "a") as fh:
        fh.write(block if block.endswith("\n") else block + "\n")
    return block


# --- arguments ----------------------------------------------------------------------------------
def parse(argv):
    opts = {"ledger": None, "measurement": "MEASUREMENT.md", "config": None, "run": None,
            "transcripts": None, "tickets": 0, "develop_gates": 1, "verify_sessions": 1,
            "retro": False, "estimate_tickets": None, "estimate_wall": NO_PRIOR,
            "estimate_tokens": None, "estimate_usd": None, "estimate_source": None}
    ints = {"--tickets": "tickets", "--develop-gates": "develop_gates",
            "--verify-sessions": "verify_sessions", "--estimate-tickets": "estimate_tickets",
            "--estimate-tokens": "estimate_tokens"}
    strs = {"--ledger": "ledger", "--measurement": "measurement", "--config": "config",
            "--run": "run", "--transcripts": "transcripts", "--estimate-source": "estimate_source"}
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--retro":
            opts["retro"] = True
        elif a in ints or a in strs or a in ("--estimate-usd", "--estimate-wall"):
            i += 1
            if i >= len(argv):
                die("%s needs a value" % a)
            if a in ints:
                opts[ints[a]] = int(argv[i])
            elif a in strs:
                opts[strs[a]] = argv[i]
            elif a == "--estimate-usd":
                opts["estimate_usd"] = float(argv[i])
            else:
                opts["estimate_wall"] = (NO_PRIOR if argv[i] in ("no-prior", NO_PRIOR)
                                         else float(argv[i]))
        else:
            die("unknown argument: %s" % a)
        i += 1
    return opts


mode = sys.argv[2]
opts = parse(sys.argv[3:])
if not opts["ledger"]:
    die("--ledger is required")
if mode == "estimate":
    print(estimate(opts))
elif mode == "record":
    if not opts["run"] or not opts["transcripts"]:
        die("record needs --run and --transcripts")
    # FR8: every figure carries the source it was read from and the stamp it was true at. A default
    # cannot satisfy that and must not pretend to -- `--estimate-usd` defaulting to 0.0 appended a
    # committed `| usd | 0.00 | 16.00 | unsourced |`, a figure nobody estimated over a source that
    # is an admission of having none. AC1 is what settles REFUSE rather than LABEL: a record with no
    # estimate cannot hold "an estimate and an actual" for that figure, so there is nothing to
    # label. Validated before `record()` runs, so nothing is appended to a committed ledger first.
    #
    # `--estimate-wall` is absent from this list deliberately. Its default is NO_PRIOR, which is a
    # declaration that no prior exists -- the honest label AC2 requires -- rather than a figure.
    for flag, key in (("--estimate-tickets", "estimate_tickets"),
                      ("--estimate-tokens", "estimate_tokens"),
                      ("--estimate-usd", "estimate_usd"),
                      ("--estimate-source", "estimate_source")):
        if opts[key] is None:
            die("record needs %s: a figure nobody estimated is not an estimate, and a default "
                "would forge one" % flag)
    print(record(opts))
else:
    die("unknown mode: %s (expected estimate or record)" % mode)
PY
