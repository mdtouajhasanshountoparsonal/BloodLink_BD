import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_user.dart';
import '../models/blood_list_entry.dart';
import '../models/blood_request.dart';
import '../models/donor.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/blood_list_service.dart';
import '../services/contact_service.dart';
import '../services/location_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/request_card.dart';
import '../widgets/section_header.dart';
import 'blood_list_screen.dart';
import 'new_request_screen.dart';
import 'nearby_requests_screen.dart';
import 'donors_screen.dart';
import 'notifications_screen.dart';
import 'request_detail_screen.dart';
import 'requests_screen.dart';

void _goNearbyRequests(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const NearbyRequestsScreen()));
}

void _goBloodList(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const BloodListScreen()));
}

double _kmOf(BloodRequest r, double lat, double lng) {
  if (r.latitude == null || r.longitude == null) return double.infinity;
  return LocationService.instance.distanceKm(
    lat,
    lng,
    r.latitude!,
    r.longitude!,
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await AuthService.instance.currentUser();
    if (mounted) setState(() => _user = u);
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
                _Header(
                  user: _user,
                  onNotifications: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const _EmergencyHero(),
                const SizedBox(height: 20),
                _StatsRow(user: _user),
                const SizedBox(height: 26),
                SectionHeader(
                  title: 'রক্তদাতা তালিকা',
                  actionLabel: 'সব দেখুন',
                  onAction: () => _goBloodList(context),
                ),
                const SizedBox(height: 12),
                _BloodListPreview(),
                const SizedBox(height: 26),
                SectionHeader(
                  title: 'কাছের রিকোয়েস্ট',
                  actionLabel: 'সব দেখুন',
                  onAction: () => _goNearbyRequests(context),
                ),
                const SizedBox(height: 12),
                StreamBuilder(
                  stream: RequestService.instance.requestsStream(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }
                    final all = snap.data ?? const <BloodRequest>[];
                    final my = _user;
                    final ulat = my?.latitude;
                    final ulng = my?.longitude;
                    final list = all.take(3).toList();
                    if (ulat != null && ulng != null) {
                      list.sort(
                        (a, b) => (_kmOf(
                          a,
                          ulat,
                          ulng,
                        )).compareTo(_kmOf(b, ulat, ulng)),
                      );
                    }
                    if (list.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'এখনো কোনো রিকোয়েস্ট নেই',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final r in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RequestCard(
                              request: r,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RequestDetailScreen(request: r),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                const SectionHeader(title: 'ডোনেশন স্ট্যাটাস'),
                const SizedBox(height: 12),
                _DonationStatusCard(user: _user),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, this.onNotifications});

  final AppUser? user;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'ডোনার';
    final letter = name.characters.firstOrNull?.toUpperCase() ?? 'D';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'আসসালামু আলাইকুম',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _GlassCircle(
          onTap: onNotifications,
          child: const Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_none_rounded, size: 23),
              Positioned(right: -2, top: -4, child: _Badge()),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 46,
          height: 46,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: AppColors.critical,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.bg, width: 1.6),
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _EmergencyHero extends StatelessWidget {
  const _EmergencyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5470), Color(0xFFC4001D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'রক্তের প্রয়োজন?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Emergency রিকোয়েস্ট পাঠান, আশপাশের সঠিক ডোনার খুঁজুন',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GlassButton(
            label: 'Emergency Request',
            icon: Icons.add_alert_rounded,
            textColor: const Color(0xFFC4001D),
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFE8E8E8)],
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const NewRequestScreen())),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatefulWidget {
  const _StatsRow({this.user});

  final AppUser? user;

  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  List<Donor> _donors = const [];
  List<BloodRequest> _requests = const [];
  StreamSubscription? _sub1;
  StreamSubscription? _sub2;

  @override
  void initState() {
    super.initState();
    _sub1 = RequestService.instance.donorsStream().listen((list) {
      debugPrint('HOME donorsStream: ${list.length} জন ডোনার');
      if (mounted) setState(() => _donors = list);
    });
    _sub2 = RequestService.instance.requestsStream().listen((list) {
      debugPrint('HOME requestsStream: ${list.length}টি সক্রিয়');
      if (mounted) setState(() => _requests = list);
    });
  }

  @override
  void dispose() {
    _sub1?.cancel();
    _sub2?.cancel();
    super.dispose();
  }

  int get _active =>
      _donors.where((d) => d.status == DonorStatus.available).length;

  int get _nearby {
    final u = widget.user;
    final active = _donors.where((d) => d.status == DonorStatus.available);
    final ulat = u?.latitude;
    final ulng = u?.longitude;
    if (ulat == null || ulng == null) return active.length;
    return active.where((d) {
      final dLat = d.latitude;
      final dLng = d.longitude;
      if (dLat == null || dLng == null) return false;
      return LocationService.instance.distanceKm(ulat, ulng, dLat, dLng) <= 10;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    void go(Widget screen) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            number: '$_active',
            label: 'সক্রিয় ডোনার',
            color: AppColors.primary,
            onTap: () => go(const DonorsScreen()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            number: '${_requests.length}',
            label: 'বর্তমান রিকোয়েস্ট',
            color: AppColors.urgent,
            onTap: () => go(const RequestsScreen()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            number: '$_nearby',
            label: 'কাছের ডোনার',
            color: AppColors.info,
            onTap: () => go(const DonorsScreen()),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.number,
    required this.label,
    required this.color,
    this.onTap,
  });

  final String number;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      onTap: onTap,
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DonationStatusCard extends StatelessWidget {
  const _DonationStatusCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final last = user?.lastDonation;
    final donations = user?.donations ?? 0;
    final now = DateTime.now();
    final hadDonation = last != null;

    final daysElapsed = hadDonation ? now.difference(last).inDays : 0;
    final eligible = !hadDonation || daysElapsed >= 90;
    final daysLeft = eligible ? 0 : 90 - daysElapsed;
    final nextDate = hadDonation ? last.add(const Duration(days: 90)) : null;
    final progress = hadDonation ? (daysElapsed / 90).clamp(0.0, 1.0) : 0.0;

    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'শেষ ডোনেশন',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hadDonation ? _bnDate(last) : 'এখনো কোনো ডোনেশন হয়নি',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: eligible
                    ? [
                        const Text(
                          'প্রস্তুত ✓',
                          style: TextStyle(
                            color: AppColors.normal,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ডোনেশন: $donations বার',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ]
                    : [
                        Text(
                          '$daysLeft দিন বাকি',
                          style: const TextStyle(
                            color: AppColors.urgent,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'পরবর্তী: ${_bnDate(nextDate!)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceHigh,
              color: eligible ? AppColors.normal : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _bnDate(DateTime t) {
    const months = [
      '',
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];
    return '${t.day} ${months[t.month]} ${t.year}';
  }
}

class _BloodListPreview extends StatefulWidget {
  const _BloodListPreview();

  @override
  State<_BloodListPreview> createState() => _BloodListPreviewState();
}

class _BloodListPreviewState extends State<_BloodListPreview> {
  ({List<String> admins, List<String> managers})? _roles;

  @override
  void initState() {
    super.initState();
    AdminService.instance.fetchRoles().then((r) {
      if (mounted) setState(() => _roles = r);
    });
  }

  String? _roleOf(String uid) {
    final r = _roles;
    if (r == null || uid.isEmpty) return null;
    if (r.admins.contains(uid)) return 'admin';
    if (r.managers.contains(uid)) return 'manager';
    return null;
  }

  Future<void> _call(String phone) async {
    await launchUrl(ContactService.instance.callUri(phone));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BloodListEntry>>(
      stream: BloodListService.instance.entriesStream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }
        final list = snap.data ?? const <BloodListEntry>[];
        if (list.isEmpty) {
          return const GlassCard(
            padding: EdgeInsets.all(16),
            child: Text(
              'এখনো কেউ যুক্ত হয়নি — ম্যানেজার/অ্যাডমিন নাম-নম্বর যোগ করবেন।',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          );
        }
        return Column(
          children: [
            for (final e in list.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PreviewRow(
                  entry: e,
                  role: _roleOf(e.addedBy),
                  onCall: _call,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.entry, required this.onCall, this.role});

  final BloodListEntry entry;
  final String? role;
  final Future<void> Function(String phone) onCall;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final (roleLabel, roleColor, roleIcon) = switch (role) {
      'admin' => ('অ্যাডমিন', AppColors.gold, Icons.shield_outlined),
      'manager' => (
        'ম্যানেজার',
        AppColors.info,
        Icons.admin_panel_settings_outlined,
      ),
      _ => (null, null, null),
    };
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _goBloodList(context),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              e.name.trim().isEmpty ? '?' : e.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (e.verified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.normal,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (roleLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(roleIcon, size: 11, color: roleColor),
                        const SizedBox(width: 4),
                        Text(
                          roleLabel,
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  e.area.isEmpty ? e.bloodGroup : '${e.area} · ${e.bloodGroup}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              e.bloodGroup,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (e.phones.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onCall(e.phones.first),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.normal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.phone_in_talk,
                  color: AppColors.normal,
                  size: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
