import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:muarra_app_v1/core/constants/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool soundEnabled = true;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu masuk lagi untuk mengakses aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // TODO: hapus sesi/token di sini, contoh:
    // await AuthService.signOut();
    // atau FirebaseAuth.instance.signOut();

    if (!mounted) return;
    context.go('/signin');
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111318),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Kelola akun dan preferensi aplikasi',
              style: TextStyle(fontSize: 13, color: Color(0xFF858B98)),
            ),
            const SizedBox(height: 24),

            // PROFIL
            _SectionCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 30,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administrator',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111318),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'admin@muarra.id',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF858B98),
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

            const SizedBox(height: 24),
            const _SectionLabel('AKUN'),
            _SectionCard(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profil',
                  onTap: () {
                    // TODO: navigasi ke halaman edit profil
                  },
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Ubah Password',
                  onTap: () {
                    // TODO: navigasi ke halaman ubah password
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
            const _SectionLabel('PREFERENSI'),
            _SectionCard(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifikasi',
                  trailing: Switch(
                    value: notificationsEnabled,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryColor,
                    onChanged: (v) => setState(() => notificationsEnabled = v),
                  ),
                ),
                const _TileDivider(),
                _SettingsTile(
                  icon: Icons.volume_up_outlined,
                  title: 'Suara',
                  trailing: Switch(
                    value: soundEnabled,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primaryColor,
                    onChanged: (v) => setState(() => soundEnabled = v),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const _SectionLabel('LAINNYA'),
            _SectionCard(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Tentang Aplikasi',
                  subtitle: 'Versi 1.0.0',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF858B98),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Colors.black.withValues(alpha: 0.06),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111318),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF858B98),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFB0B5C0),
                      )
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
