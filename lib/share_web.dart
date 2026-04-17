import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

@JS('_compressForShare')
external JSPromise<JSString> _compress(JSString jsonInput);

List<Uint8List>? parseSharedPhotos() {
  try {
    final hash = web.window.location.hash;
    if (!hash.startsWith('#share=')) return null;
    final encoded = hash.substring(7);
    final jsonStr = utf8.decode(base64Url.decode(base64Url.normalize(encoded)));
    final list = (jsonDecode(jsonStr) as List).cast<String>();
    return list.map(base64Decode).toList();
  } catch (_) {
    return null;
  }
}

Future<String?> buildShareUrl(List<Uint8List> photos) async {
  try {
    final input = jsonEncode(photos.map(base64Encode).toList());
    final result = await _compress(input.toJS).toDart;
    final compressed = (jsonDecode(result.toDart) as List).cast<String>();
    final encoded = base64Url.encode(utf8.encode(jsonEncode(compressed)));
    final base = web.window.location.href.split('#').first;
    return '$base#share=$encoded';
  } catch (_) {
    return null;
  }
}

Future<void> copyToClipboard(String text) async {
  try {
    await web.window.navigator.clipboard.writeText(text).toDart;
  } catch (_) {
    // fallback: execCommand
    final ta = web.document.createElement('textarea') as web.HTMLTextAreaElement;
    ta.value = text;
    web.document.body!.append(ta);
    ta.select();
    web.document.execCommand('copy');
    ta.remove();
  }
}
