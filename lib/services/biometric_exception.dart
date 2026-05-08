import 'package:local_auth/local_auth.dart';

enum BiometricErrorCode {
  noBiometricHardware,
  notEnrolled,
  temporaryLockout,
  biometricLockout,
  userCanceled,
  systemCanceled,
  unknown,
}

class BiometricException implements Exception {
  final BiometricErrorCode code;
  final String message;
  final String userMessage;

  const BiometricException({
    required this.code,
    this.message = '',
    required this.userMessage,
  });

  factory BiometricException.fromLocalAuthException(LocalAuthException e) {
    switch (e.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
        return BiometricException(
          code: BiometricErrorCode.noBiometricHardware,
          message: e.description ?? 'No biometric hardware',
          userMessage: 'Perangkat tidak memiliki sensor biometrik.',
        );
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return BiometricException(
          code: BiometricErrorCode.notEnrolled,
          message: e.description ?? 'No biometrics enrolled',
          userMessage: 'Belum ada sidik jari tersimpan. Daftarkan di Pengaturan.',
        );
      case LocalAuthExceptionCode.temporaryLockout:
        return BiometricException(
          code: BiometricErrorCode.temporaryLockout,
          message: e.description ?? 'Temporary lockout',
          userMessage: 'Terlalu banyak percobaan gagal. Coba lagi nanti.',
        );
      case LocalAuthExceptionCode.biometricLockout:
        return BiometricException(
          code: BiometricErrorCode.biometricLockout,
          message: e.description ?? 'Biometric lockout',
          userMessage: 'Biometrik terkunci. Gunakan PIN/password untuk membuka.',
        );
      case LocalAuthExceptionCode.userCanceled:
        return BiometricException(
          code: BiometricErrorCode.userCanceled,
          message: e.description ?? 'User canceled',
          userMessage: 'Autentikasi dibatalkan.',
        );
      case LocalAuthExceptionCode.systemCanceled:
        return BiometricException(
          code: BiometricErrorCode.systemCanceled,
          message: e.description ?? 'System canceled',
          userMessage: 'Autentikasi dibatalkan oleh sistem.',
        );
      default:
        return BiometricException(
          code: BiometricErrorCode.unknown,
          message: e.description ?? 'Unknown error',
          userMessage: 'Terjadi kesalahan. Silakan coba lagi.',
        );
    }
  }

  bool get isRetryable =>
      code == BiometricErrorCode.userCanceled ||
      code == BiometricErrorCode.systemCanceled ||
      code == BiometricErrorCode.unknown;

  // Tampilkan tombol "Buka Pengaturan"?
  bool get requiresSettings => code == BiometricErrorCode.notEnrolled;

  // Otomatis pindah ke form password?
  bool get requiresFallback =>
      code == BiometricErrorCode.noBiometricHardware ||
      code == BiometricErrorCode.biometricLockout;

  @override
  String toString() => 'BiometricException($code): $userMessage';
}