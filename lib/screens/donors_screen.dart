import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/donor.dart';
import '../services/contact_service.dart';
import '../services/location_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/blood_group_chip.dart';
import 'donor_profile_screen.dart';

class DonorsScreen extends StatefulWidget {
  const DonorsScreen({super.key, this.initialGroup});

  final String? initialGroup;

  @override
  State<DonorsScreen> createState() => _DonorsScreenState();
}

class _DonorsScreenState extends State<DonorsScreen> {
  static const _groups = ['সব', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  String _group = 'সব';
  final _searchCtrl = TextEditingController();
  String _query = '';
  List<Donor> _donors = const [];
  Position? _pos;
  String? _error;
  bool _waOk = false;

  late final int _initialIndex;

  @override
  void initState() {
    super.initState();
    final g = widget.initialGroup;
    _initialIndex = g == null ? 0 : _groups.indexOf(g);
    if (_initialIndex > 0) _group = g!;
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    ContactService.instance.whatsappInstalled().then((ok) {
      if (mounted) setState(() => _waOk = ok);
    });
    final pos = await LocationService.instance.currentPosition();
    if (mounted) {
      setState(() => _pos = pos);
    }
    RequestService.instance.donorsStream().listen(
      (list) {
        debugPrint('donorsStream: ${list.length} জন ডোনার');
        if (mounted) {
          setState(() {
            _donors = list;
            _error = null;
          });
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('donorsStream error: $e');
        if (mounted) setState(() => _error = e.toString());
      },
    );
  }

  double _dist(Donor d) {
    final my = _pos;
    if (my != null && d.latitude != null && d.longitude != null) {
      return LocationService.instance
          .distanceKm(my.latitude, my.longitude, d.latitude!, d.longitude!);
    }
    return d.distanceKm;
  }

  List<Donor> get _filtered {
    var list = List<Donor>.from(_donors);
    if (_group != 'সব') {
      list = list.where((d) => d.bloodGroup == _group).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((d) => d.name.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) {
      if (_pos != null) return _dist(a).compareTo(_dist(b));
      return b.donations.compareTo(a.donations);
    });
    return list;
  }

  Future<void> _call(Donor d) async {
    if (!d.showPhone) {
      _toast('এই ডোনার নম্বর লুকিয়ে রেখেছেন');
      return;
    }
    if (d.phone.isEmpty) {
      _toast('নম্বর পাওয়া যায়নি');
      return;
    }
    final ok = await launchUrl(ContactService.instance.callUri(d.phone));
    if (!ok) _toast('কল খোলা যায়নি');
  }

  Future<void> _whatsApp(Donor d) async {
    if (d.phone.isEmpty) {
      _toast('নম্বর পাওয়া যায়নি');
      return;
    }
    final ok = await ContactService.instance
        .openWhatsapp(d.phone, text: 'রক্ত দরকার — BloodLink');
    if (!ok) _toast('WhatsApp খোলা যায়নি');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BackgroundDecor(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text('ডোনার খুঁজুন', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 19, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: const InputDecoration(
                            hintText: 'নাম দিয়ে খুঁজুন...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _groups.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final g = _groups[i];
                    final sel = g == _group;
                    return GestureDetector(
                      onTap: () => setState(() => _group = g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            color: sel ? Colors.white : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${list.length} জন ডোনার পাওয়া গেছে',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 8),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.critical.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.critical, width: 1),
                    ),
                    child: const Text(
                      'তথ্য আনতে সমস্যা হচ্ছে (limit/rules)। ইন্টারনেট ও লগইন চেক করে আবার চেষ্টা করুন।',
                      style: TextStyle(color: AppColors.critical, fontSize: 12.5),
                    ),
                  ),
                ),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            'মেলে এমন ডোনার নেই\n\nডোনার হিসেবে রেজিস্টার করা ইউজাররা এখানে দেখাবে। রক্ত দিতে রেজিস্টার করলে তালিকায় যোগ হবেন।',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, height: 1.6),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) => _donorTile(list[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _donorTile(Donor d) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DonorProfileScreen(donorUid: d.uid),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            BloodGroupChip(group: d.bloodGroup),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          d.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (d.verified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${d.donations} বার ডোনেট ${_hasPos(d) ? '• ${_dist(d).toStringAsFixed(1)} km' : ''}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
            if (d.showPhone && d.phone.isNotEmpty) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _call(d),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.normal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.normal, width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_in_talk, size: 15, color: AppColors.normal),
                      SizedBox(width: 6),
                      Text(
                        'যোগাযোগ',
                        style: TextStyle(
                          color: AppColors.normal,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_waOk) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _whatsApp(d),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.normal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.normal, width: 1.2),
                    ),
                    child: const Icon(Icons.chat_rounded, size: 17, color: AppColors.normal),
                  ),
                ),
              ],
            ] else
              const Icon(Icons.phone_disabled, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  bool _hasPos(Donor d) =>
      _pos != null && d.latitude != null && d.longitude != null;
}