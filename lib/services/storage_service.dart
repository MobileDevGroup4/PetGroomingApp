import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    final originalBytes = await file.readAsBytes();
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      throw Exception('Unsupported image format');
    }
    const maxEdge = 600;
    final resized = img.copyResize(decoded,
        width: decoded.width >= decoded.height ? maxEdge : null,
        height: decoded.height > decoded.width ? maxEdge : null,
        interpolation: img.Interpolation.cubic);
    final jpgBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));

    final id = const Uuid().v4();
    final path = 'profilePhotos/$uid/$id.jpg';

    final ref = _storage.ref().child(path);
    await ref.putData(jpgBytes, SettableMetadata(contentType: 'image/jpeg'));

    return await ref.getDownloadURL();
  }
}