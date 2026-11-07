#!/bin/bash
# 在 macOS 上把三个原生库编出来（muta_hts / worldline / muta_sinsy），放进插件包目录。
#
# 上游只有 build-native.ps1（PowerShell + MSVC 假设），这里是等价的 bash 版本：
# 同样的 CMake 工程、同样的补丁，只是生成器换成 Makefile、产物后缀是 .dylib。
#
# 用法：  ./build-native.sh <输出目录>
# 依赖：  Xcode 命令行工具、CMake（brew install cmake）
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
THIRD="$HERE/third_party"
OUT="${1:-$HERE/build/native}"
BUILD="${BUILD_DIR:-$HERE/.native-build}"
JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
ARCH="$(uname -m)"

export PATH="/opt/homebrew/bin:$PATH"
mkdir -p "$OUT" "$BUILD"

# ── 1. muta_hts：上游 hts_engine_API 源码要打两个补丁，在副本上打 ──
SRC="$BUILD/hts_src"
rm -rf "$SRC"
cp -R "$THIRD/hts_engine_API" "$SRC"
rm -rf "$SRC/.git"
for p in "$THIRD"/hts_engine_API/patches/*.patch; do
  echo "  apply $(basename "$p")"
  git -C "$SRC" apply -p1 "$p"
done

echo "── muta_hts"
cmake -S "$HERE/src/native/hts" -B "$BUILD/hts" \
  -DCMAKE_BUILD_TYPE=Release -DHTS_SRC="$SRC" >/dev/null
cmake --build "$BUILD/hts" -j"$JOBS" >/dev/null
cp "$BUILD/hts/muta_hts.dylib" "$OUT/"

# ── 2. worldline：vendes 的两棵树本身就是最终状态，不用打补丁 ──
echo "── worldline"
cmake -S "$HERE/src/native/worldline" -B "$BUILD/worldline" \
  -DCMAKE_BUILD_TYPE=Release \
  -DWORLDLINE_SRC="$THIRD/worldline" \
  -DWORLD_SRC="$THIRD/world" >/dev/null
cmake --build "$BUILD/worldline" -j"$JOBS" >/dev/null
cp "$BUILD/worldline/worldline.dylib" "$OUT/"

# ── 3. muta_sinsy：Sinsy 是 2013 年前后的老代码，动态异常规格在 clang 17 下是硬错误，
#      需要显式关掉那几个诊断（MSVC 只是警告，所以上游没写）。 ──
echo "── muta_sinsy"
cmake -S "$HERE/src/native/sinsy" -B "$BUILD/sinsy" \
  -DCMAKE_BUILD_TYPE=Release \
  -DSINSY_SRC="$THIRD/sinsy" \
  -DCMAKE_CXX_FLAGS="-Wno-dynamic-exception-spec -Wno-register -Wno-deprecated-declarations" >/dev/null
cmake --build "$BUILD/sinsy" -j"$JOBS" >/dev/null
cp "$BUILD/sinsy/muta_sinsy.dylib" "$OUT/"

# 不签名的话，从网上下载的包在 arm64 上会被 TuneLab 拒载（arm64 要求每个 dylib 有效签名）。
for lib in muta_hts worldline muta_sinsy; do
  codesign --force --sign - "$OUT/$lib.dylib" >/dev/null 2>&1 || true
done

echo
echo "原生库（$ARCH）：$OUT"
ls -lh "$OUT"/*.dylib
