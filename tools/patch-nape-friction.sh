#!/bin/bash
# Make nape-haxe4 2.0.22 match the original 2012 Nape's friction behaviour: skip Coulomb friction on
# contacts that have a real restitution BOUNCE (fast impacts) — so the ball slips off walls (no
# friction, full climb, no spin) but still grips/rolls on the ground (resting contacts have bounce==0).
# Reproduces the original feel (e.g. level 9 shots reaching the receiving player). Idempotent.
set -e
NAPE=$(haxelib path nape-haxe4 2>/dev/null | head -1)
ARB="$NAPE/zpp_nape/dynamics/Arbiter.hx"
[ -f "$ARB" ] || { echo "nape-friction patch: Arbiter.hx not found"; exit 1; }
if grep -q "bounce!=0)jMax=0" "$ARB"; then echo "nape-friction patch: already applied"; exit 0; fi
perl -i -pe 's/\QjMax=c1.friction*c1.jnAcc;\E/jMax=c1.friction*c1.jnAcc;if(c1.bounce!=0)jMax=0;\/*SB2 patch: 2012-Nape no-friction-on-bounce*\//' "$ARB"
perl -i -pe 's/\QjMax=c2.friction*c2.jnAcc;\E/jMax=c2.friction*c2.jnAcc;if(c2.bounce!=0)jMax=0;\/*SB2 patch*\//' "$ARB"
grep -q "bounce!=0)jMax=0" "$ARB" && echo "nape-friction patch: applied" || { echo "nape-friction patch: FAILED"; exit 1; }
