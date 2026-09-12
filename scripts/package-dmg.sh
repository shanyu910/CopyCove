#!/bin/bash
# 生成 CopyCove.dmg（拖拽安装式：内含 App + Applications 快捷方式）
# 仅用系统自带工具（hdiutil），无第三方依赖
set -euo pipefail
cd "$(dirname "$0")/.."

# 与 build-app.sh 一致：钉 SDK 26.5（CLT 27 的 SwiftUI 宏插件缺失）
PINNED_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
if [ -d "$PINNED_SDK" ]; then
    export SDKROOT="$PINNED_SDK"
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" resources/Info.plist)
APP="build/CopyCove.app"
DMG="build/CopyCove-$VERSION.dmg"

if [ ! -d "$APP" ]; then
    echo "==> 先构建 App"
    scripts/build-app.sh
fi

echo "==> 准备 dmg 暂存目录"
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "==> 生成 $DMG"
rm -f "$DMG"
hdiutil create -volname "CopyCove" \
    -srcfolder "$STAGING" \
    -format UDZO \
    -ov \
    "$DMG" -quiet

echo "==> 校验"
hdiutil verify "$DMG" -quiet && echo "    dmg 校验通过"

echo "==> 完成: $DMG"
echo "    使用: 双击挂载后，把 CopyCove 拖到 Applications 上即完成安装"
