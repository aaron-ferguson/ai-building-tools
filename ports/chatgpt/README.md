# AI Building Tools for ChatGPT Work

This marketplace ships six manual workflows: queue, design, prototype, develop, verify, and retro. A workspace admin can import it
directly from GitHub in Admin Console → Plugins → Add → Import marketplace.

| Field | Value |
| --- | --- |
| Source | https://github.com/aaron-ferguson/ai-building-tools |
| Path | `ports/chatgpt` |
| Branch | `chatgpt/queue-port` for the pilot. Use `main` after merge. |

Review the import result and set AI Building Tools to Installed for the test
role, or make it Available and install it from the workspace directory.
Open a new Work chat with a writable project checkout and a readable
ai-building-conventions checkout. An existing project can set conventions.path
in .tickets/config.yml. For a new project with sibling checkouts, put this in
the project root's AGENTS.md or CLAUDE.md:

    ## Conventions
    @../ai-building-conventions/CONVENTIONS_CORE.md

Ask the fresh chat to queue an engineering change. Verify that the
ai-building-queue skill ran, then inspect the ticket, its convention citation,
and its position in .tickets/QUEUE.md. In a second, unwired disposable project,
verify that queue stops before creating .tickets/.

## Cloud sprint

Ask Work to coordinate a sprint with fresh subagent sessions. Specify the repository, branch, ticket scope and stopping limits. The coordinator uses a writable cloud checkout and the existing backlog scripts. Grant publication permission when the resulting commits should go to GitHub.

## Maintaining the package

Work imports the committed plugin directory directly. After changing the
source queue workflow, templates, references, or adapter, run these commands
from the repository root and commit the updated package alongside the change:

    python3 ports/chatgpt/build.py --refresh-plugin
    python3 ports/chatgpt/test_package.py

The test compares all six packaged skills with a fresh build, including
executable permissions. Remove obsolete generated files identified by the test.
To build a standalone queue skill ZIP, pass a new output filename to build.py.
