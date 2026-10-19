import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// หาไฟล์แคชในเครื่อง ถ้าแพลตฟอร์มไม่รองรับ (หรือปลั๊กอินยังไม่ลงทะเบียน) คืน null
/// แล้วแอปจะทำงานต่อโดยไม่แคชลงดิสก์ แทนที่จะพัง
Future<File?> cacheFile(String name) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$name');
  } catch (_) {
    try {
      return File('${Directory.systemTemp.path}/$name');
    } catch (_) {
      return null;
    }
  }
}
