import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordHasher {
  PasswordHasher._();

  static const _salt = 'du_xuan_2026_local';

  static String sha256Hash(String input) {
    final bytes = utf8.encode('$_salt:$input');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
