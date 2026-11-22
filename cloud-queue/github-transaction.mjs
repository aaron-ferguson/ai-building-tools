/**
 * GitHub Git Data API adapter for atomic backlog-only commits.
 * No dependencies; compatible with Node 20+.
 */
const API = 'https://api.github.com';
export class HeadMovedError extends Error {
  constructor(message = 'Branch changed; refresh and rebuild the entire backlog transaction') {
    super(message); this.name = 'HeadMovedError';
  }
}
async function request(token, method, path, body) {
  const response = await fetch(API + path, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'Content-Type': 'application/json'
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) })
  });
  const value = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(`GitHub ${method} ${path}: HTTP ${response.status}: ${value.message || 'unknown error'}`);
    error.status = response.status;
    throw error;
  }
  return value;
}
function repoPath(owner, repo) {
  if (!/^[A-Za-z0-9_.-]+$/.test(owner) || !/^[A-Za-z0-9_.-]+$/.test(repo)) throw new Error('Invalid repository');
  return `/repos/${owner}/${repo}`;
}
function validateFiles(files) {
  if (!files || !Object.keys(files).length) throw new Error('No backlog changes');
  for (const [path, content] of Object.entries(files)) {
    if (!path.startsWith('.tickets/') || path.includes('..') || path.endsWith('/') ||
        typeof content !== 'string') throw new Error(`Invalid backlog path or content: ${path}`);
  }
}
export async function readSnapshot({ owner, repo, branch = 'main', token }) {
  const base = repoPath(owner, repo);
  const ref = await request(token, 'GET', `${base}/git/ref/heads/${encodeURIComponent(branch)}`);
  const head = ref.object.sha;
  const commit = await request(token, 'GET', `${base}/git/commits/${head}`);
  const tree = await request(token, 'GET', `${base}/git/trees/${commit.tree.sha}?recursive=1`);
  if (tree.truncated) throw new Error('GitHub tree truncated; refuse unsafe ID allocation');
  return { head, treeSha: commit.tree.sha, paths: tree.tree.map(e => e.path), entries: tree.tree };
}
export async function readText({ owner, repo, token, snapshot, path }) {
  const entry = snapshot.entries.find(e => e.path === path && e.type === 'blob');
  if (!entry) throw new Error(`File not found in pinned snapshot: ${path}`);
  const blob = await request(token, 'GET', `${repoPath(owner, repo)}/git/blobs/${entry.sha}`);
  if (blob.encoding !== 'base64') throw new Error('Unsupported blob encoding');
  return Buffer.from(blob.content.replace(/\s/g, ''), 'base64').toString('utf8');
}
export async function commitBacklog({ owner, repo, branch = 'main', token, snapshot, files, message }) {
  validateFiles(files);
  if (!snapshot?.head || !snapshot?.treeSha || !message) throw new Error('Pinned snapshot and message required');
  const base = repoPath(owner, repo);
  // Fail early if a different writer already advanced the branch.
  const latest = await request(token, 'GET', `${base}/git/ref/heads/${encodeURIComponent(branch)}`);
  if (latest.object.sha !== snapshot.head) throw new HeadMovedError();
  const blobs = await Promise.all(Object.entries(files).map(async ([path, content]) => {
    const blob = await request(token, 'POST', `${base}/git/blobs`, { content, encoding: 'utf-8' });
    return { path, mode: '100644', type: 'blob', sha: blob.sha };
  }));
  const tree = await request(token, 'POST', `${base}/git/trees`, {
    base_tree: snapshot.treeSha, tree: blobs
  });
  const commit = await request(token, 'POST', `${base}/git/commits`, {
    message, tree: tree.sha, parents: [snapshot.head]
  });
  try {
    // Non-forced update only accepts fast-forwards. A concurrent sibling commit
    // is not a descendant of the new commit, so GitHub rejects it.
    await request(token, 'PATCH', `${base}/git/refs/heads/${encodeURIComponent(branch)}`, {
      sha: commit.sha, force: false
    });
  } catch (error) {
    if ([409, 422].includes(error.status)) throw new HeadMovedError();
    throw error;
  }
  return { sha: commit.sha, url: `https://github.com/${owner}/${repo}/commit/${commit.sha}` };
}
