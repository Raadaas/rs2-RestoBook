import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Sprema PDF na disk – otvara "Save As" dijalog da korisnik odabere lokaciju.
/// Na macOS sandbox zaobilazi "Operation not permitted" jer odabir putanje daje dopuštenje.
Future<String?> savePdfToFile(List<int> bytes, String filename) async {
  final path = await FilePicker.platform.saveFile(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
    fileName: filename.replaceAll('.pdf', ''),
  );
  if (path == null || path.isEmpty) return null;
  final fullPath = path.endsWith('.pdf') ? path : '$path.pdf';
  final file = File(fullPath);
  await file.writeAsBytes(bytes);
  return file.path;
}
