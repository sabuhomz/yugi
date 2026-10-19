#!/usr/bin/env bash
# สร้างโฟลเดอร์ android/ios ด้วย flutter create โดยไม่ทับโค้ดของเรา และเปิดสิทธิ์ INTERNET
set -e
cd "$(dirname "$0")"

BK=$(mktemp -d)
cp -r lib "$BK/lib"
cp pubspec.yaml "$BK/pubspec.yaml"

flutter create --project-name duel_speed_cards --org com.example --platforms=android,ios .

rm -rf lib && cp -r "$BK/lib" lib
cp "$BK/pubspec.yaml" pubspec.yaml
rm -rf test   # เทสต์เริ่มต้นของ flutter create อ้างอิง MyApp เดิม

M=android/app/src/main/AndroidManifest.xml
if ! grep -q "android.permission.INTERNET" "$M"; then
  sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$M"
fi

flutter pub get
echo "เสร็จแล้ว รันด้วย: flutter run"
