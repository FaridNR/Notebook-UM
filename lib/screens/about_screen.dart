import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  final AppState? appState;

  const AboutScreen({super.key, this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        backgroundColor: bgCard,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. App Identity Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F3F7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E384D) : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/logo_um.png',
                    width: 54,
                    height: 54,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white : const Color(0xFF090A0C),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'UM',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF090A0C) : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'NoteBook UM',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aplikasi Manajemen Catatan Tugas & Jadwal Kuliah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E384D) : const Color(0xFFBFDBFE),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Versi 1.0.0 (Build 1) • IFB5J',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Profil Mahasiswa Pengembang
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      'Informasi Akademik & Pengembang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInfoRow('Nama Mahasiswa', 'Farid Noor Rahman', textPrimary, textSecondary),
                const Divider(height: 18),
                _buildInfoRow('NIM', '2411001', textPrimary, textSecondary),
                const Divider(height: 18),
                _buildInfoRow('Program Studi', 'S1 Informatika', textPrimary, textSecondary),
                const Divider(height: 18),
                _buildInfoRow('Kelas', 'IFB5J (Malam)', textPrimary, textSecondary),
                const Divider(height: 18),
                _buildInfoRow('Perguruan Tinggi', 'Universitas Mulia Balikpapan', textPrimary, textSecondary),
                const Divider(height: 18),
                _buildInfoRow('Partner Riset PPI', 'Timor Bintang Nugraha (2411010)', textPrimary, textSecondary),
                const Divider(height: 18),
                _buildInfoRow('Dosen Pembimbing', 'Pramudya Prima Insan, S.Kom., M.Kom.', textPrimary, textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Fitur Utama & Arsitektur
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF1E2430) : const Color(0xFFE5E8EC),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.layers_outlined, size: 18, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text(
                      'Fitur Utama & Arsitektur',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFeatureBullet(
                  icon: Icons.access_time_rounded,
                  title: 'Real-time Class Tracker (WITA UTC+8)',
                  desc: 'Mendeteksi otomatis kelas yang sedang berlangsung, akan datang, atau selesai secara presisi.',
                  color: const Color(0xFFD97706),
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 10),
                _buildFeatureBullet(
                  icon: Icons.checklist_rounded,
                  title: 'Manajemen Catatan & Tugas Terhubung Sesi',
                  desc: 'Pencatatan tugas berbasis mata kuliah, deadline dinamis next session, dan filter cepat.',
                  color: const Color(0xFF2563EB),
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 10),
                _buildFeatureBullet(
                  icon: Icons.touch_app_rounded,
                  title: 'Tombol Cepat DANA Style & Floating Dock',
                  desc: 'Navigasi jempol intuitif dengan tombol sentral melayang untuk input tugas instan.',
                  color: const Color(0xFF059669),
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 10),
                _buildFeatureBullet(
                  icon: Icons.sync_alt_rounded,
                  title: 'State Management Reaktif (Provider & Consumer)',
                  desc: 'Penyegaran data terisolasi tanpa re-render penuh antarmuka.',
                  color: const Color(0xFF7C3AED),
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Copyright Footer
          Center(
            child: Text(
              '© 2026 NoteBook UM • Universitas Mulia',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textPrimary, Color textSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBullet({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
