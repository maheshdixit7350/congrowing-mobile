import 'dart:convert';

class ChatEncryption {
  /// Encrypts plain text using the derived key from chatId.
  static String encrypt(String plainText, String chatId) {
    if (plainText.isEmpty) return '';
    try {
      final keyBytes = utf8.encode(chatId);
      final textBytes = utf8.encode(plainText);
      final rc4 = RC4(keyBytes);
      final encryptedBytes = rc4.crypt(textBytes);
      return base64.encode(encryptedBytes);
    } catch (_) {
      return plainText;
    }
  }

  /// Decrypts cipher text using the derived key from chatId.
  static String decrypt(String base64Text, String chatId) {
    if (base64Text.isEmpty) return '';
    try {
      final keyBytes = utf8.encode(chatId);
      final encryptedBytes = base64.decode(base64Text);
      final rc4 = RC4(keyBytes);
      final decryptedBytes = rc4.crypt(encryptedBytes);
      return utf8.decode(decryptedBytes);
    } catch (_) {
      return base64Text;
    }
  }
}

class RC4 {
  final List<int> _s = List<int>.generate(256, (i) => i);

  RC4(List<int> key) {
    if (key.isEmpty) return;
    int j = 0;
    for (int i = 0; i < 256; i++) {
      j = (j + _s[i] + key[i % key.length]) % 256;
      final temp = _s[i];
      _s[i] = _s[j];
      _s[j] = temp;
    }
  }

  List<int> crypt(List<int> input) {
    final s = List<int>.from(_s);
    int i = 0;
    int j = 0;
    final output = List<int>.filled(input.length, 0);
    for (int k = 0; k < input.length; k++) {
      i = (i + 1) % 256;
      j = (j + s[i]) % 256;
      final temp = s[i];
      s[i] = s[j];
      s[j] = temp;
      final t = (s[i] + s[j]) % 256;
      output[k] = input[k] ^ s[t];
    }
    return output;
  }
}
