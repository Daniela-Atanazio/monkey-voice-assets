#!/usr/bin/env bash
# Valida se os arquivos .mp3 atendem aos requisitos da tag SSML <audio> da Alexa.
# Referência: https://developer.amazon.com/en-US/docs/alexa/custom-skills/speech-synthesis-markup-language-ssml-reference.html#audio
#
# Requisitos verificados:
#   - MP3 MPEG versão 2 (sample rate 16000, 22050 ou 24000 Hz implica MPEG-2)
#   - 48 kbps
#   - duração <= 240 s por arquivo
#
# Uso: scripts/validate-audio.sh [arquivo.mp3 ...]   (sem argumentos: valida audio/**/*.mp3)

set -uo pipefail

MAX_SECONDS=240
ALLOWED_RATES="16000 22050 24000"
REQUIRED_BITRATE=48000

cd "$(dirname "$0")/.."

if [ "$#" -gt 0 ]; then
  files=("$@")
else
  mapfile -t files < <(find audio -type f -iname '*.mp3' | sort)
fi

if [ "${#files[@]}" -eq 0 ]; then
  echo "Nenhum arquivo .mp3 encontrado em audio/."
  exit 0
fi

fail=0
for f in "${files[@]}"; do
  errors=()

  codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$f" 2>/dev/null)
  rate=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of csv=p=0 "$f" 2>/dev/null)
  bitrate=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of csv=p=0 "$f" 2>/dev/null)
  duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null)

  [ "$codec" = "mp3" ] || errors+=("codec '$codec' (esperado: mp3)")
  case " $ALLOWED_RATES " in
    *" $rate "*) ;;
    *) errors+=("sample rate ${rate:-?} Hz (esperado: 16000, 22050 ou 24000, que correspondem a MPEG-2)") ;;
  esac
  [ "${bitrate:-0}" = "$REQUIRED_BITRATE" ] || errors+=("bitrate ${bitrate:-?} bps (esperado: ${REQUIRED_BITRATE})")
  if [ -z "$duration" ] || ! awk -v d="$duration" -v m="$MAX_SECONDS" 'BEGIN{exit !(d<=m)}'; then
    errors+=("duração ${duration:-?} s (máximo: ${MAX_SECONDS} s)")
  fi
  ffmpeg -v error -i "$f" -f null - 2>/dev/null || errors+=("arquivo não decodifica sem erros")

  if [ "${#errors[@]}" -eq 0 ]; then
    printf 'OK    %s (mp3, %s Hz, %s bps, %.1f s)\n' "$f" "$rate" "$bitrate" "$duration"
  else
    fail=1
    printf 'ERRO  %s\n' "$f"
    for e in "${errors[@]}"; do printf '        - %s\n' "$e"; done
  fi
done

exit "$fail"
