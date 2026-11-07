#!/bin/bash
# 把上游 release 里 Windows x64 的三个原生 DLL 取下来，放进 $1 目录。
#
# 我们不在 Windows 上编译，但上游的 win-x64 lite 包里就是同一套源码 + MSVC 产物，
# 直接复用（MIT，来源与许可写在 THIRD-PARTY-NOTICES.md 里）。
#
# 用法：  ./tools/fetch-win-natives.sh <输出目录>
set -euo pipefail

OUT="${1:?用法: $0 <输出目录>}"
CACHE="${CACHE_DIR:-$(cd "$(dirname "$0")/.." && pwd)/.cache}"
URL="https://github.com/KakaruHayate/MUTAForTuneLab/releases/download/v0.1.0/MUTAForTuneLab-0.1.0-win-x64-lite.tlx"
SHA256="10c4cbcc936e02a99b4b850afa08f02059eaae9d466951df546c130163010607"

mkdir -p "$OUT" "$CACHE"
TLX="$CACHE/upstream-win-x64-lite.tlx"

if [ ! -f "$TLX" ]; then
  echo "── 下载上游 win-x64 原生库 ($URL)"
  curl -fL --retry 3 -o "$TLX.part" "$URL"
  mv "$TLX.part" "$TLX"
fi

actual="$(shasum -a 256 "$TLX" | cut -d' ' -f1)"
[ "$actual" = "$SHA256" ] || { echo "sha256 不符：$TLX（$actual）" >&2; exit 1; }

TMP="$CACHE/upstream-win-x64"
rm -rf "$TMP" && mkdir -p "$TMP"
unzip -qo "$TLX" -d "$TMP"

for lib in muta_hts muta_sinsy worldline; do
  [ -f "$TMP/$lib.dll" ] || { echo "上游包里没有 $lib.dll" >&2; exit 1; }
  cp "$TMP/$lib.dll" "$OUT/"
done

echo "Windows 原生库："
ls -lh "$OUT"/*.dll
