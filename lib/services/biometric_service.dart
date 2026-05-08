import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

import 'biometric_exception.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    final bool canCheck = await _auth.canCheckBiometrics;  // Ada sensor?
    final bool isSupported = await _auth.isDeviceSupported(); // Device mendukung?
    return canCheck && isSupported;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _auth.getAvailableBiometrics();
    // Mengembalikan list: [BiometricType.fingerprint, BiometricType.face, ...]
    // BiometricType.weak = face Android (2D), BiometricType.strong = fingerprint/iris
  }

  Future<bool> authenticate({String reason = 'Verifikasi identitas Anda'}) async {
    final bool available = await isBiometricAvailable();
    if (!available) {
      throw const BiometricException(
        code: BiometricErrorCode.noBiometricHardware,
        userMessage: 'Perangkat tidak memiliki sensor biometrik.',
      );
    }

    final List<BiometricType> types = await getAvailableBiometrics();
    if (types.isEmpty) {
      throw const BiometricException(
        code: BiometricErrorCode.notEnrolled,
        userMessage: 'Belum ada sidik jari tersimpan. Daftarkan di Pengaturan.',
      );
    }
    try {
      final bool result = await _auth.authenticate(
        localizedReason: reason,           // Teks yang muncul di dialog
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Verifikasi Diperlukan',
            cancelButton: 'Batal',
            signInHint: 'Tempelkan jari atau arahkan wajah',
          ),
        ],
        biometricOnly: false,              // false = izinkan fallback PIN/pattern OS
        sensitiveTransaction: true,        // true = tidak izinkan face 2D (Class 2)
        persistAcrossBackgrounding: true,  // dialog tetap muncul setelah app di-background
      );
      if (!result) {
        throw const BiometricException(
          code: BiometricErrorCode.userCanceled,
          userMessage: 'Autentikasi dibatalkan.',
        );
      }

      return true;
    } on LocalAuthException catch (e) {
      throw BiometricException.fromLocalAuthException(e);
    }
  }
}
