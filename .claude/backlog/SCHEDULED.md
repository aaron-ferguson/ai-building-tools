# Scheduled — dormant tickets waiting on a date

Tickets here carry `status: scheduled` and a `wake:` date. **They hold no rank while dormant** —
that is the whole reason they live here rather than in `QUEUE.md`, where they would dilute a
stack rank with work nobody can start yet.

`next` prints a `DUE:` line only when something has woken. On waking, the ticket moves into
`QUEUE.md` and is ranked normally — arriving with a date attached, so the existing
"an external deadline promotes" rule does the work.

Most rows here are **outcome reviews**, created automatically when a project carrying a `measure`
rolls up closed. Their job is to read the metric, compare it to the target, and execute the branch
the project declared before the work started.

| ID | Title | Wake | Owner | Item |
|------|-------|------|-------|------|
| _(none yet)_ | | | | |
