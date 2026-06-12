#!/bin/zsh
# Convert original WAV sfx + music to ogg (+ m4a fallback for Safari).
set -e
SRC=/Users/jonscott/Projects/SoccerBalls2
OUT="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$OUT/public/assets/audio/sfx" "$OUT/public/assets/audio/music"

for f in "$SRC"/Sound/*.wav; do
  name="$(basename "$f" .wav)"
  ffmpeg -y -loglevel error -i "$f" -c:a libvorbis -q:a 4 "$OUT/public/assets/audio/sfx/$name.ogg"
  ffmpeg -y -loglevel error -i "$f" -c:a aac -b:a 96k "$OUT/public/assets/audio/sfx/$name.m4a"
done

for f in "$SRC"/Music/*.wav; do
  name="$(basename "$f" .wav)"
  ffmpeg -y -loglevel error -i "$f" -c:a libvorbis -q:a 5 "$OUT/public/assets/audio/music/$name.ogg"
  ffmpeg -y -loglevel error -i "$f" -c:a aac -b:a 128k "$OUT/public/assets/audio/music/$name.m4a"
done

echo "sfx: $(ls "$OUT/public/assets/audio/sfx" | wc -l | tr -d ' ') files, music: $(ls "$OUT/public/assets/audio/music" | wc -l | tr -d ' ') files"
