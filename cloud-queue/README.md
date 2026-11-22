# ChatGPT cloud queue adapter (experimental)

This adapter lets a ChatGPT session commit native `.tickets/` changes through GitHub's Git Data API without a local checkout.

## Safety contract

1. Read the target branch head, recursive tree, queue, configuration, item template, and conventions before preparing changes.
2. Validate the ticket against the queue skill's full contract. This adapter **does not generate ticket specifications**.
3. Mint IDs from all `.tickets/items/` paths in the tree, never just `next_id`.
4. Compute `ac_digest` with the repository's canonical `.tickets/next --ac-digest` algorithm. Do not guess it.
5. Submit all changed backlog files in **one Git tree and commit** with the observed head as parent.
6. Advance the branch only if it is still at the observed head. On conflict, discard the candidate and re-read/re-rank/revalidate.
7. Never create a GitHub issue as a substitute for a native backlog item.

The API implementation in `github-transaction.mjs` handles steps 1, 5 and 6. The skill must handle steps 2–4 and the conflict retry. **Do not enable ticket creation until canonical digest computation and validation are wired.**

## Authentication

Provide a short-lived, least-privilege GitHub token with Contents: Read and write to the target repository. Never place tokens in prompts, tickets, logs or commits.

## Usage

```js
import { readSnapshot, commitBacklog } from './github-transaction.mjs';
const snapshot = await readSnapshot({ owner, repo, branch, token });
const result = await commitBacklog({
  owner, repo, branch, token, snapshot,
  files: { '.tickets/QUEUE.md': queueText, '.tickets/config.yml': configText,
           '.tickets/items/0239-example.md': itemText },
  message: 'Capture 0239: example'
});
```

The caller must pass a complete validated change set. This API does not rank, allocate or validate tickets.
