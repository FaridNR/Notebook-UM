import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final AppState appState;

  const SettingsScreen({
    super.key,
    required this.appState,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _deleteConfirmController = TextEditingController();
  bool _canDelete = false;

  @override
  void dispose() {
    _deleteConfirmController.dispose();
    super.dispose();
  }

  void _onExportJson(BuildContext context) {
    final jsonStr = widget.appState.exportDataAsJson();
    Clipboard.setData(ClipboardData(text: jsonStr));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data JSON berhasil disalin ke clipboard!'),
        backgroundColor: const Color(0xFF090A0C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.appState.displayName);
    final nimController = TextEditingController(text: widget.appState.nim);
    final prodiController = TextEditingController(text: widget.appState.prodi);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil Mahasiswa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                hintText: 'Farid Noor Rahman',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nimController,
              decoration: const InputDecoration(
                labelText: 'NIM',
                hintText: '2411001',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: prodiController,
              decoration: const InputDecoration(
                labelText: 'Program Studi / Kelas',
                hintText: 'S1 Informatika • IFB5J',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newNim = nimController.text.trim();
              final newProdi = prodiController.text.trim();
              widget.appState.updateProfile(
                displayName: newName.isNotEmpty ? newName : null,
                nim: newNim.isNotEmpty ? newNim : null,
                prodi: newProdi.isNotEmpty ? newProdi : null,
              );
              Navigator.pop(ctx);
              widget.appState.showToast('Profil mahasiswa berhasil diperbarui');
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showTimezonePicker(BuildContext context) {
    final timezones = [
      {'id': 'Asia/Makassar', 'label': 'Asia/Makassar (WITA, UTC+8)'},
      {'id': 'Asia/Jakarta', 'label': 'Asia/Jakarta (WIB, UTC+7)'},
      {'id': 'Asia/Jayapura', 'label': 'Asia/Jayapura (WIT, UTC+9)'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih Zona Waktu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...timezones.map((tz) {
                final isSelected = widget.appState.timezone == tz['id'];
                return ListTile(
                  title: Text(tz['label']!, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                  trailing: isSelected ? const Icon(Icons.check, size: 20) : null,
                  onTap: () {
                    widget.appState.updateProfile(timezone: tz['id']);
                    Navigator.pop(ctx);
                    widget.appState.showToast('Zona waktu diubah ke ${tz['id']}');
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus seluruh data jadwal dan tugas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              widget.appState.clearAllData();
              Navigator.pop(ctx);
              setState(() {
                _deleteConfirmController.clear();
                _canDelete = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seluruh data berhasil dihapus')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgCard = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final insetTone = isDark ? AppColors.darkSurfaceStep : AppColors.lightSurfaceStep;

    final initials = widget.appState.displayName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .take(2)
        .join();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Header
            Container(
              color: bgCard,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Preferensi & Sinkronisasi Akun',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),

            // Main Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                children: [
                  // Digital KTM Card (Universitas Mulia Student Artifact)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131826) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark ? const Color(0xFF263248) : const Color(0xFF334155),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KTM Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    'assets/images/logo_um.png',
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Text(
                                      'UM',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'UNIVERSITAS MULIA',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'KARTU TANDA MAHASISWA DIGITAL',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                'AKTIF',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF34D399),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Main Info Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFBBF24), width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials.isNotEmpty ? initials : 'FNR',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.appState.displayName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'NIM: ${widget.appState.nim}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFBBF24),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.appState.prodi,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showEditProfileDialog(context),
                              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF94A3B8)),
                              tooltip: 'Edit Profil',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Barcode Strip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: List.generate(24, (i) {
                                  final isThick = (i % 3 == 0 || i % 7 == 0);
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                    width: isThick ? 2.5 : 1.2,
                                    height: 16,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  );
                                }),
                              ),
                              Text(
                                '${widget.appState.nim} • WITA',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Section 1: Zona Waktu & Sinkronisasi
                  Container(
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Zona Waktu & Sinkronisasi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Item 1: Timezone
                        GestureDetector(
                          onTap: () => _showTimezonePicker(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: insetTone,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Zona Waktu Aktif',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${widget.appState.timezone} (UTC+8)',
                                      style: TextStyle(fontSize: 11, color: textSecondary),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Ganti',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.blueAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.chevron_right, size: 16, color: textSecondary),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Section 2: Notifikasi & Tampilan
                  Container(
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Notifikasi & Tampilan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Item 1: Pengingat H-24
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: insetTone,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pengingat H-24 Jam',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Notifikasi 1 hari sebelum batas pengumpulan', style: TextStyle(fontSize: 10, color: textSecondary)),
                                ],
                              ),
                              CupertinoSwitch(
                                value: widget.appState.isReminderH24,
                                activeTrackColor: const Color(0xFF10B981),
                                onChanged: (val) => widget.appState.toggleReminderH24(),
                              ),
                            ],
                          ),
                        ),

                        // Item 2: Pengingat H-1
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: insetTone,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pengingat H-1 Jam',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Notifikasi mendesak sebelum jam tenggat', style: TextStyle(fontSize: 10, color: textSecondary)),
                                ],
                              ),
                              CupertinoSwitch(
                                value: widget.appState.isReminderH1,
                                activeTrackColor: const Color(0xFF10B981),
                                onChanged: (val) => widget.appState.toggleReminderH1(),
                              ),
                            ],
                          ),
                        ),

                        // Item 3: Mode Gelap
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: insetTone,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mode Gelap (OLED Black)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Latar belakang gelap hemat baterai', style: TextStyle(fontSize: 10, color: textSecondary)),
                                ],
                              ),
                              CupertinoSwitch(
                                value: isDark,
                                activeTrackColor: const Color(0xFF10B981),
                                onChanged: (val) => widget.appState.toggleTheme(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Section 3: Cadangan Data
                  Container(
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Cadangan Data',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: insetTone,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ekspor File JSON Lengkap',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.appState.totalCourses} Matkul, ${widget.appState.totalSlots} Slot, ${widget.appState.tasks.length} Tugas',
                                    style: TextStyle(fontSize: 10, color: textSecondary),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => _onExportJson(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFFF4F4F5) : const Color(0xFF090A0C),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.download_rounded,
                                        size: 13,
                                        color: isDark ? const Color(0xFF090A0C) : Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ekspor JSON',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFF090A0C) : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Section 4: Akun & Sesi
                  Container(
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Sesi Akun',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            widget.appState.logout();
                          },
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: insetTone,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, size: 16, color: textPrimary),
                                const SizedBox(width: 8),
                                Text(
                                  'Keluar dari Akun',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Section 5: Danger Zone (PRD Section 1.5 Flow F)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.roseDarkBg : AppColors.roseLightBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zona Berbahaya',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.roseTextDark : AppColors.roseAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tindakan permanen. Seluruh data mata kuliah, jadwal mingguan, dan tugas akan dihapus dari penyimpanan perangkat.',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ketik kata "HAPUS" untuk konfirmasi:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF121316) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _deleteConfirmController,
                            onChanged: (val) {
                              setState(() {
                                _canDelete = val.trim() == 'HAPUS';
                              });
                            },
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE11D48),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'HAPUS',
                              hintStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _canDelete ? () => _showDeleteDialog(context) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE11D48),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFFE11D48).withValues(alpha: 0.35),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Hapus Permanen Seluruh Data',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
