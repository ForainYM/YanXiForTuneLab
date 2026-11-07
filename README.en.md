# YanXi for TuneLab

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**YanXi (嫣汐) singing in TuneLab, voice bank included.** Install the extension, pick the
「嫣汐 (YanXi)」 voice, and write — no separate MUTA install, no pointing the plugin at a folder.

This is a fork of [MUTAForTuneLab](https://github.com/KakaruHayate/MUTAForTuneLab) (MIT). The acoustic
model, front ends and vocoder are upstream work; this fork only (a) **ships the voice bank inside the
package** and (b) exposes a single engine, `YanXi`, with 嫣汐 as its only voice.

**[中文说明](README.md)**

---

## What it is

A TuneLab voice extension (`type = voice`, `engine = YanXi`). It reads MUTA's `.voice` / `.inf` / `.bnk`
formats, runs the HTS model itself, and renders through **worldline R1.1**. No MUTA binary is included
or invoked.

`voices/yanxi/` holds YanXi's model, bank, timbre and noise files — about 100 MB, which is why the
`.tlx` is ~97 MB.

## Features

- **Chinese and Japanese from one voice.** Language is a part setting; only the front end changes
  (pinyin labels vs. Sinsy labels), not the timbre.
- **MUTA consonant timing**, capped at half the note, so short notes stay articulate.
- **Continuations** — `-` and `+` stretch the previous vowel, no second attack.
- **Portamento across the beat** — pitch moves start 60–90 ms before the beat and settle ~30 ms after.
- **Manual breaths** — `br` / `sp` take a fragment of the bank's `.inf` tail PCM (band-passed noise
  otherwise), mixed under the singing at MUTA's level.
- **Pinned phonemes** and **per-note bank register offset**.
- **Seven automation lanes** — Energy / Timbre / Husky on the model output; Gender / Tension /
  Breathiness / Voicing on the vocoder.
- **Incremental rendering** — a note edit re-renders its block; a curve edit, only overlapping blocks.

## Install

1. Download the `.tlx` for your platform (Windows x64 or macOS arm64).
2. Drag it into the TuneLab window, or use **Install Extension** in the extensions sidebar. It unpacks
   and loads immediately.
   Manual: unzip so `manifest.json` sits at the root of
   `Extensions/com.forain.yanxifortunelab/` — `%AppData%\TuneLab\Extensions\` on Windows,
   `~/Library/Application Support/TuneLab/Extensions/` on macOS.
3. Add a voice part and choose **嫣汐 (YanXi)**.

## Platforms

| | |
| --- | --- |
| Windows x64 | ✅ official TuneLab 2.1.0+ |
| macOS arm64 (Apple Silicon) | ✅ with a self-built TuneLab — official builds are Windows-only |
| macOS x86_64 / Windows ARM64 | ❌ not built |

The extension is a plain TuneLab extension: SDK assemblies come from the host process, and it only
depends on `sdk-version 1.1`, so **any 2.1.x macOS arm64 build of TuneLab can load it** — no host
patches, no need to be built on the same machine.

## Language note

The bank is a Chinese MUTA voice. A part defaults to Chinese, where kana may be read as pinyin and
fail to render. For Japanese lyrics, set the part's language to **Japanese / ja**; the front end
switches to Sinsy phones and the timbre stays the same.

## Build

Requires .NET 8 SDK and CMake (plus Xcode CLT on macOS, VS 2022 C++ tools on Windows).

```bash
VOICE_DIR=~/Music/MUTA/yanxi ./build.sh mac   # native libs + managed code + voice bank → dist/*.tlx
./build.sh win                                # reuses upstream win-x64 native DLLs (sha256 pinned)
./build.sh install                            # install into the local TuneLab (macOS)
```

`VOICE_DIR` must contain `<id>.voice`, `<id>.inf` and `<id>.bnk`. **The voice bank is not in this
repository** — it is copied into the package at build time.

## License

- Plugin code: [MIT](LICENSE), Copyright (c) 2026 Forain.
- Upstream MUTAForTuneLab and TuneLab are MIT; see `LICENSE-MUTAForTuneLab` and `LICENSE-TuneLab`.
- Voice data in `voices/yanxi/` belongs to MUTA and its rights holders; it is redistributed verbatim
  inside this extension without granting any rights to the voice, the character or MUTA. See §0 of
  [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md); takedown requests are honoured.
- Sinsy, HTS engine, WORLD and worldline notices are reproduced in `THIRD-PARTY-NOTICES.md`.

## Credits

[KakaruHayate/MUTAForTuneLab](https://github.com/KakaruHayate/MUTAForTuneLab),
[LiuYunPlayer/TuneLab](https://github.com/LiuYunPlayer/TuneLab),
[Sinsy](https://github.com/sinsy-synth/sinsy), [HTS Engine](https://github.com/r9y9/hts_engine_API),
[WORLD](https://github.com/mmorise/World), [worldline](https://github.com/KakaruHayate/worldline),
and 嫣汐 / MUTA for the voice.
