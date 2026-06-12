#!/bin/zsh
# Convert SWF-exported sounds (ffdec dump in /tmp/sb2-sounds, filenames
# <charId>_<class>_<class>.<ext>) for any sound class with no lossless WAV
# original in the repo. WAV-sourced conversions from convert-audio.sh win.
set -e
SRC=/Users/jonscott/Projects/SoccerBalls2
DUMP=/tmp/sb2-sounds
OUT="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$OUT/public/assets/audio/sfx" "$OUT/public/assets/audio/music"

for f in "$DUMP"/*; do
  base="$(basename "$f")"
  ext="${base##*.}"
  noext="${base%.*}"
  rest="${noext#*_}"            # strip charId
  name="${rest:0:$(( ${#rest} / 2 ))}"   # name is duplicated: x_x
  name="${name%_}"
  case "$name" in
    music_*|menus_music|kazoo) dir=music ;;
    *) dir=sfx ;;
  esac
  if [[ "$dir" == "sfx" && -f "$SRC/Sound/$name.wav" ]]; then
    continue  # lossless original already converted
  fi
  ffmpeg -y -loglevel error -i "$f" -c:a libvorbis -q:a 5 "$OUT/public/assets/audio/$dir/$name.ogg"
  ffmpeg -y -loglevel error -i "$f" -c:a aac -b:a 128k "$OUT/public/assets/audio/$dir/$name.m4a"
  echo "converted from swf: $dir/$name"
done
