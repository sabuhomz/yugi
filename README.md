# Speed Duel Cards (Flutter)

แอปรวมการ์ด Yu-Gi-Oh! Duel Links แบบ **Speed Duel** พร้อมแปลความสามารถเป็นภาษาไทย และระบบจัดเด็ค

## วิธีรัน

```bash
cd duel_speed_cards
bash setup.sh      # สร้าง android/ios + เปิดสิทธิ์ INTERNET + flutter pub get
flutter run
```

(ต้องติดตั้ง Flutter SDK 3.24 ขึ้นไป / Dart 3.3+)

## ฟีเจอร์

- ดึงการ์ดจาก YGOPRODeck ทั้ง `format=Duel Links` และ `format=Speed Duel` แล้วรวมกัน (รวม Extra Deck) ตรวจ `checkDBVer.php` ทุกครั้งที่เปิดแอป ถ้าฐานข้อมูลอัปเดตจะดึงใหม่เอง มีปุ่มรีเฟรชในหน้าการ์ด และแคชไว้ใช้ออฟไลน์
- รูปการ์ดจริงจาก YGOPRODeck (โหลดผ่าน `Image.network` เก็บในหน่วยความจำระหว่างใช้งาน)
- ชื่อการ์ดเป็นภาษาอังกฤษ ความสามารถ/คำบรรยายแปลเป็นไทยในหน้ารายละเอียด (กดสลับดูต้นฉบับ EN ได้)
- ค้นหาจากชื่อ + ฟิลเตอร์ (ประเภท, ชนิดมอนสเตอร์, ธาตุ, เลเวล, เผ่า) + เรียงตามชื่อ/ATK/DEF/เลเวล
- จัดเด็ค: Main 20–30 ใบ, Extra Deck 9 ใบ, ใบซ้ำได้ไม่เกิน 3, ตั้งชื่อเด็ค, ทำสำเนา, เรียงอัตโนมัติ, หลายเด็ค (เก็บในเครื่อง)

## การแปลไทย (ทำงานอย่างไร)

`lib/services/translation_service.dart`

1. ชื่อการ์ดใน `"..."` ถูกกันไว้ ไม่แปล
2. ศัพท์เกม (Special Summon, Graveyard, Tribute, banish ฯลฯ) แทนด้วยคำไทยตามพจนานุกรมในไฟล์ แก้/เพิ่มได้ที่ `_glossary`
3. ส่วนที่เหลือแปลผ่าน Google Translate (`translate.googleapis.com`, client=gtx) แล้วบันทึกแคชต่อการ์ด ดังนั้นแต่ละใบแปลครั้งเดียว

> endpoint นี้ไม่เป็นทางการและไม่มีรับประกัน หากจะปล่อยแอปจริงแนะนำเปลี่ยนเป็น Google Cloud Translation API (มี API key) โดยแก้เฉพาะเมธอด `_googleOne`

## โครงสร้าง

```
lib/
  main.dart
  theme/duel_theme.dart          สี/ปุ่ม/พาเนลสไตล์ Duel Links
  models/                        card, deck, card_filter
  services/                      card_repository, translation_service, deck_store
  screens/                       home, cards, card_detail, deck_list, deck_editor
  widgets/                       card_image, filter_sheet, dialogs
```
