# YanXi for TuneLab v0.1.0

**嫣汐（YanXi）第一次能在 TuneLab 里直接唱歌**——声库随插件一起装，不用另外装 MUTA。

## 下载

| 平台 | 文件 | 大小 |
| --- | --- | --- |
| Windows x64 | `YanXiForTuneLab-0.1.0-win-x64.tlx` | 97 MB |
| macOS arm64（Apple Silicon） | `YanXiForTuneLab-0.1.0-mac-arm64.tlx` | 97 MB |

安装：把 `.tlx` 拖进 TuneLab 窗口，或用扩展侧边栏的 **Install Extension**，装完立即生效；新建声部时音源选 **嫣汐 (YanXi)**。

macOS 版需要 TuneLab 2.1.x 的 arm64 构建（官方只发 Windows，mac 版要自己从源码构建，方法见 README）。插件是标准扩展，不改宿主，任何 2.1.x arm64 构建都能加载。

## 这一版里有什么

- 嫣汐的 MUTA 声库（`.voice` / `.inf` / `.bnk` / `.chr` / `.nsp`）随包分发，解压约 100 MB。
- 中文与日文共用一副音色：语言是 part 级设置，只换前端，不改音色。
- MUTA 的辅音时值、延续音、跨拍滑音、手动换气（`br` / `sp`）、音素锁定、每音符音区偏移。
- 内置 worldline R1.1 声码器，无需外部组件；七条自动化（Energy / Timbre / Husky / Gender / Tension / Breathiness / Voicing）。
- 设置 → 扩展 → 嫣汐 里可以再指向一个额外的 MUTA 音源目录（可选）。

## 已知事项

- part 的语言属性默认是中文；写日文歌词时把它设成 **Japanese / ja**，否则假名可能被当拼音而唱不出来。
- 单声部音源，同 tick 叠音符不会渲染（这是 MUTA 引擎的既有行为）。
- 原生库只有 arm64（mac）与 x64（win）两种架构，Intel Mac 与 Windows ARM64 不支持。

## 校验

```
SHA256 (YanXiForTuneLab-0.1.0-win-x64.tlx)  = 63866a6bb20c22d49a32ae4970b79cd69bac57ee7584e60fc35a5b728c7c9513
SHA256 (YanXiForTuneLab-0.1.0-mac-arm64.tlx) = 1368d06a770411b858f751b66d7d6e052f541c9e4a97ed18e46c6e8d311ff49f
```

## 许可

插件代码 MIT（Copyright 2026 Forain）。上游 [MUTAForTuneLab](https://github.com/KakaruHayate/MUTAForTuneLab) 与
[TuneLab](https://github.com/LiuYunPlayer/TuneLab) 亦为 MIT。`voices/yanxi/` 里的声库数据权利归 MUTA 及其权利人，
本包只作原样再分发，不授予音源、角色或 MUTA 程序的权利；权利人要求下架即撤。详见 `THIRD-PARTY-NOTICES.md` 第 0 节。
