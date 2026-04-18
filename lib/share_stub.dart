import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const _cloudName = 'dyqxanbmx';
const _uploadPreset = 'shot-together';
const _baseUrl = 'https://shot-together-hjp.web.app';

Future<List<Uint8List>?> parseSharedPhotos() async => null;

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
      throw Exception('Upload failed [${res.statusCode}]: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    ids.add(json['public_id'] as String);
  }

  final encoded = base64Url.encode(utf8.encode(ids.join(',')));
  return '$_baseUrl#share=$encoded';
}

Future<void> copyToClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}
