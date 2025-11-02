import 'dart:typed_data';

String seedToPrivateKey(Uint8List seed) {
  return seed
      .sublist(0, 32)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}
