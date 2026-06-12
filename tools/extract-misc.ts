// VarsData.xml + TextStrings.xml + Achievements.xml -> vars/strings/achievements JSON.
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { parseXml, childrenOf, firstChild, attrStr, attrNum, attrInt } from './xml.ts';

const SRC = '/Users/jonscott/Projects/SoccerBalls2';
const OUT = join(import.meta.dirname, '..');

// ---- vars (balance constants) ----
{
  const xml = parseXml(readFileSync(join(SRC, 'bin/VarsData.xml'), 'utf8'));
  const vars: Record<string, number | string> = {};
  for (const v of childrenOf(xml, 'variable')) {
    const name = attrStr(v, 'name');
    vars[name] = attrStr(v, 'type') === 'number' ? attrNum(v, 'value') : attrStr(v, 'value');
  }
  writeFileSync(join(OUT, 'src/data/vars.json'), JSON.stringify(vars, null, 1));
  console.log(`vars: ${Object.keys(vars).length} variables`);
}

// ---- strings (English; en="" means the key itself is the English text) ----
{
  const xml = parseXml(readFileSync(join(SRC, 'bin/TextStrings.xml'), 'utf8'));
  const strings: Record<string, string> = {};
  for (const t of childrenOf(xml, 'textstring')) {
    const name = attrStr(t, 'name');
    if (!name) continue;
    strings[name] = attrStr(t, 'en') || name;
  }
  writeFileSync(join(OUT, 'src/data/strings.json'), JSON.stringify(strings, null, 1));
  console.log(`strings: ${Object.keys(strings).length} entries`);
}

// ---- achievements ----
{
  const xml = parseXml(readFileSync(join(SRC, 'bin/Achievements.xml'), 'utf8'));
  const achievements = childrenOf(xml, 'achievement').map((a) => ({
    name: attrStr(a, 'name'),
    desc: attrStr(a, 'desc'),
    toUnlock: attrStr(a, 'tounlock'),
    specificLevel: attrInt(a, 'specificlevel', 0),
    testFunc: attrStr(firstChild(a, 'test')!, 'func'),
    passFunc: attrStr(firstChild(a, 'pass')!, 'func'),
  }));
  writeFileSync(join(OUT, 'src/data/achievements.json'), JSON.stringify(achievements, null, 1));
  console.log(`achievements: ${achievements.length} entries`);
}
