import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Criptografia dos arquivos de backup do ZOOM.
///
/// O arquivo é protegido com o PIN do usuário usando AES-256-GCM, com a
/// chave derivada via PBKDF2-HMAC-SHA256 (salt aleatório de 16 bytes).
class BackupCrypto {
  const BackupCrypto._();

  static const int iterations = 100000;
  static const int _saltLen = 16;
  static const int _nonceLen = 12;
  static const int _keyLen = 32;
  static const int _macBits = 128;
  static final Uint8List _noAad = Uint8List(0);

  static bool isEncrypted(Map<String, dynamic> env) => env['encrypted'] == true;

  static Map<String, dynamic> encrypt(
    Map<String, dynamic> payload,
    String pin, {
    Random? random,
  }) {
    final Uint8List salt = _randomBytes(_saltLen, random);
    final Uint8List nonce = _randomBytes(_nonceLen, random);
    final Uint8List key = _deriveKey(pin, salt, iterations, _keyLen);
    final GCMBlockCipher cipher = GCMBlockCipher(AESEngine());
    cipher.init(
        true, AEADParameters(KeyParameter(key), _macBits, nonce, _noAad));
    final Uint8List plain = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    final Uint8List cipherText = cipher.process(plain);
    return <String, dynamic>{
      'encrypted': true,
      'format': 'zoom-backup',
      'version': 1,
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': iterations,
      'cipher': 'AES-256-GCM',
      'salt': base64.encode(salt),
      'iv': base64.encode(nonce),
      'data': base64.encode(cipherText),
    };
  }

  /// Retorna `null` se o PIN estiver errado ou o arquivo estiver corrompido.
  static Map<String, dynamic>? decrypt(
    Map<String, dynamic> env,
    String pin,
  ) {
    try {
      final Uint8List salt = base64.decode(env['salt'] as String);
      final Uint8List nonce = base64.decode(env['iv'] as String);
      final Uint8List data = base64.decode(env['data'] as String);
      final int iterations = (env['iterations'] as num).toInt();
      final Uint8List key = _deriveKey(pin, salt, iterations, _keyLen);
      final GCMBlockCipher cipher = GCMBlockCipher(AESEngine());
      cipher.init(
          false, AEADParameters(KeyParameter(key), _macBits, nonce, _noAad));
      final Uint8List plain = cipher.process(data);
      final Object? decoded = jsonDecode(utf8.decode(plain));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Uint8List _deriveKey(
      String pin, Uint8List salt, int iterations, int length) {
    final PBKDF2KeyDerivator derivator =
        PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(salt, iterations, length));
    return derivator.process(Uint8List.fromList(utf8.encode(pin)));
  }

  static Uint8List _randomBytes(int length, Random? random) {
    final Random source = random ?? Random.secure();
    final Uint8List bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = source.nextInt(256);
    }
    return bytes;
  }
}
