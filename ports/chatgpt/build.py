"""Build a self-contained ChatGPT queue skill from this checkout."""
import argparse
from hashlib import sha256
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

ROOT = Path(__file__).resolve().parents[2]
QUEUE = ROOT / "skills/queue"
NAME = "ai-building-queue"
PREFLIGHT = """## Before any backlog write

Use the target project's Git root. Paths to references and templates in this skill
start at the installed skill directory. Ensure the target checkout is writable.
Resolve conventions before scaffolding, syncing templates, or changing a ticket.
"""


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError(f"Upstream adapter anchor changed: {old!r}")
    return text.replace(old, new)


def package_files():
    workflow = (QUEUE / "SKILL.md").read_text()
    _, _, body = workflow.split("---\n", 2)
    body = replace_once(body, "# /queue", "# Queue engineering work\n\n" + PREFLIGHT)
    body = body.replace("plugin root", "skill directory")
    body = replace_once(body, "project's `CLAUDE.md` profile", "project's instruction profile")
    header = (
        "---\nname: ai-building-queue\n"
        "description: Capture, rank, inspect, and maintain engineering tickets in a "
        "project's .tickets backlog using its ai-building-conventions checkout. "
        "Use when asked to queue engineering work or manage the project backlog.\n---\n"
    )
    reference = (ROOT / "references/CONVENTIONS.md").read_text()
    start = "**2. The project's"
    end = "## Routing a finding"
    if reference.count(start) != 1 or reference.count(end) != 1:
        raise ValueError("Upstream conventions headings changed")
    before, rest = reference.split(start)
    adapted, routing = rest.split(end)
    # The adapter replaces these paragraphs. Force a review if upstream edits them.
    digest = sha256((start + adapted).encode()).hexdigest()
    if digest != "5d07c82f468bf6558ab3767c35a4c18129d1d11f40e48552d53aa7c142a922ea":
        raise ValueError("Review the changed upstream conventions resolver before packaging")
    before = replace_once(before, "Stop at the first\none that resolves to a directory containing `CONVENTIONS_CORE.md`.",
                          "Select the first valid core and report inconsistent pointers as described below.")
    reference = before + Path(__file__).with_name("resolution.md").read_text() + "\n" + end + routing
    yield f"{NAME}/SKILL.md", (header + body).encode(), 0o644
    yield f"{NAME}/references/CONVENTIONS.md", reference.encode(), 0o644
    for folder in (QUEUE / "templates", ROOT / "references"):
        for path in sorted(folder.iterdir()):
            if path.is_file() and path != ROOT / "references/CONVENTIONS.md":
                yield f"{NAME}/{folder.name}/{path.name}", path.read_bytes(), path.stat().st_mode & 0o777


STAGES = ("design", "prototype", "develop", "verify", "retro")


def replace_section(text, start, end, replacement):
    if text.count(start) != 1 or text.count(end) != 1:
        raise ValueError(f"Review changed section: {start}")
    before, section = text.split(start)
    _, after = section.split(end)
    return before + replacement + end + after


def stage_workflow(stage):
    source = ROOT / "skills" / stage / "SKILL.md"
    text = replace_once(source.read_text(), f"name: {stage}\n", f"name: ai-building-{stage}\n")
    header, body = text.split("\n---\n", 1)
    host = (
        "Work in the target project's writable checkout. Resolve bundled paths relative "
        "to this skill directory. Read applicable project instructions, including AGENTS.md "
        "and existing CLAUDE.md. Follow references/CONVENTIONS.md for conventions lookup. "
        "Use a fresh session for each stage. Stage names in ticket fields and handoffs stay "
        "unprefixed; ask for the corresponding ai-building skill in the next session.\n"
    )
    body = body.replace("at the plugin root", "in this skill directory")
    body = body.replace("the project's `CLAUDE.md`", "the project's instructions")
    if stage == "verify":
        body = replace_section(body, "Skills run from the pinned install", "The `qa_level`",
                               "Record the installed plugin version and the source revision under test. "
                               "Verify installed behavior in a fresh session after publishing.\n\n")
    if stage == "retro":
        body = replace_section(body, "- **A skill edit has a release chain", "## Step 6",
                               "- For a ChatGPT skill change, edit the source checkout, rebuild the port, "
                               "and run ports/chatgpt/test_package.py. Obtain authorization to publish "
                               "the branch and update the private plugin. Report any pending release "
                               "or fresh-session verification.\n\n---\n\n")
        body = body.split("**When Step 5 ran")[0].rstrip() + " Report pending publication or verification here.\n"
    return header + "\n---\n\n" + host + body


def plugin_files():
    queue = list(package_files())
    yield from queue
    for stage in STAGES:
        name = f"ai-building-{stage}"
        yield f"{name}/SKILL.md", stage_workflow(stage).encode(), 0o644
        for path, data, mode in queue:
            relative = path.split("/", 1)[1]
            if relative.startswith("references/") or relative == "templates/item.md":
                yield f"{name}/{relative}", data, mode
        if stage == "prototype":
            asset = ROOT / "skills/prototype/assets/prototype-template.html"
            yield f"{name}/assets/{asset.name}", asset.read_bytes(), 0o644


def build(output):
    with ZipFile(output, "x") as archive:
        for name, data, mode in package_files():
            info = ZipInfo(name)
            info.external_attr = (0o100000 | mode) << 16
            archive.writestr(info, data, compress_type=ZIP_DEFLATED)


def refresh_plugin():
    skills = Path(__file__).parent / "plugins/ai-building-tools/skills"
    for name, data, mode in plugin_files():
        dest = skills / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        dest.chmod(mode)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("output", nargs="?", type=Path, help="new ZIP file to create")
    target.add_argument("--refresh-plugin", action="store_true", help="refresh the checked-in skill")
    args = parser.parse_args()
    if args.refresh_plugin:
        refresh_plugin()
    else:
        build(args.output)
