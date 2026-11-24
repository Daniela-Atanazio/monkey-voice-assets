# monkey-voice-assets

Áudios hospedados publicamente (GitHub Pages) para uso na skill **Monkey Voice** da Alexa, via tag SSML `<audio>`.

> **Este repositório é público.** Todo arquivo aqui pode ser baixado por qualquer pessoa com o link. Não publique áudio com dados pessoais, de clientes ou confidenciais. A própria Alexa proíbe esse tipo de conteúdo na tag `<audio>`.

## Áudios disponíveis

| Arquivo | Duração | URL para a skill |
|---|---|---|
| `audio/portcastelo.mp3` | 8,9 s | `https://<USUARIO>.github.io/monkey-voice-assets/audio/portcastelo.mp3` |

Substitua `<USUARIO>` pelo usuário (ou organização) dono do repositório.

## Requisitos da Alexa (tag SSML `<audio>`)

Fonte: [Referência SSML da Alexa — audio](https://developer.amazon.com/en-US/docs/alexa/custom-skills/speech-synthesis-markup-language-ssml-reference.html#audio)

**Arquivo**

| Requisito | Valor |
|---|---|
| Formato | MP3, **MPEG versão 2** |
| Bitrate | **48 kbps** |
| Sample rate | **16000, 22050 ou 24000 Hz** |
| Duração | até **240 s** por arquivo |
| Quantidade | até **5** arquivos por resposta (`outputSpeech` soma no máximo 240 s; `reprompt`, 90 s) |
| Conteúdo | sem informação de cliente ou sensível |

**URL**

| Requisito | Valor |
|---|---|
| Protocolo | **HTTPS**, em endpoint acessível pela internet |
| Certificado | válido e confiável (sem certificado autoassinado) |
| Autenticação | **não** pode exigir autenticação, portanto o repositório precisa ser **público** |

O GitHub Pages atende HTTPS com certificado válido e não exige autenticação.

## Áudios para o Voice Monkey

O [Voice Monkey](https://voicemonkey.io/docs/media) documenta como formato suportado **MP3 a 44,1 kHz ou 48 kHz, mono ou estéreo**, com até 240 s. Esse padrão é diferente do da tag SSML `<audio>` (MPEG-2, 48 kbps, até 24 kHz), por isso há duas pastas:

| Pasta | Para quê | Padrão |
|---|---|---|
| `audio/` | skills Alexa próprias (SSML `<audio>`) | MPEG-2, 48 kbps, 16/22,05/24 kHz. O CI valida. |
| `audio-voicemonkey/` | parâmetro `audio` da API do Voice Monkey | MP3 44,1 kHz mono |

URL de exemplo (Voice Monkey): `https://<USUARIO>.github.io/monkey-voice-assets/audio-voicemonkey/portcastelo.mp3`

| Arquivo | Duração | Uso |
|---|---|---|
| `audio-voicemonkey/portcastelo.mp3` | 8,9 s | teste inicial |
| `audio-voicemonkey/porteiro-castelo.mp3` | 21,3 s | campainha (botão Zigbee), tocado pelo Flow do Voice Monkey |
| `audio-voicemonkey/porteiro-castelo-alto.mp3` | 21,3 s | mesma gravação, mais forte (≈ -12 LUFS, pico -1,3 dBFS; a versão acima fica em ≈ -16 LUFS) |

## Como adicionar um novo áudio

Requer `ffmpeg` instalado.

```bash
# 1. Converter para o formato da Alexa (MP3, MPEG-2, 48 kbps, 24 kHz, mono)
scripts/convert-for-alexa.sh caminho/do/original.wav audio/nome-do-audio.mp3

# 2. Validar (também roda automaticamente no GitHub Actions a cada push)
scripts/validate-audio.sh

# 3. Publicar
git add audio/nome-do-audio.mp3
git commit -m "Adiciona nome-do-audio"
git push
```

Depois do push, aguarde o Pages publicar (normalmente alguns minutos) e teste a URL:

```bash
curl -sI https://<USUARIO>.github.io/monkey-voice-assets/audio/nome-do-audio.mp3
# esperado: HTTP/2 200 e content-type: audio/mpeg
```

## Como usar na skill

Resposta em SSML, com o áudio no meio da fala:

```xml
<speak>
  Aqui vai o som.
  <audio src="https://<USUARIO>.github.io/monkey-voice-assets/audio/portcastelo.mp3"/>
</speak>
```

Exemplo de handler com o ASK SDK para Node.js:

```javascript
const AUDIO_BASE = 'https://<USUARIO>.github.io/monkey-voice-assets/audio';

const MonkeyVoiceHandler = {
  canHandle(handlerInput) {
    return handlerInput.requestEnvelope.request.type === 'LaunchRequest';
  },
  handle(handlerInput) {
    return handlerInput.responseBuilder
      .speak(`<audio src="${AUDIO_BASE}/portcastelo.mp3"/>`)
      .getResponse();
  },
};
```

## Observações

- Se a skill falhar com um áudio, o primeiro teste é rodar `scripts/validate-audio.sh` nele. Um mp3 comum (MPEG-1, 44,1 kHz, 128 kbps) não toca na Alexa.
- Ao substituir um arquivo mantendo o mesmo nome, a Alexa e o CDN do Pages podem demorar a refletir a mudança. Para troca imediata, use um nome novo (por exemplo `portcastelo-v2.mp3`).
