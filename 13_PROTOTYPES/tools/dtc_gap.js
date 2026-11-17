'use strict';
/** Membandingkan katalog DTC FLASHPRO (CSV) dengan database RevCore (Kotlin). */
const fs = require('fs');
const path = require('path');

function parseCsvLine(line) {
  const out = [];
  let cur = '';
  let q = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (q) {
      if (c === '"' && line[i + 1] === '"') { cur += '"'; i++; }
      else if (c === '"') q = false;
      else cur += c;
    } else if (c === '"') q = true;
    else if (c === ',') { out.push(cur); cur = ''; }
    else cur += c;
  }
  out.push(cur);
  return out;
}

function loadFlashpro(csvPath) {
  const lines = fs.readFileSync(csvPath, 'utf8').replace(/^\uFEFF/, '').split(/\r?\n/).filter(Boolean);
  return lines.slice(1).map((l) => {
    const [code, description] = parseCsvLine(l);
    return { code, description };
  });
}

function loadRevCore(ktPath) {
  const src = fs.readFileSync(ktPath, 'utf8');
  const out = [];
  const re = /HondaDtc\((\d+),\s*(\d+),\s*"(P[0-9A-F]{4})"/g;
  let m;
  while ((m = re.exec(src)) !== null) out.push({ code: `${m[1]}-${m[2]}`, pcode: m[3] });
  return out;
}

function main() {
  const root = path.resolve(__dirname, '..', '..');
  const fpCsv = path.join(root, '05_ECU_IDENTIFICATION', 'extract', 'DTC_CODES.csv');
  const rcKt = path.join(root, '..', 'Qoder', 'work', 'revcore', 'app', 'src', 'main', 'java', 'com', 'revcore', 'android', 'core', 'protocol', 'HondaDtcDatabase.kt');
  const fp = loadFlashpro(fpCsv);
  const rc = loadRevCore(rcKt);
  const rcSet = new Set(rc.map((x) => x.code));
  const fpSet = new Set(fp.map((x) => x.code));
  const missing = fp.filter((x) => !rcSet.has(x.code));
  const extra = rc.filter((x) => !fpSet.has(x.code));
  const out = [];
  out.push(`flashpro=${fp.length} revcore=${rc.length} missing_in_revcore=${missing.length} extra_in_revcore=${extra.length}`);
  out.push('code,flashpro_description,revcore_pcode');
  for (const m of missing) out.push(`${m.code},"${m.description.replace(/"/g, '""')}",`);
  out.push('');
  out.push('--- extra_in_revcore ---');
  for (const e of extra) out.push(`${e.code},${e.pcode}`);
  return out.join('\n');
}

if (require.main === module) {
  process.stdout.write(main() + '\n');
}

module.exports = { loadFlashpro, loadRevCore, main };
