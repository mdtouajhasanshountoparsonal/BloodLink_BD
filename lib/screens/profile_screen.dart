import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../utils/blood_compat.dart';
import '../widgets/background_decor.dart';
import '../widgets/blood_group_chip.dart';
import '../widgets/glass_card.dart';
import 'admin_panel_screen.dart';
import 'blood_list_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_screen.dart';
import 'report_screen.dart';
import 'usage_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await AuthService.instance.currentUser();
    final admin = await AdminService.instance.isAdmin(u);
    if (mounted) {
      setState(() {
        _user = u;
        _isAdmin = admin;
      });
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('লগ আউট করবেন?'),
        content: const Text(
          'আপনি কি নিশ্চিত যে লগ আউট করতে চান?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.critical),
            child: const Text('হ্যাঁ, লগ আউট'),
          ),
        ],
      ),
    );
    if (ok == true) await AuthService.instance.signOut();
  }

  Future<void> _openEdit() async {
    final user = _user;
    if (user == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );
    if (changed == true) _load();
  }

  Future<void> _open(Widget screen) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundDecor(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(user: _user),
                const SizedBox(height: 20),
                _StatGrid(user: _user),
                const SizedBox(height: 20),
                _ReputationCard(user: _user),
                const SizedBox(height: 20),
                _DonationStatusCard(user: _user),
                const SizedBox(height: 22),
                const Text('সেটিংস', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    children: [
                      if (_isAdmin) ...[
                        _MenuTile(
                          icon: Icons.admin_panel_settings_rounded,
                          label: 'অ্যাডমিন প্যানেল',
                          onTap: () => _open(const AdminPanelScreen()),
                        ),
                        const _Divider(),
                      ],
                      _MenuTile(
                        icon: Icons.manage_accounts_outlined,
                        label: 'প্রোফাইল এডিট',
                        onTap: _openEdit,
                      ),
                      const _Divider(),
                      _MenuTile(
                        icon: Icons.lock_outline_rounded,
                        label: 'প্রাইভেসি ও নিরাপত্তা',
                        onTap: () => _open(const PrivacyScreen()),
                      ),
                      const _Divider(),
                      _MenuTile(
                        icon: Icons.notifications_none_rounded,
                        label: 'নোটিফিকেশন',
                        onTap: () => _open(const NotificationSettingsScreen()),
                      ),
                      const _Divider(),
                      _MenuTile(
                        icon: Icons.help_outline_rounded,
                        label: 'সাহায্য ও সাপোর্ট',
                        onTap: () => _open(const HelpScreen()),
                      ),
                      const _Divider(),
                      _MenuTile(
                        icon: Icons.report_problem_outlined,
                        label: 'রিপোর্ট করুন',
                        onTap: () => _open(const ReportScreen()),
                      ),
                      const _Divider(),
                      _MenuTile(
                        icon: Icons.format_list_numbered_rounded,
                        label: 'রক্তদাতা তালিকা',
                        onTap: () => _open(const BloodListScreen()),
                      ),
                      const _Divider(),
                      _MenuTile(
                        icon: Icons.data_usage_rounded,
                        label: 'ব্যবহার ও কোটা',
                        onTap: () => _open(const UsageScreen()),
                      ),
                      const _Divider(),
                      _MenuTile(
                        icon: Icons.logout_rounded,
                        label: 'লগ আউট',
                        destructive: true,
                        onTap: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'ডোনার';
    final letter = name.characters.firstOrNull?.toUpperCase() ?? 'D';
    final group = user?.bloodGroup ?? 'O+';
    final hasPhone = user?.phone != null && user!.phone.isNotEmpty;
    final area = hasPhone ? user!.phone : 'প্রোফাইল এডিটে নম্বর যুক্ত করুন';
    final verified = user?.verified ?? false;

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primarySoft, AppColors.primaryDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.border, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  area,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    BloodGroupChip(group: group, compact: true),
                    const SizedBox(width: 8),
                    Icon(
                      verified ? Icons.verified_rounded : Icons.gpp_maybe_outlined,
                      color: verified ? AppColors.info : AppColors.urgent,
                      size: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      verified ? 'ভেরিফাইড ডোনার' : 'ভেরিফাইড নয়',
                      style: TextStyle(color: verified ? AppColors.info : AppColors.urgent, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final donations = user?.donations ?? 0;
    final available = user?.available ?? true;
    final verified = user?.verified ?? false;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            number: '$donations',
            label: 'ডোনেশন',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            number: available ? 'সক্রিয়' : 'বন্ধ',
            label: 'অবস্থা',
            color: available ? AppColors.normal : AppColors.urgent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            number: verified ? 'হ্যাঁ' : 'না',
            label: 'ভেরিফাইড',
            color: verified ? AppColors.gold : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.number, required this.label, required this.color});

  final String number;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              number,
              style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DonationStatusCard extends StatelessWidget {
  const _DonationStatusCard({required this.user});

  final AppUser? user;

  static String _fmt(DateTime t) =>
      '${t.day}/${t.month}/${t.year}';

  @override
  Widget build(BuildContext context) {
    final last = user?.lastDonation;
    final win = DonationEligibility.forUser(last);
    final color = win.eligible ? AppColors.normal : AppColors.urgent;
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              win.eligible ? Icons.add_alert_rounded : Icons.schedule_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'সর্বশেষ রক্তদান: ${last == null ? 'এখনো দেননি' : _fmt(last)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                if (win.eligible)
                  const Text(
                    'এখনই রক্ত দিতে পারেন',
                    style: TextStyle(color: AppColors.normal, fontSize: 12.5, fontWeight: FontWeight.w800),
                  )
                else
                  Text(
                    'আবার পারবেন: ${_fmt(win.eligibleFrom!)} — আর ${win.remaining} দিন বাকি',
                    style: const TextStyle(color: AppColors.urgent, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReputationCard extends StatelessWidget {
  const _ReputationCard({required this.user});

  final AppUser? user;

  static const _tiers = ['ব্রোঞ্জ', 'সিলভার', 'গোল্ড', 'প্ল্যাটিনাম'];

  @override
  Widget build(BuildContext context) {
    final donations = user?.donations ?? 0;
    final (tier, progress) = _tierOf(donations);
    const needed = [0, 5, 15, 30];
    final full = donations >= 30;
    final nextTier = tier < 3 ? _tiers[tier + 1] : 'প্ল্যাটিনাম';
    final left = tier < 3 ? needed[tier + 1] - donations : 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.military_tech, color: AppColors.gold, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$tier ডোনার', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      full
                          ? 'সর্বোচ্চ সম্মান অর্জন হয়েছে — ধন্যবাদ!'
                          : '$nextTier হতে আর $left টি ডোনেশন বাকি',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceHigh,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < _tiers.length; i++)
                _TierDot(tier: _tiers[i], filled: i <= tier),
            ],
          ),
        ],
      ),
    );
  }

  (int, double) _tierOf(int d) {
    const thresholds = [0, 5, 15, 30];
    for (var i = 1; i < thresholds.length; i++) {
      if (d < thresholds[i]) {
        final start = thresholds[i - 1].toDouble();
        final end = thresholds[i].toDouble();
        return (i - 1, ((d - start) / (end - start)).clamp(0.0, 1.0));
      }
    }
    return (3, 1.0);
  }
}

class _TierDot extends StatelessWidget {
  const _TierDot({required this.tier, required this.filled});

  final String tier;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final color = filled ? AppColors.gold : AppColors.textSecondary;

    return Expanded(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: filled ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            tier,
            style: TextStyle(
              color: filled ? color : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, this.destructive = false, this.onTap});

  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.critical : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: destructive ? AppColors.critical : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right, size: 20, color: destructive ? AppColors.critical : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 46, endIndent: 12, color: AppColors.border);
  }
}