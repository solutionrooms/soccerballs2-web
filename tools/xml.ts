// Minimal XML parser for the machine-generated SoccerBalls2 data files.
// Handles elements, attributes, comments, and self-closing tags. No entities
// beyond the basic five, no CDATA (the source files use neither).

export interface XmlNode {
  tag: string;
  attrs: Record<string, string>;
  children: XmlNode[];
}

const ENTITIES: Record<string, string> = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&apos;': "'",
};

function decode(s: string): string {
  return s.replace(/&(amp|lt|gt|quot|apos);/g, (m) => ENTITIES[m]);
}

export function parseXml(src: string): XmlNode {
  let i = 0;
  const root: XmlNode = { tag: '#root', attrs: {}, children: [] };
  const stack: XmlNode[] = [root];

  while (i < src.length) {
    const lt = src.indexOf('<', i);
    if (lt < 0) break;
    if (src.startsWith('<!--', lt)) {
      i = src.indexOf('-->', lt) + 3;
      continue;
    }
    if (src.startsWith('<?', lt)) {
      i = src.indexOf('?>', lt) + 2;
      continue;
    }
    if (src[lt + 1] === '/') {
      const gt = src.indexOf('>', lt);
      stack.pop();
      i = gt + 1;
      continue;
    }
    const gt = findTagEnd(src, lt);
    const inner = src.slice(lt + 1, gt);
    const selfClose = inner.endsWith('/');
    const body = selfClose ? inner.slice(0, -1) : inner;
    const node = parseTag(body);
    stack[stack.length - 1].children.push(node);
    if (!selfClose) stack.push(node);
    i = gt + 1;
  }
  if (root.children.length !== 1) {
    throw new Error(`expected single root element, got ${root.children.length}`);
  }
  return root.children[0];
}

// '>' may legally appear inside quoted attribute values.
function findTagEnd(src: string, start: number): number {
  let inQuote = false;
  for (let i = start; i < src.length; i++) {
    const c = src[i];
    if (c === '"') inQuote = !inQuote;
    else if (c === '>' && !inQuote) return i;
  }
  throw new Error('unterminated tag at ' + start);
}

function parseTag(body: string): XmlNode {
  const m = body.match(/^\s*([\w:-]+)/);
  if (!m) throw new Error('bad tag: ' + body.slice(0, 60));
  const node: XmlNode = { tag: m[1], attrs: {}, children: [] };
  const attrRe = /([\w:-]+)\s*=\s*"([^"]*)"/g;
  attrRe.lastIndex = m[0].length;
  let a: RegExpExecArray | null;
  while ((a = attrRe.exec(body))) {
    node.attrs[a[1]] = decode(a[2]);
  }
  return node;
}

export function childrenOf(node: XmlNode, tag: string): XmlNode[] {
  return node.children.filter((c) => c.tag === tag);
}

export function firstChild(node: XmlNode, tag: string): XmlNode | undefined {
  return node.children.find((c) => c.tag === tag);
}

export function attrStr(node: XmlNode, name: string, def = ''): string {
  const v = node.attrs[name];
  return v === undefined || v === '' ? def : v;
}

export function attrNum(node: XmlNode, name: string, def = 0): number {
  const v = node.attrs[name];
  if (v === undefined || v === '') return def;
  const n = Number(v);
  return Number.isNaN(n) ? def : n;
}

export function attrInt(node: XmlNode, name: string, def = 0): number {
  return Math.trunc(attrNum(node, name, def));
}

export function attrBool(node: XmlNode, name: string, def = false): boolean {
  const v = node.attrs[name];
  if (v === undefined || v === '') return def;
  return v === 'true' || v === '1';
}

// "1,2, 3,4" -> [1,2,3,4]  (mirrors Utils.PointArrayFromString flattened)
export function numList(s: string): number[] {
  if (!s.trim()) return [];
  return s.split(',').map((p) => Number(p.trim()));
}

// "a=1,b=two,c=" -> {a:"1", b:"two", c:""} (mirrors ObjParameters.ValuesFromString)
export function paramMap(s: string): Record<string, string> {
  const out: Record<string, string> = {};
  if (!s.trim()) return out;
  for (const pair of s.split(',')) {
    const eq = pair.indexOf('=');
    if (eq < 0) continue;
    out[pair.slice(0, eq).trim()] = pair.slice(eq + 1).trim();
  }
  return out;
}
