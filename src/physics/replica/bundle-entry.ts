// Bundle entry — exposes the UNCHANGED NapeReplica on the global scope so the
// Haxe game (compiled to JS) can construct it through a JS extern. Built with
// esbuild to haxe-port/.../nape-replica.js. This file does NOT modify nape-core.ts;
// the bit-exact engine ships verbatim.
import { NapeReplica } from './nape-core';

(globalThis as unknown as { NapeReplica: typeof NapeReplica }).NapeReplica = NapeReplica;
