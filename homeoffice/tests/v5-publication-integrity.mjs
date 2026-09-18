import fs from 'node:fs/promises';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';

const base = process.env.V5_BASE_URL || 'https://mjayj9.github.io/Friendslop_HomeOffice/';
const expectedBuild = process.env.V5_EXPECTED_BUILD;
assert.ok(expectedBuild, 'Set V5_EXPECTED_BUILD to the reviewed artifact ID');
const dir = process.env.V5_PUBLICATION_DIR || 'homeoffice/evidence/v5/publication';
await fs.mkdir(dir, { recursive: true });
const report = { base, expectedBuild, startedAt: new Date().toISOString(), files: [], completed: false };
try {
  const response = await fetch(new URL('build-info.json', base), { cache: 'no-store' });
  assert.equal(response.status, 200);
  const manifest = await response.json();
  report.manifest = manifest;
  assert.equal(manifest.buildId, expectedBuild, 'Public manifest must be the reviewed build');
  assert.equal(manifest.protocolVersion, 4);
  const entries = Object.entries(manifest.files);
  let cursor = 0;
  await Promise.all(Array.from({ length: 4 }, async () => {
    while (cursor < entries.length) {
      const [path, expected] = entries[cursor++];
      assert.ok(!path.startsWith('/') && !path.split('/').includes('..'));
      const res = await fetch(new URL(path, base), { cache: 'no-store' });
      const data = Buffer.from(await res.arrayBuffer());
      const sha256 = crypto.createHash('sha256').update(data).digest('hex');
      report.files.push({ path, status: res.status, bytes: data.length, sha256,
        matches: res.status === 200 && data.length === expected.bytes && sha256 === expected.sha256 });
    }
  }));
  report.files.sort((a, b) => a.path.localeCompare(b.path));
  assert.equal(report.files.length, entries.length);
  assert.deepEqual(report.files.filter(f => !f.matches), []);
  report.completed = true;
} catch (error) {
  report.failure = error.stack;
  process.exitCode = 1;
} finally {
  report.finishedAt = new Date().toISOString();
  await fs.writeFile(`${dir}/integrity.json`, JSON.stringify(report, null, 2));
  console.log(JSON.stringify({ completed: report.completed, buildId: report.manifest?.buildId,
    verified: report.files.filter(f => f.matches).length, files: report.files.length, failure: report.failure }));
}
