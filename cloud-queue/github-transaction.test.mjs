import test from 'node:test';
import assert from 'node:assert/strict';
import { commitBacklog } from './github-transaction.mjs';

test('rejects non-backlog files before any network access', async () => {
  await assert.rejects(
    commitBacklog({ owner: 'example', repo: 'repo', token: 'unused',
      snapshot: { head: 'a', treeSha: 'b' },
      files: { 'src/index.js': 'oops' }, message: 'bad' }),
    /Invalid backlog path/
  );
});
test('rejects path traversal before any network access', async () => {
  await assert.rejects(
    commitBacklog({ owner: 'example', repo: 'repo', token: 'unused',
      snapshot: { head: 'a', treeSha: 'b' },
      files: { '.tickets/../README.md': 'oops' }, message: 'bad' }),
    /Invalid backlog path/
  );
});
test('requires a pinned snapshot', async () => {
  await assert.rejects(
    commitBacklog({ owner: 'example', repo: 'repo', token: 'unused',
      files: { '.tickets/QUEUE.md': 'x' }, message: 'bad' }),
    /Pinned snapshot/
  );
});
