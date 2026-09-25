import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/blood_request.dart';
import '../services/location_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/blood_group_chip.dart';
import 'request_detail_screen.dart';

/// কাছের রিকোয়েস্ট — দূরত্ব অনুযায়ী সাজানো, রিকোয়েস্টকর্তার সাথে সরাসরি যোগাযোগ
class NearbyRequestsScreen extends StatefulWidget {
  const NearbyRequestsScreen({super.key});

  @override
  State<NearbyRequestsScreen> createState() => _NearbyRequestsScreenState();
}

class _NearbyRequestsScreenState extends State<NearbyRequestsScreen> {
  Position? _pos;
  List<BloodRequest> _requests = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pos = await LocationService.instance.currentPosition();
    if (mounted) {
      setState(() => _pos = pos);
    }
    RequestService.instance.requestsStream().listen(
      (list) {
        debugPrint('requestsStream (nearby): ${list.length}টি সক্রিয়');
        if (mounted) {
          setState(() {
            _requests = list;
            _loading = false;
            _error = null;
          });
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('requestsStream error: $e');
        if (mounted) {
          setState(() {
            _loading = false;
            _error = e.toString();
          });
        }
      },
    );
  }

  double? _km(BloodRequest r) {
    final my = _pos;
    if (my == null || r.latitude == null || r.longitude == null) return null;
    return LocationService.instance.distanceKm(
      my.latitude,
      my.longitude,
      r.latitude!,
      r.longitude!,
    );
  }

  List<BloodRequest> get _sorted {
    final list = List<BloodRequest>.from(_requests);
    list.sort((a, b) {
      final da = _km(a);
      final db = _km(b);
      if (da == null && db == null) {
        return _urgencyRank(a).compareTo(_urgencyRank(b));
      }
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return list;
  }

  int _urgencyRank(BloodRequest r) => switch (r.urgency) {
    Urgency.critical => 0,
    Urgency.urgent => 1,
    Urgency.normal => 2,
  };

  Future<void> _callRequester(BloodRequest r) async {
    if (r.requesterPhone.isEmpty) return;
    final ok = await launchUrl(Uri(scheme: 'tel', path: r.requesterPhone));
    if (!ok) _toast('কল খোলা যায়নি');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final list = _sorted;
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
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'কাছের রিকোয়েস্ট',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _pos == null
                      ? 'লোকেশন অন করুন — সব রিকোয়েস্ট জরুরিভিত্তিতে সাজানো হবে'
                      : 'আপনার লোকেশন থেকে আস্তে-আস্তে দূরত্ব অনুযায়ী সাজানো',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${list.length}টি সক্রিয় রিকোয়েস্ট',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.critical.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.critical, width: 1),
                    ),
                    child: const Text(
                      'রিকোয়েস্ট আনতে সমস্যা হচ্ছে (rules/limit)। ইন্টারনেট ও লগইন চেক করুন।',
                      style: TextStyle(
                        color: AppColors.critical,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: Text(
                            'এখনো কোনো সক্রিয় রিকোয়েস্ট নেই\n\nরিকোয়েস্ট করলে ৬ ঘণ্টা পর্যন্ত এখানে দেখা যাবে। রিকোয়েস্ট করার পরে অন্য ডিভাইস থেকে দেখুন।',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _nearbyCard(list[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nearbyCard(BloodRequest r) {
    final km = _km(r);
    final remaining = r.remainingLabel();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RequestDetailScreen(request: r)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: r.urgency.color.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: r.urgency.color.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BloodGroupChip(group: r.bloodGroup),
                const SizedBox(width: 10),
                if (km != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.near_me,
                          size: 12,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${km.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: AppColors.info,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: r.urgency.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    r.urgency.label,
                    style: TextStyle(
                      color: r.urgency.color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.patientName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${r.hospital} • ${r.area}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${r.bags} ব্যাগ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'বাকি $remaining',
                      style: const TextStyle(
                        color: AppColors.critical,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.requesterName.isNotEmpty
                        ? 'রিকোয়েস্টকর্তা: ${r.requesterName}'
                        : 'রিকোয়েস্টকর্তা অজানা',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (r.requesterPhone.isNotEmpty)
                  GestureDetector(
                    onTap: () => _callRequester(r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.normal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.normal, width: 1.2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.call_rounded,
                            size: 15,
                            color: AppColors.normal,
                          ),
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
                  )
                else
                  const Icon(
                    Icons.phone_disabled,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
