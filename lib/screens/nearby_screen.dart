import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_user.dart';
import '../models/donor.dart';
import '../services/auth_service.dart';
import '../services/contact_service.dart';
import '../services/location_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../utils/blood_compat.dart';
import '../utils/match_score.dart';
import '../widgets/background_decor.dart';
import '../widgets/blood_group_chip.dart';
import '../widgets/donor_card.dart';

import 'package:url_launcher/url_launcher.dart';

import 'donor_profile_screen.dart';
import 'donors_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  static const _cumilla = LatLng(23.4607, 91.1809);

  AppUser? _user;
  Position? _pos;
  String _filter = 'কম্প্যাটিবল';
  String _sort = 'কাছের';
  List<Donor> _donors = const [];
  StreamSubscription? _sub;
  bool _waOk = false;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = RequestService.instance.donorsStream().listen((list) {
      if (mounted) setState(() => _donors = list);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    ContactService.instance.whatsappInstalled().then((ok) {
      if (mounted) setState(() => _waOk = ok);
    });
    final user = await AuthService.instance.currentUser();
    if (user == null) return;
    final pos = await LocationService.instance.currentPosition();
    if (pos != null) {
      await AuthService.instance.updateLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    }
    if (mounted) {
      setState(() {
        _user = user;
        if (pos != null) _pos = pos;
      });
    }
  }

  bool _compatible(Donor d) {
    final group = _user?.bloodGroup ?? 'O+';
    return BloodCompat.canDonateTo(
      donorGroup: d.bloodGroup,
      receiverGroup: group,
    );
  }

  double _distanceOf(Donor d) {
    final my = _pos;
    if (my != null && d.latitude != null && d.longitude != null) {
      return LocationService.instance.distanceKm(
        my.latitude,
        my.longitude,
        d.latitude!,
        d.longitude!,
      );
    }
    return d.distanceKm;
  }

  List<Donor> get _visible {
    final donors = _donors.where((d) {
      if (d.uid.isNotEmpty && d.uid == _user?.uid) return false;
      if (d.status != DonorStatus.available) return false;
      return !(_filter == 'কম্প্যাটিবল' && !_compatible(d));
    }).toList();
    if (_sort == 'স্কোর') {
      donors.sort((a, b) => _scoreOf(b).total.compareTo(_scoreOf(a).total));
    } else {
      donors.sort((a, b) => _distanceOf(a).compareTo(_distanceOf(b)));
    }
    return donors;
  }

  MatchScore _scoreOf(Donor d) => MatchScorer.compute(
    receiverGroup: _user?.bloodGroup ?? 'O+',
    donorGroup: d.bloodGroup,
    distanceKm: _distanceOf(d),
    available: d.status == DonorStatus.available,
    verified: d.verified,
    donations: d.donations,
  );

  Future<void> _call(Donor d) async {
    if (!d.showPhone) {
      _toast('এই ডোনার নম্বর লুকিয়ে রেখেছেন');
      return;
    }
    if (d.phone.isEmpty) {
      _toast('এই ডোনারের নম্বর পাওয়া যায়নি');
      return;
    }
    final ok = await launchUrl(ContactService.instance.callUri(d.phone));
    if (!ok) _toast('কল খোলা যায়নি');
  }

  Future<void> _whatsApp(Donor d) async {
    if (d.phone.isEmpty) {
      _toast('এই ডোনারের নম্বর পাওয়া যায়নি');
      return;
    }
    final ok = await ContactService.instance.openWhatsapp(
      d.phone,
      text: 'রক্ত দরকার — BloodLink',
    );
    if (!ok) _toast('WhatsApp খোলা যায়নি');
  }

  void _openProfile(String uid) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DonorProfileScreen(donorUid: uid)),
    );
  }

  void _openDonors() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DonorsScreen()));
  }

  Widget _filterPill({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundDecor(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'কাছের ডোনার',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _pos == null
                      ? 'লোকেশন অন করতে হলে আসল দূরত্ব দেখাবে'
                      : 'আপনার লোকেশন অনুযায়ী কাছের ডোনার',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                _mapCard(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ডোনার',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterPill(
                      onTap: _openDonors,
                      icon: Icons.search_rounded,
                      color: AppColors.gold,
                      label: 'সব ডোনার খুঁজুন',
                    ),
                    _filterPill(
                      onTap: () => setState(() {
                        _sort = _sort == 'কাছের' ? 'স্কোর' : 'কাছের';
                      }),
                      icon: Icons.swap_vert,
                      color: AppColors.info,
                      label: _sort == 'কাছের'
                          ? 'কাছে সবচেয়ে নিকট'
                          : 'স্মার্ট ম্যাচ ⚡',
                    ),
                    _filterPill(
                      onTap: () => setState(() {
                        _filter = _filter == 'কম্প্যাটিবল'
                            ? 'সবাই'
                            : 'কম্প্যাটিবল';
                      }),
                      icon: Icons.bloodtype_outlined,
                      color: AppColors.primary,
                      label: _filter == 'কম্প্যাটিবল'
                          ? '${_user?.bloodGroup ?? 'O+'} কম্প্যাটিবল ✓'
                          : 'সবাই',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _visible.isEmpty
                      ? const Center(
                          child: Text(
                            'কম্প্যাটিবল ডোনার এখনো পাওয়া যায়নি',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _visible.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final d = _visible[i];
                            return DonorCard(
                              donor: Donor(
                                uid: d.uid,
                                name: d.name,
                                bloodGroup: d.bloodGroup,
                                distanceKm: _distanceOf(d),
                                status: d.status,
                                donations: d.donations,
                                verified: d.verified,
                                phone: d.phone,
                                showPhone: d.showPhone,
                              ),
                              score: _filter == 'কম্প্যাটিবল'
                                  ? _scoreOf(d).total
                                  : null,
                              onCall: () => _call(d),
                              onTap: () => _openProfile(d.uid),
                              onChat: () => _toast(
                                'চ্যাট করতে রিকোয়েস্ট ডিটেইল খুলুন — সেখানে ডোনারদের সাথে যুক্ত হন',
                              ),
                              onWhatsApp: _waOk && d.showPhone
                                  ? () => _whatsApp(d)
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mapCard() {
    final center = _pos == null
        ? _cumilla
        : LatLng(_pos!.latitude, _pos!.longitude);

    final donors = _visible
        .where((d) => d.latitude != null && d.longitude != null)
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 260,
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bloodlink.bloodlink_bd',
              retinaMode: false,
            ),
            MarkerLayer(
              markers: [
                for (final d in donors)
                  Marker(
                    point: LatLng(d.latitude!, d.longitude!),
                    width: 40,
                    height: 44,
                    child: _donorMarker(d.bloodGroup),
                  ),
                if (_pos != null)
                  Marker(
                    point: LatLng(_pos!.latitude, _pos!.longitude),
                    width: 44,
                    height: 44,
                    child: _youMarker(),
                  ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _donorMarker(String group) {
    final color = BloodGroupChip.colorOf(group);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.16),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            group,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _youMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.info, Color(0xFF29B6F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.info.withValues(alpha: 0.5),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.navigation_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
