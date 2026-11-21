# Queue for ChatGPT Work

From the tools checkout, build a skill archive at a new path:

    python3 ports/chatgpt/build.py /tmp/ai-building-queue.zip

Install the ZIP as a skill in ChatGPT Work. Start a fresh chat with a writable
project checkout and a readable conventions checkout. In the project's
AGENTS.md or CLAUDE.md, a sibling conventions checkout can be wired with:

    ## Conventions
    @../ai-building-conventions/CONVENTIONS_CORE.md

Existing projects can use conventions.path in .tickets/config.yml.
Invoke ai-building-queue and ask it to queue a specific engineering change.
Check the item, its convention citations and its position in .tickets/QUEUE.md.
Repeat in an unwired disposable project and verify it stops without creating
.tickets/. The generated ZIP contains queue only. Open a new session for
each subsequent stage using the existing harness.
