import 'dart:convert';

class AppEncryption {
  AppEncryption._();

  // A secure static key for encryption/decryption
  static final List<int> _key = utf8.encode("AccountManagerSec2026Key#KeepItPrivate!");

  /// Encrypts plain text string and returns a base64 encoded string
  static String encrypt(String plainText) {
    final List<int> plainBytes = utf8.encode(plainText);
    final List<int> cipherBytes = _rc4(plainBytes);
    return base64.encode(cipherBytes);
  }

  /// Decrypts a base64 encoded cipher text and returns the plain text string
  static String decrypt(String base64CipherText) {
    final List<int> cipherBytes = base64.decode(base64CipherText);
    final List<int> plainBytes = _rc4(cipherBytes);
    return utf8.decode(plainBytes);
  }

  /// Helper to perform RC4 crypt
  static List<int> _rc4(List<int> data) {
    List<int> s = List<int>.generate(256, (index) => index);
    int j = 0;
    for (int i = 0; i < 256; i++) {
      j = (j + s[i] + _key[i % _key.length]) % 256;
      int temp = s[i];
      s[i] = s[j];
      s[j] = temp;
    }

    List<int> out = List<int>.filled(data.length, 0);
    int x = 0;
    int y = 0;
    for (int k = 0; k < data.length; k++) {
      x = (x + 1) % 256;
      y = (y + s[x]) % 256;
      int temp = s[x];
      s[x] = s[y];
      s[y] = temp;
      int t = (s[x] + s[y]) % 256;
      out[k] = data[k] ^ s[t];
    }
    return out;
  }
}
