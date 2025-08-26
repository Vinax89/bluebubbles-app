import 'package:bluebubbles/database/global/platform_file.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:universal_io/io.dart';

Future<PlatformFile?> loadPathAsFile(String path) async {
  final file = File(path);
  if (!(await file.exists())) return null;

  final bytes = await file.readAsBytes();
  return PlatformFile(
    name: basename(file.path),
    bytes: bytes,
    size: bytes.length,
    path: path,
  );
}

/// Changes the delay time of any GIF with 0 delay time.
/// https://giflib.sourceforge.net/whatsinagif/animation_and_transparency.html
Future<Uint8List> fixSpeedyGifs(Uint8List image) async {
  return await compute((image) {
    // Ensure we always have enough bytes remaining to safely access
    // [i + 4] and [i + 5]. The previous boundary check of
    // `image.length - 2` could result in a RangeError when the pattern
    // appeared near the end of the byte array.
    for (int i = 0; i < image.length - 5; i++) {
      final slice = image.sublist(i, i + 3);
      if (const ListEquality().equals(slice, [0x21, 0xF9, 0x04])) {
        final delay1 = image[i + 4];
        final delay2 = image[i + 5];
        if (delay1 == 0x00 && delay2 == 0x00) {
          image[i + 4] = 0x0A;
        }
      }
    }
    return image;
  }, image);
}