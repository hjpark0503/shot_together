import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void triggerWebDownload(Uint8List bytes, String filename) {
  final base64 = base64Encode(bytes);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = 'data:image/png;base64,$base64';
  anchor.download = filename;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
}
