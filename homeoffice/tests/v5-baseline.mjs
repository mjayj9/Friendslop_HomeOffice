import { chromium } from 'playwright';
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
const dir = process.env.V5_BASELINE_DIR || 'homeoffice/evidence/v5/baseline';
await fs.mkdir(dir, { recursive: true });
const base = process.env.V5_BASE_URL || 'https://mjayj9.github.io/Friendslop_HomeOffice/';
const report = { checkedAt: new Date().toISOString(), base, environment: 'New isolated Chromium on Windows; automated keyboard/mouse observation; no real account, microphone or third-party messages.' };
const manifest = await (await fetch(base + 'build-info.json')).json();
report.manifest = manifest;
report.artifacts = [];
for (const [path, expected] of Object.entries(process.env.V5_SKIP_HASH ? {} : manifest.files)) {
  const response = await fetch(base + path);
  const data = Buffer.from(await response.arrayBuffer());
  const sha256 = crypto.createHash('sha256').update(data).digest('hex');
  report.artifacts.push({ path, status: response.status, bytes: data.length, sha256, matches: data.length === expected.bytes && sha256 === expected.sha256 });
}
const browser = await chromium.launch({ headless: true, args: ['--use-angle=d3d11'] });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 }, recordVideo: { dir, size: { width: 1440, height: 900 } } });
report.errors = []; page.on('pageerror', e => report.errors.push(e.message));
const diag = () => page.evaluate(() => Homeoffice.diagnostics());
const actor = async () => { const d = await diag(); return d.currentState.players.find(a => a.id === d.id); };
async function key(k, ms) { await page.keyboard.down(k); await page.waitForTimeout(ms); await page.keyboard.up(k); await page.waitForTimeout(80); }
async function turn(yaw, pitch = 0) {
  for (let i = 0; i < 8; i++) { const a = await actor(), d = Math.atan2(Math.sin(yaw - (a.lookYaw ?? a.yaw)), Math.cos(yaw - (a.lookYaw ?? a.yaw))); if (Math.abs(d) < .03) break; await key(d > 0 ? 'ArrowLeft' : 'ArrowRight', Math.abs(d) / 1.5 * 1000); }
  for (let i = 0; i < 6; i++) { const d = pitch - (await actor()).pitch; if (Math.abs(d) < .03) break; await key(d > 0 ? 'ArrowUp' : 'ArrowDown', Math.abs(d) / 1.2 * 1000); }
}
async function move(x, z) {
  for (let i = 0; i < 16; i++) { const a = await actor(), dx = x - a.p[0], dz = z - a.p[2], n = Math.hypot(dx, dz); if (n < .3) return; await turn(Math.atan2(-dx, -dz)); await key('KeyW', Math.min(1300, Math.max(25, (n - .12) / 3.1 * 1000))); }
  throw Error('Walking blocked: ' + JSON.stringify({ target: [x, z], actor: await actor() }));
}
async function look(x, y, z) { const a = await actor(); await turn(Math.atan2(a.p[0] - x, a.p[2] - z), Math.atan2(y - a.p[1] - 1.62, Math.hypot(x - a.p[0], z - a.p[2]))); }
try {
  await page.goto(base + (process.env.V5_BASE_URL ? '?signal=local' : ''), { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.Homeoffice?.readyState(), null, { timeout: 120000 });
  await page.screenshot({ path: dir + '/01-entry.png' });
  await page.locator('#displayName').fill('V5 현장 조사'); await page.locator('#host').click();
  await page.waitForFunction(() => Homeoffice.diagnostics().playing && Homeoffice.diagnostics().currentState?.players.length === 1, null, { timeout: 60000 });
  report.initial = await diag(); await page.screenshot({ path: dir + '/02-arrival.png' });
  await key('KeyC', 50);
  await move(-.4, 10.95); await move(-6, 10.95); await move(-8.8, 10.95); await move(-8.8, 7.8);
  await look(-10.4, .25, 6.3); await page.screenshot({ path: dir + '/03-living-low-table.png' });
  report.living = await diag();
  await move(-8.8, 3.8); await move(-6.7, 3.8); await move(-6.7, .1); await look(-10, .3, 0);
  await page.screenshot({ path: dir + '/04-dining-table.png' }); report.dining = await diag();
  report.completed = true;
} catch (e) { report.failure = e.stack; await page.screenshot({ path: dir + '/failure.png' }).catch(() => {}); report.last = await diag().catch(() => null); }
finally { report.video = await page.video().path(); await browser.close(); await fs.writeFile(dir + '/report.json', JSON.stringify(report, null, 2)); console.log(JSON.stringify({ buildId: manifest.buildId, verified: report.artifacts.filter(x => x.matches).length, files: report.artifacts.length, completed: report.completed, failure: report.failure, path: dir })); }
