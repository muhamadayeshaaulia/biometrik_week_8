import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/biometric_service.dart';
import '../services/biometric_exception.dart';

enum _AuthMethod { face, fingerprint, password }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final BiometricService _service = BiometricService();

  _AuthMethod? _activeMethod;  // null = halaman pemilihan metode
  bool _isLoading = false;
  String? _errorMessage;
  BiometricErrorCode? _errorCode;
  List<_AuthMethod> _availableMethods = [];  // diisi saat initState

  // Animasi 'berdenyut' saat menunggu respons biometrik
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);  // otomatis bolak-balik

  late final Animation<double> _pulseAnim = Tween(begin: 1.0, end: 1.12).animate(
    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    _init();  // Panggil async, jangan await di initState
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final available = await _service.isBiometricAvailable();
    final types = await _service.getAvailableBiometrics();

    // Tentukan metode yang tersedia berdasarkan BiometricType
    // Android face  → BiometricType.weak
    // iOS Face ID   → BiometricType.face
    // Fingerprint   → BiometricType.fingerprint atau BiometricType.strong
    final hasFace = types.contains(BiometricType.face) ||
        types.contains(BiometricType.weak);
    final hasFingerprint = types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.strong);

    final methods = <_AuthMethod>[];
    if (available && hasFace) methods.add(_AuthMethod.face);
    if (available && hasFingerprint) methods.add(_AuthMethod.fingerprint);
    // Password selalu tersedia
    methods.add(_AuthMethod.password);

    setState(() {
      _availableMethods = methods;
    });
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorCode = null;
    });

    try {
      await _service.authenticate();
      // Autentikasi berhasil — navigasi ke halaman utama
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autentikasi berhasil!')),
        );
      }
    } on BiometricException catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleError(BiometricException e) {
    setState(() {
      _errorMessage = e.userMessage;
      _errorCode = e.code;
      // Jika error membutuhkan fallback (lockout permanen / tidak ada hardware),
      // otomatis pindah ke form password
      if (e.requiresFallback) _activeMethod = _AuthMethod.password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon biometrik dengan animasi denyut
              ScaleTransition(
                scale: _isLoading
                    ? _pulseAnim
                    : const AlwaysStoppedAnimation(1.0),
                child: Icon(
                  _activeMethod == _AuthMethod.face
                      ? Icons.face
                      : Icons.fingerprint,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Tampilkan error jika ada
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Tombol-tombol metode autentikasi
              ..._availableMethods.map((method) {
                final icon = switch (method) {
                  _AuthMethod.face => Icons.face,
                  _AuthMethod.fingerprint => Icons.fingerprint,
                  _AuthMethod.password => Icons.lock,
                };
                final label = switch (method) {
                  _AuthMethod.face => 'Face ID',
                  _AuthMethod.fingerprint => 'Sidik Jari',
                  _AuthMethod.password => 'Password',
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() => _activeMethod = method);
                              if (method != _AuthMethod.password) {
                                _authenticate();
                              }
                            },
                      icon: Icon(icon),
                      label: Text(label),
                    ),
                  ),
                );
              }),

              // Tombol buka pengaturan jika biometrik belum terdaftar
              if (_errorCode != null &&
                  BiometricException(
                    code: _errorCode!,
                    userMessage: '',
                  ).requiresSettings)
                TextButton(
                  onPressed: () {
                    // Buka pengaturan biometrik OS
                  },
                  child: const Text('Buka Pengaturan'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
