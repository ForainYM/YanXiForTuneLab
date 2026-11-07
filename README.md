# YanXi for TuneLab

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![TuneLab](https://img.shields.io/badge/TuneLab-2.1.0%2B%20(SDK%201.1)-informational)](https://github.com/LiuYunPlayer/TuneLab)

**把嫣汐（YanXi）的 MUTA 声库带进 TuneLab 唱歌。** 装好插件、选「嫣汐」音源，就能直接在 TuneLab
里写词、画曲线、导出成品——不需要另外安装 MUTA，也不需要把音源目录指来指去。

本仓库是 [MUTAForTuneLab](https://github.com/KakaruHayate/MUTAForTuneLab)（MIT）的 fork：
声学模型、前端、声码器那条链沿用上游，区别只有两处——**声库随包分发**，以及引擎只暴露嫣汐一个音源。

**[English](README.en.md)**

---

## 这是什么

TuneLab 的音源扩展（extension type = `voice`，engine = `YanXi`）。插件自己实现 MUTA 的
`.voice` / `.inf` / `.bnk` 读取与 HTS 推理，再接 **worldline R1.1** 声码器合成波形；
不含 MUTA 的可执行文件，也不调用 MUTA。

随包带的是 `voices/yanxi/`：嫣汐的声学模型（`.voice`、`.inf`）、拼接库（`.bnk`）、音色定义（`.chr`）与
噪声参数（`.nsp`）。解压后约 100 MB，所以 `.tlx` 有 97 MB 左右——**体积基本就是声库本身**。

## 功能

- **中文与日文共用一副音色。** 歌词语言是 part 级设置：切语言只换前端（拼音标注 / Sinsy 音素），不改音色。
- **MUTA 的辅音时值。** 辅音用 MUTA 自己的时长表，最多占音符的一半，短音符也咬得清。
- **延续音。** `-` 和 `+` 是连音记号，把前一音符的元音拉过去，不重新起音。
- **跨拍滑音。** 音高变化在拍点前 60–90 ms 起、拍点后约 30 ms 落，不是硬切。
- **手动换气。** 歌词写 `br` 或 `sp`，取声库 `.inf` 里的尾音片段（没有就带通噪声），按 MUTA 的电平垫在唱声下面。
- **音素锁定。** 任意音符可钉死 leading/body 音素，编辑器里的音素边界和渲染用的是同一组数字。
- **音区偏移。** 每个音符可选不同的采样音区（半音偏移），音高本身不变。
- **七条自动化。** Energy / Timbre / Husky 作用于声学模型输出，Gender / Tension / Breathiness / Voicing 作用于声码器。
- **增量渲染。** 改音符只重算所在块，改曲线只重算重叠时间段的块，改 part 设置才整段重算。

## 安装

1. 下载对应平台的 `.tlx`：
   - Windows x64 → `YanXiForTuneLab-0.1.0-win-x64.tlx`
   - macOS（Apple Silicon）→ `YanXiForTuneLab-0.1.0-mac-arm64.tlx`
2. 把 `.tlx` **拖进 TuneLab 窗口**，或用扩展侧边栏的 **Install Extension**。安装即解压并立即加载，不用重启。
   （手动安装也行：把包解压到扩展目录，`manifest.json` 要在
   `com.forain.yanxifortunelab/` 这一层的根上——Windows 是 `%AppData%\TuneLab\Extensions\`，
   macOS 是 `~/Library/Application Support/TuneLab/Extensions/`。）
3. 新建声部，音源选 **嫣汐 (YanXi)**。

装好后在 设置 → 扩展 → 嫣汐 里可以再补一个「额外 MUTA 音源目录」（可选）；不填也能用，随包那个音源始终在。

## 平台

| | 支持情况 |
| --- | --- |
| Windows x64 | ✅ 官方 TuneLab 2.1.0+ 直接可用 |
| macOS arm64（Apple Silicon） | ✅ 需自行从源码构建 TuneLab（官方只发 Windows 版） |
| macOS x86_64 / Windows ARM64 | ❌ 未提供（原生库只编了 arm64 / x64） |

### 关于 macOS 版

TuneLab 官方目前只发布 Windows 版，mac 版要从 [LiuYunPlayer/TuneLab](https://github.com/LiuYunPlayer/TuneLab)
自己构建。**插件本身是标准扩展，不改宿主**：SDK 程序集由 TuneLab 进程提供，插件只依赖
`sdk-version 1.1` 的接口，所以任何一份 2.1.x 的 macOS 构建都能加载这个包——不需要谁打补丁，
也不需要和构建者用同一台机器。唯一的硬条件是：**宿主是 arm64 的 TuneLab 2.1.x**。

构建步骤（与 TuneLab 仓库的说明一致，这里只是本机验证过的版本）：

```bash
git clone https://github.com/LiuYunPlayer/TuneLab.git
cd TuneLab
dotnet publish TuneLab/TuneLab.csproj -c Release -r osx-arm64 --self-contained true -o out
# TuneLab 的音频走 ppy.SDL2-CS；Homebrew 的 libSDL2 是 sdl2-compat，运行时还要 libSDL3。
cp /opt/homebrew/lib/libSDL2-2.0.0.dylib out/libSDL2.dylib
cp /opt/homebrew/lib/libSDL3.0.dylib     out/libSDL3.dylib
```

> Intel Mac 用户：mac 包里三个原生库（`muta_hts` / `muta_sinsy` / `worldline`）只有 arm64 架构，
> 所以 Intel 上加载会失败；需要的话可按下面「从源码构建」在 x86_64 上重编。

## 语言设置（容易踩的坑）

声库本身是中文 MUTA 库。**part 的 `language` 默认是中文**，这时假名会被当拼音处理，
`い`、`う` 这类音可能直接唱不出来（渲染时报 `phone alignment … the labels gave 0 phones`）。

用日文歌词时，把该 part 的语言属性设成 **Japanese / ja**：前端会切到 Sinsy 音素，音色不变。
汉字歌词则直接用中文即可。

## 从源码构建

依赖：.NET 8 SDK、CMake；macOS 还要 Xcode 命令行工具，Windows 还要 VS 2022 C++ 工具。

```bash
# macOS：编译原生库 + 托管代码，把声库拷进包，产出 dist/*.tlx
VOICE_DIR=~/Music/MUTA/yanxi ./build.sh mac

# Windows 包：原生库直接取上游 release 的 win-x64 MSVC 产物（scripts 里有校验）
./build.sh win

# 装进本机 TuneLab（macOS）
./build.sh install
```

- `VOICE_DIR` 指向一个 MUTA 音源目录，里面要有 `<id>.voice`、`<id>.inf`、`<id>.bnk`（`.chr`/`.nsp` 可选）。
  默认 `~/Music/MUTA/yanxi`。
- 原生库源码在 `third_party/`，`src/native/` 是包装层；`build-native.sh` 会在副本上给
  `hts_engine_API` 打两个补丁，并对 dylib 做 adhoc 签名（arm64 上没签名 TuneLab 会拒载）。
- **声库不进仓库**（体积与权利原因），仓库里只有代码；构建时从本机拷进包里。

## 许可

- **插件代码**：[MIT](LICENSE)，Copyright (c) 2026 Forain。可商用、可修改、可再分发，保留版权与许可声明即可。
- **上游**：[MUTAForTuneLab](https://github.com/KakaruHayate/MUTAForTuneLab) 与
  [TuneLab](https://github.com/LiuYunPlayer/TuneLab) 均为 MIT，原文见 `LICENSE-MUTAForTuneLab`、`LICENSE-TuneLab`。
- **音源数据**：`voices/yanxi/` 下的 `.voice/.inf/.bnk/.chr/.nsp` **不适用 MIT**，适用
  [`LICENSE-VOICEBANK.txt`](LICENSE-VOICEBANK.txt)：非商业可自由使用（须署名「音源：嫣汐 TuneLab」），
  禁止商业使用、二次配布、AI 训练与未授权移植。完整条款见 [`RULES.md`](RULES.md)（V1.0，2026-11-07 生效）。
- **权利说明**：音源数据来自原始 MUTA 嫣汐音源，由本包做格式转换；角色与原始数据的权利归原权利人，
  本包不对其主张权利，仅在取得原权利人法定代表人文字确认后进行非商业配布。权利人可随时联系下架。
- **第三方**：Sinsy、HTS engine、WORLD、worldline 等组件的许可原文都在 `THIRD-PARTY-NOTICES.md`。

## 致谢

- [KakaruHayate/MUTAForTuneLab](https://github.com/KakaruHayate/MUTAForTuneLab) — 整个 MUTA 引擎移植的基础
- [LiuYunPlayer/TuneLab](https://github.com/LiuYunPlayer/TuneLab) — 宿主与插件 SDK
- [Sinsy](https://github.com/sinsy-synth/sinsy) — 日文前端；[HTS Engine](https://github.com/r9y9/hts_engine_API) — 声学模型推理
- [WORLD](https://github.com/mmorise/World) 与 [worldline](https://github.com/KakaruHayate/worldline) — 声码器
- 嫣汐 / MUTA — 声库与角色
