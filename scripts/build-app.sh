#!/bin/bash
# 把 swift build 产物组装成 CopyCove.app 并 ad-hoc 签名（无需 Xcode）
set -euo pipefail
cd "$(dirname "$0")/.."

echo "==> swift build (release)"
swift build -c release

APP="build/CopyCove.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cp .build/release/CopyCove "$APP/Contents/MacOS/CopyCove"
cp resources/Info.plist "$APP/Contents/Info.plist"

echo "==> ad-hoc codesign"
codesign --force --sign - "$APP"

echo "==> 完成: $APP"
echo "    运行: open $APP"
