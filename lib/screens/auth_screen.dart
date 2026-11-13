import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final AppState appState;

  const AuthScreen({
    super.key,
    required this.appState,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _authMode = 0; // 0: Masuk / Login, 1: Registrasi

  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  static final _nimRegex = RegExp(r'^[0-9]{6,12}$');

  // Login controllers (Akun bawaan default)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Register controllers
  final _regNameController = TextEditingController();
  final _regNimController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _obscureRegConfirm = true;

  String? _errorMessage;
  int _failedLoginAttempts = 0;
  DateTime? _lockoutUntil;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.appState.userEmail;
    _passwordController.text = widget.appState.userPassword;
    _regNameController.text = widget.appState.displayName;
    _regNimController.text = widget.appState.nim;
    _regEmailController.text = widget.appState.userEmail;
    _regPasswordController.text = widget.appState.userPassword;
    _regConfirmPasswordController.text = widget.appState.userPassword;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regNimController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    // Cek status penguncian brute force
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final remainingSec = _lockoutUntil!.difference(DateTime.now()).inSeconds + 1;
      setState(() {
        _errorMessage = 'Terlalu banyak percobaan gagal. Akses dikunci sementara selama $remainingSec detik.';
      });
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Masukkan alamat email yang valid (contoh: nama@mhs.ac.id)';
      });
      return;
    }

    if (password.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Kata sandi tidak boleh kosong atau hanya berisi spasi';
      });
      return;
    }

    if (password.length < 10) {
      setState(() {
        _errorMessage = 'Kata sandi minimal 10 karakter sesuai standar keamanan PRD';
      });
      return;
    }

    // Validasi kecocokan kredensial dengan database lokal
    final isValid = widget.appState.verifyCredentials(email, password);
    if (!isValid) {
      _failedLoginAttempts++;
      if (_failedLoginAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
        setState(() {
          _errorMessage = 'Terlalu banyak percobaan gagal. Akses dikunci sementara selama 30 detik.';
        });
      } else {
        setState(() {
          _errorMessage = 'Email atau kata sandi salah. Silakan periksa kembali.';
        });
      }
      return;
    }

    // Reset percobaan jika login berhasil
    _failedLoginAttempts = 0;
    _lockoutUntil = null;

    setState(() {
      _errorMessage = null;
    });

    widget.appState.login(email, password);
    widget.appState.showToast('Selamat datang di NoteBook UM, ${widget.appState.displayName}');
  }

  void _submitRegister() {
    final name = _regNameController.text.trim();
    final nim = _regNimController.text.trim();
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text;
    final confirm = _regConfirmPasswordController.text;

    if (name.isEmpty || name.length < 3) {
      setState(() {
        _errorMessage = 'Nama lengkap mahasiswa minimal 3 karakter';
      });
      return;
    }

    if (nim.isEmpty || !_nimRegex.hasMatch(nim)) {
      setState(() {
        _errorMessage = 'NIM harus berupa angka valid (6–12 digit, contoh: 2411001)';
      });
      return;
    }

    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Masukkan alamat email yang valid (contoh: nama@mhs.ac.id)';
      });
      return;
    }

    if (password.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Kata sandi tidak boleh kosong atau hanya berisi spasi';
      });
      return;
    }

    if (password.length < 10) {
      setState(() {
        _errorMessage = 'Kata sandi minimal 10 karakter sesuai standar keamanan PRD';
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _errorMessage = 'Konfirmasi kata sandi tidak cocok dengan kata sandi';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    // Peringatan jika mendaftarkan email berbeda dengan akun saat ini
    if (widget.appState.userEmail.isNotEmpty &&
        widget.appState.userEmail.trim().toLowerCase() != email.toLowerCase()) {
      _confirmOverwriteAccount(name, email, password, nim);
      return;
    }

    _executeRegister(name, email, password, nim);
  }

  void _confirmOverwriteAccount(String name, String email, String password, String nim) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ganti Akun Perangkat?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(
          'Perangkat ini saat ini terhubung dengan akun ${widget.appState.userEmail}. Mendaftar akun baru ($email) akan menggantikan profil akun utama di perangkat ini. Lanjutkan?',
          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeRegister(name, email, password, nim);
            },
            child: const Text('Ya, Ganti Akun'),
          ),
        ],
      ),
    );
  }

  void _executeRegister(String name, String email, String password, String nim) {
    widget.appState.register(
      name: name,
      email: email,
      password: password,
      nim: nim,
      prodi: 'S1 Informatika • IFB5J',
    );

    // Sinkronkan controller login agar langsung siap dipakai
    _emailController.text = email;
    _passwordController.text = password;

    widget.appState.showToast('Akun $name ($nim) berhasil didaftarkan!');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final inputBg = isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Brand Logo
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : const Color(0xFF090A0C),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'UM',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF090A0C) : Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      _authMode == 0 ? 'Masuk ke NoteBook UM' : 'Registrasi Akun NoteBook UM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      _authMode == 0
                          ? 'Aplikasi Catatan Tugas & Jadwal Kuliah Real-Time'
                          : 'Daftarkan akun mahasiswa untuk sinkronisasi jadwal & tugas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Segmented Switcher (Masuk vs Registrasi)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _authMode = 0;
                                  _errorMessage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _authMode == 0
                                      ? (isDark ? AppColors.darkSurface : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _authMode == 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _authMode == 0 ? textPrimary : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _authMode = 1;
                                  _errorMessage = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _authMode == 1
                                      ? (isDark ? AppColors.darkSurface : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _authMode == 1
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Registrasi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _authMode == 1 ? textPrimary : textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Form Container Card
                    Container(
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.roseDarkBg : AppColors.roseLightBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.roseTextDark : AppColors.roseText,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (_authMode == 0) ...[
                            // LOGIN MODE
                            Text(
                              'Email Mahasiswa',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'faridnoorrahman@gmail.com',
                                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            Text(
                              'Kata Sandi (Min. 10 Karakter)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submitLogin(),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0542411640',
                                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      size: 18,
                                      color: textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            GestureDetector(
                              onTap: _submitLogin,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white : const Color(0xFF090A0C),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Masuk ke Akun',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF090A0C) : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            // REGISTER MODE
                            Text(
                              'Nama Lengkap',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _regNameController,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Farid Noor Rahman',
                                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'NIM (Nomor Induk Mahasiswa)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _regNimController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: '2411001',
                                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Email Mahasiswa',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _regEmailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'faridnoorrahman@gmail.com',
                                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Kata Sandi (Min. 10 Karakter)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _regPasswordController,
                                obscureText: _obscureRegPassword,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Minimal 10 karakter...',
                                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureRegPassword ? Icons.visibility_off : Icons.visibility,
                                      size: 18,
                                      color: textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureRegPassword = !_obscureRegPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Konfirmasi Kata Sandi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: inputBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                controller: _regConfirmPasswordController,
                                obscureText: _obscureRegConfirm,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submitRegister(),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ulangi kata sandi...',
                                  hintStyle: TextStyle(fontSize: 13, color: textSecondary),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureRegConfirm ? Icons.visibility_off : Icons.visibility,
                                      size: 18,
                                      color: textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureRegConfirm = !_obscureRegConfirm;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            GestureDetector(
                              onTap: _submitRegister,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white : const Color(0xFF090A0C),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Daftar Akun Baru',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF090A0C) : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Info footnote
                    Text(
                      _authMode == 0
                          ? 'Akun resmi mahasiswa IFB5J Universitas Mulia'
                          : 'Data akun tersimpan aman di database lokal SQLite perangkat Anda',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
