#!/usr/bin/env bash
# Converte qualquer áudio para o formato aceito pela tag SSML <audio> da Alexa:
# MP3, MPEG-2, 48 kbps, 24 kHz, mono, sem tag ID3.
#
# Uso: scripts/convert-for-alexa.sh entrada.(mp3|wav|m4a|...) [saida.mp3]
# Sem o segundo argumento, grava em audio/<nome-da-entrada>.mp3

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Uso: $0 entrada [saida.mp3]" >&2
  exit 1
fi

cd "$(dirname "$0")/.."

in="$1"
name="$(basename "${in%.*}")"
out="${2:-audio/${name}.mp3}"

mkdir -p "$(dirname "$out")"

ffmpeg -y -loglevel error -i "$in" \
  -map 0:a -map_metadata -1 -vn \
  -ac 1 -ar 24000 \
  -codec:a libmp3lame -b:a 48k \
  -write_xing 0 -id3v2_version 0 \
  "$out"

# Remove uma tag ID3v2 residual, se o ffmpeg tiver gravado alguma.
python3 -I - "$out" <<'EOF'
import sys
p = sys.argv[1]
d = open(p, 'rb').read()
if d[:3] == b'ID3':
    size = ((d[6] & 0x7f) << 21) | ((d[7] & 0x7f) << 14) | ((d[8] & 0x7f) << 7) | (d[9] & 0x7f)
    open(p, 'wb').write(d[10 + size:])
EOF

echo "Gerado: $out"
scripts/validate-audio.sh "$out"
