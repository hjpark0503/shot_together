import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:web/web.dart' as web;

const _cloudName = 'dyqxanbmx';
const _uploadPreset = 'shot-together';

Future<List<Uint8List>?> parseSharedPhotos() async {
  try {
    final hash = web.window.location.hash;
    if (!hash.startsWith('#share=')) return null;
    final encoded = hash.substring(7);
    final ids = utf8.decode(base64Url.decode(base64Url.normalize(encoded))).split(',');

    final photos = await Future.wait(
      ids.map((id) async {
        final url = 'https://res.cloudinary.com/$_cloudName/image/upload/$id';
        final res = await http.get(Uri.parse(url));
        return res.bodyBytes;
      }),
    );
    return photos;
  } catch (_) {
    return null;
  }
}

Future<String?> buildShareUrl(List<Uint8List> photos) async {
  final ids = <String>[];

  for (int i = 0; i < photos.length; i++) {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload'),
    );
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      photos[i],
      filename: 'photo_$i.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      // ignore: avoid_print
      print('Cloudinary error [${res.statusCode}]: ${res.body}');
      throw Exception('Upload failed [${res.statusCode}]: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    ids.add(json['public_id'] as String);
  }

  final encoded = base64Url.encode(utf8.encode(ids.join(',')));
  final base = web.window.location.href.split('#').first;
  return '$base#share=$encoded';
}

Future<void> copyToClipboard(String text) async {
  try {
    await web.window.navigator.clipboard.writeText(text).toDart;
  } catch (_) {
    final ta = web.document.createElement('textarea') as web.HTMLTextAreaElement;
    ta.value = text;
    web.document.body!.append(ta);
    ta.select();
    web.document.execCommand('copy');
    ta.remove();
  }
}
