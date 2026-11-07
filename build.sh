#!/bin/bash
# 构建 YanXi for TuneLab 的 .tlx 包。
#
#   ./build.sh            # 两个平台都做：mac (osx-arm64) + windows (win-x64)
#   ./build.sh mac        # 只做 mac
#   ./build.sh win        # 只做 windows
#   ./build.sh install    # 顺带装进本机 TuneLab（mac）
#
# 产物在 dist/：
#   YanXiForTuneLab-<版本>-mac-arm64.tlx
#   YanXiForTuneLab-<版本>-win-x64.tlx
#
# 依赖：.NET 8 SDK、CMake、Xcode 命令行工具。
# 音源默认取 ~/Music/MUTA/yanxi，可以用 VOICE_DIR=/path/to/yanxi 覆盖。
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DOTNET="${DOTNET:-/usr/local/share/dotnet/dotnet}"
[ -x "$DOTNET" ] || DOTNET="$(command -v dotnet)"
export PATH="$(dirname "$DOTNET"):/opt/homebrew/bin:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1

PROJ="$HERE/src/YanXiForTuneLab/YanXiForTuneLab.csproj"
VERSION="$(python3 -c "import json;print(json.load(open('$HERE/src/YanXiForTuneLab/manifest.json'))['version'])")"
VOICE_DIR="${VOICE_DIR:-$HOME/Music/MUTA/yanxi}"
VOICE_ID="$(basename "$VOICE_DIR")"
BUILD="$HERE/build"
DIST="$HERE/dist"
MAC_PKG="$BUILD/mac-package"
WIN_PKG="$BUILD/win-package"
MAC_ARCH="$(uname -m)"

if [ ! -f "$VOICE_DIR/${VOICE_ID}.voice" ]; then
  echo "找不到音源：$VOICE_DIR/${VOICE_ID}.voice" >&2
  echo "用 VOICE_DIR=/path/to/yanxi ./build.sh 指定。" >&2
  exit 1
fi

# 编译期需要宿主的 SDK dll；优先用本机装的 TuneLab.app。
find_tunelab_dir() {
  if [ -n "${TUNELAB_DIR:-}" ]; then echo "$TUNELAB_DIR"; return; fi
  for d in \
    "$HOME/Applications/TuneLab.app/Contents/MacOS" \
    "/Applications/TuneLab.app/Contents/MacOS" \
    "$HOME/Projects/TuneLab-mac/tunelab-src/TuneLab/bin/Release/net8.0"; do
    [ -f "$d/TuneLab.SDK.dll" ] && { echo "$d"; return; }
  done
  echo ""
}
TL_DIR="$(find_tunelab_dir)"

build_managed() {   # $1 = 输出目录
  echo "── 托管代码 → $1"
  rm -rf "$1"
  "$DOTNET" build "$PROJ" -c Release -p:MutaLite=true \
    -p:TuneLabDir="${TL_DIR:-__unset__}" -p:OutputPath="$1/" >/dev/null
  find "$1" -name '*.pdb' -delete
}

copy_voice() {      # $1 = 输出目录
  echo "── 音源 $VOICE_DIR → $1/voices/$VOICE_ID"
  mkdir -p "$1/voices/$VOICE_ID"
  cp "$VOICE_DIR"/*.voice "$VOICE_DIR"/*.inf "$VOICE_DIR"/*.bnk "$VOICE_DIR"/*.chr "$1/voices/$VOICE_ID/"
  [ -f "$VOICE_DIR/${VOICE_ID}.nsp" ] && cp "$VOICE_DIR/${VOICE_ID}.nsp" "$1/voices/$VOICE_ID/" || true
  du -sh "$1/voices/$VOICE_ID"
}

pack() {            # $1 = 包目录  $2 = 输出 tlx
  echo "── 打包 $(basename "$2")"
  mkdir -p "$DIST"
  rm -f "$2"
  ( cd "$1" && zip -qr -X "$2" . )
  ls -lh "$2"
}

build_mac() {
  echo "══ mac ($MAC_ARCH)"
  "$HERE/build-native.sh" "$BUILD/mac-natives" >/dev/null
  build_managed "$MAC_PKG"
  cp "$BUILD/mac-natives"/*.dylib "$MAC_PKG/"
  copy_voice "$MAC_PKG"
  pack "$MAC_PKG" "$DIST/YanXiForTuneLab-$VERSION-mac-$MAC_ARCH.tlx"
}

build_win() {
  echo "══ windows (x64)"
  "$HERE/tools/fetch-win-natives.sh" "$BUILD/win-natives" >/dev/null
  build_managed "$WIN_PKG"
  cp "$BUILD/win-natives"/*.dll "$WIN_PKG/"
  copy_voice "$WIN_PKG"
  pack "$WIN_PKG" "$DIST/YanXiForTuneLab-$VERSION-win-x64.tlx"
}

install_mac() {
  local ext="$HOME/Library/Application Support/TuneLab/Extensions/com.forain.yanxifortunelab"
  echo "── 安装到 $ext"
  rm -rf "$ext"
  mkdir -p "$ext"
  cp -R "$MAC_PKG"/. "$ext"/
}

if [ -z "$TL_DIR" ]; then
  echo "警告：没找到 TuneLab.SDK.dll，用 TUNELAB_DIR 指定安装目录（只影响编译期引用）。" >&2
fi

case "${1:-all}" in
  mac)  build_mac ;;
  win)  build_win ;;
  all)  build_mac; build_win ;;
  install) build_mac; install_mac ;;
  *)    echo "用法: $0 [all|mac|win|install]" >&2; exit 2 ;;
esac

echo
echo "完成："
ls -lh "$DIST"/*.tlx
