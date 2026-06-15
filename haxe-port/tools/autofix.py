#!/usr/bin/env python3
# Compiler-driven fixer for AS3 numeric/string coercions Haxe rejects but AS3 did
# implicitly. Parses Haxe's exact error spans (1-based columns) and wraps the
# offending expression in the faithful coercion:
#   Float should be Int    -> Std.int(x)               (AS3 ToInt32 truncation)
#   String should be Float -> as3hx.Compat.parseFloat(x)
#   String should be Int   -> as3hx.Compat.parseInt(x)
# For assignment/declaration spans it wraps only the RHS. Iterates until stable.
# Deterministic given the converted source, so it's a reproducible pipeline step
# (run after promote.sh). Re-running on already-fixed code is a no-op.
import subprocess, re, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

WRAP = {
    'Float should be Int': lambda x: 'Std.int(%s)' % x,
    'String should be Float': lambda x: 'as3hx.Compat.parseFloat(%s)' % x,
    'String should be Int': lambda x: 'as3hx.Compat.parseInt(%s)' % x,
}
ERR = re.compile(r'(src/\S+\.hx):(\d+): characters (\d+)-(\d+) : (' +
                 '|'.join(re.escape(k) for k in WRAP) + r')$')


def errors():
    r = subprocess.run(['haxe', 'bin/html5/haxe/release.hxml', '--no-output'],
                       capture_output=True, text=True)
    es = []
    for line in (r.stdout + r.stderr).splitlines():
        m = ERR.match(line.strip())
        if m:
            es.append((m.group(1), int(m.group(2)), int(m.group(3)),
                       int(m.group(4)), m.group(5)))
    return es


def find_assign(s):
    # index of a plain assignment '=' (not ==, <=, >=, !=, +=, etc.), else None
    for i, c in enumerate(s):
        if c == '=':
            prev = s[i - 1] if i > 0 else ' '
            nxt = s[i + 1] if i + 1 < len(s) else ' '
            if prev not in '=<>!+-*/%&|^' and nxt != '=':
                return i
    return None


COMPOUND = re.compile(r'^(.+?)\s*([/%*+\-])=\s*(.+)$')


def fix_line(text, a, b, kind):
    """Return modified text, or None if this span can't be safely auto-fixed."""
    span = text[a:b]
    core = span.rstrip()
    trail = span[len(core):]
    semi = ''
    if core.endswith(';'):
        core, semi = core[:-1], ';'
    cs = core.lstrip()
    indent = core[:len(core) - len(cs)]
    # idempotency: already wrapped -> unfixable by re-wrapping
    if cs.startswith('Std.int(') or cs.startswith('as3hx.Compat.parse'):
        return None
    # return EXPR -> return WRAP(EXPR)
    prefix = ''
    if cs.startswith('return '):
        prefix, cs = indent + 'return ', cs[len('return '):]
        indent = ''
    # compound assignment  lvalue OP= rhs  ->  lvalue = WRAP(lvalue OP rhs)
    m = COMPOUND.match(cs)
    if m and find_assign(cs) is None:
        lv, op, rhs = m.group(1).strip(), m.group(2), m.group(3).strip()
        return text[:a] + prefix + indent + '%s = %s' % (lv, WRAP[kind]('%s %s %s' % (lv, op, rhs))) + semi + trail + text[b:]
    # plain assignment/declaration -> wrap only the RHS
    eq = find_assign(cs)
    if eq is not None:
        new = prefix + indent + cs[:eq + 1] + ' ' + WRAP[kind](cs[eq + 1:].strip()) + semi
    else:
        new = prefix + indent + WRAP[kind](cs.strip()) + semi
    return text[:a] + new + trail + text[b:]


total, skipped = 0, set()
for it in range(60):
    es = [e for e in errors() if (e[0], e[1]) not in skipped]
    if not es:
        break
    seen, batch = set(), []
    for f, ln, s, e, k in es:          # one (leftmost) per line per pass
        if (f, ln) in seen:
            continue
        seen.add((f, ln))
        batch.append((f, ln, s, e, k))
    progressed = 0
    for f, ln, s, e, k in batch:
        lines = open(f).read().split('\n')
        new = fix_line(lines[ln - 1], s - 1, e - 1, k)
        if new is None:
            skipped.add((f, ln))
            continue
        lines[ln - 1] = new
        open(f, 'w').write('\n'.join(lines))
        progressed += 1
    total += progressed
    print('autofix iter %d: wrapped %d span(s)' % (it, progressed))
    if progressed == 0:
        break
print('autofix: %d wrapped, %d span(s) left for manual fix' % (total, len(skipped)))
for f, ln in sorted(skipped):
    print('  manual:', f, ln)
