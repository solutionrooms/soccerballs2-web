#!/usr/bin/env bash
# Fast typecheck of the converted game using lime's generated hxml, skipping JS
# output. Run from anywhere; prints Haxe errors. Regenerate the hxml with
# `haxelib run lime build html5` if project.xml changes.
cd "$(dirname "$0")/.."
exec haxe bin/html5/haxe/release.hxml --no-output 2>&1
