#!/bin/bash
# 把 swift build 产物组装成 CopyCove.app 并签名（无需 Xcode）
set -euo pipefail
cd "$(dirname "$0")/.."

# CLT 27 beta SDK 缺 SwiftUIMacros 插件（@State 编不过），钉在 26.5 SDK
# 直到苹果修复；老 SDK 不存在时回落默认
PINNED_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
if [ -d "$PINNED_SDK" ]; then
    export SDKROOT="$PINNED_SDK"
fi

echo "==> swift build (release)"
swift build -c release

APP="build/CopyCove.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cp .build/release/CopyCove "$APP/Contents/MacOS/CopyCove"
cp resources/Info.plist "$APP/Contents/Info.plist"

echo "==> codesign"
# 优先用本地稳定证书 CopyCoveDev（TCC 辅助功能授权绑定它，重编译不失效）；
# 注意自签名证书不会出现在 find-identity 的有效列表里，用 find-certificate 检测
if security find-certificate -c "CopyCoveDev" >/dev/null 2>&1 \
   && codesign --force --sign "CopyCoveDev" "$APP" 2>/dev/null; then
    echo "    签名身份: CopyCoveDev（稳定）"
else
    codesign --force --sign - "$APP"
    echo "    签名身份: ad-hoc（回退；每次编译指纹变化，TCC 授权会失效）"
fi

echo "==> 完成: $APP"
echo "    运行: open $APP"
