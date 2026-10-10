import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:hamyon/core/error/failures.dart';
import 'package:path_provider/path_provider.dart';

class SecureVault {
  SecureVault._(this._file);

  factory SecureVault.forDirectory(Directory directory) =>
      SecureVault._(File('${directory.path}/hamyon_vault.dat'));

  static Future<SecureVault> create() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return SecureVault.forDirectory(directory);
  }

  static const int _iterations = 210000;
  static const int _saltLength = 16;
  static const int _nonceLength = 12;

  final File _file;
  final AesGcm _cipher = AesGcm.with256bits();
  final Hmac _hmac = Hmac.sha256();
  final Pbkdf2 _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: 512,
  );

  List<int>? _encryptionKey;
  List<int>? _signingKey;
  Future<void> _queue = Future.value();

  Future<bool> exists() => _file.exists();
  bool get isUnlocked => _encryptionKey != null && _signingKey != null;

  Future<void> createNew(String pin) async {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      throw const ValidationFailure('PIN aynan 4 ta raqamdan iborat bo‘lsin');
    }
    if (await exists()) {
      throw const StorageFailure('Hamyon allaqachon yaratilgan');
    }
    final salt = _randomBytes(_saltLength);
    final keys = await _deriveKeys(pin, salt);
    _encryptionKey = keys.$1;
    _signingKey = keys.$2;
    await _writeEnvelope(_emptyDatabase(), salt);
  }

  Future<bool> unlock(String pin) async {
    if (!await exists()) return false;
    try {
      final envelope = await _readEnvelope();
      final salt = base64Decode(envelope['salt']! as String);
      final keys = await _deriveKeys(pin, salt);
      await _decrypt(envelope, keys.$1);
      _encryptionKey = keys.$1;
      _signingKey = keys.$2;
      return true;
    } on SecretBoxAuthenticationError {
      return false;
    } on FormatException {
      throw const IntegrityFailure();
    }
  }

  Future<bool> verifyPin(String pin) async {
    if (!await exists()) return false;
    try {
      final envelope = await _readEnvelope();
      final salt = base64Decode(envelope['salt']! as String);
      final keys = await _deriveKeys(pin, salt);
      await _decrypt(envelope, keys.$1);
      return true;
    } on SecretBoxAuthenticationError {
      return false;
    } on FormatException {
      throw const IntegrityFailure();
    }
  }

  void lock() {
    _encryptionKey = null;
    _signingKey = null;
  }

  Future<Map<String, dynamic>> read() =>
      _serialized(() async => Map<String, dynamic>.from(await _readUnlocked()));

  Future<T> mutate<T>(FutureOr<T> Function(Map<String, dynamic> database) action) =>
      _serialized(() async {
        final database = await _readUnlocked();
        final result = await action(database);
        final envelope = await _readEnvelope();
        final salt = base64Decode(envelope['salt']! as String);
        await _writeEnvelope(database, salt);
        return result;
      });

  Future<String> sign(String payload) async {
    final key = _signingKey;
    if (key == null) throw const AuthenticationFailure('Hamyon qulflangan');
    final mac = await _hmac.calculateMac(
      utf8.encode(payload),
      secretKey: SecretKey(key),
    );
    return base64Encode(mac.bytes);
  }

  Future<bool> verifySignature(String payload, String signature) async {
    try {
      final actual = await sign(payload);
      final a = base64Decode(actual);
      final b = base64Decode(signature);
      if (a.length != b.length) return false;
      var difference = 0;
      for (var i = 0; i < a.length; i++) {
        difference |= a[i] ^ b[i];
      }
      return difference == 0;
    } on FormatException {
      return false;
    }
  }

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<Map<String, dynamic>> _readUnlocked() async {
    final key = _encryptionKey;
    if (key == null) throw const AuthenticationFailure('Hamyon qulflangan');
    try {
      return await _decrypt(await _readEnvelope(), key);
    } on SecretBoxAuthenticationError {
      throw const IntegrityFailure();
    } on FormatException {
      throw const IntegrityFailure();
    }
  }

  Future<Map<String, dynamic>> _readEnvelope() async {
    try {
      return Map<String, dynamic>.from(
        jsonDecode(await _file.readAsString()) as Map,
      );
    } on FileSystemException catch (error) {
      throw StorageFailure('Faylni o‘qib bo‘lmadi: ${error.message}');
    }
  }

  Future<Map<String, dynamic>> _decrypt(
    Map<String, dynamic> envelope,
    List<int> key,
  ) async {
    if (envelope['version'] != 1) {
      throw const FormatException('Noma’lum vault versiyasi');
    }
    final box = SecretBox(
      base64Decode(envelope['ciphertext']! as String),
      nonce: base64Decode(envelope['nonce']! as String),
      mac: Mac(base64Decode(envelope['tag']! as String)),
    );
    final clearBytes = await _cipher.decrypt(box, secretKey: SecretKey(key));
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(clearBytes)) as Map);
  }

  Future<void> _writeEnvelope(
    Map<String, dynamic> database,
    List<int> salt,
  ) async {
    final key = _encryptionKey;
    if (key == null) throw const AuthenticationFailure('Hamyon qulflangan');
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(database)),
      secretKey: SecretKey(key),
      nonce: _randomBytes(_nonceLength),
    );
    final envelope = <String, dynamic>{
      'version': 1,
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': _iterations,
      'cipher': 'AES-256-GCM',
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'tag': base64Encode(box.mac.bytes),
    };
    await _file.parent.create(recursive: true);
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(jsonEncode(envelope), flush: true);
    try {
      await temporary.rename(_file.path);
    } on FileSystemException {
      if (await _file.exists()) await _file.delete();
      await temporary.rename(_file.path);
    }
  }

  Future<(List<int>, List<int>)> _deriveKeys(
    String pin,
    List<int> salt,
  ) async {
    final key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    final bytes = await key.extractBytes();
    return (bytes.sublist(0, 32), bytes.sublist(32, 64));
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  Map<String, dynamic> _emptyDatabase() => <String, dynamic>{
        'schemaVersion': 1,
        'cards': <Map<String, dynamic>>[],
        'transactions': <Map<String, dynamic>>[],
      };
}
