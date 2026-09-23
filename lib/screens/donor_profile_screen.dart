import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/donor.dart';
import '../services/contact_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/blood_group_chip.dart';

class DonorProfileScreen extends StatefulWidget {
  const DonorProfileScreen({super.key, required this.donorUid});

  final String donorUid;

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  Donor? _donor;
  bool _waOk = false;
  Stream<Donor?> _userStream = Stream<Donor?>.empty();
  Stream<List<DonationRecord>> _historyStream =
      Stream<List<DonationRecord>>.empty();

  @override
  void initState() {
    super.initState();
    _userStream = RequestService.instance.userStreamByUid(widget.donorUid);
    _historyStream =
        RequestService.instance.donationsHistoryStream(widget.donorUid);
    ContactService.instance.whatsappInstalled().then((ok) {
      if (mounted) setState(() => _waOk = ok);
    });
  }

  String _lastDonationText(DateTime? d) {
    if (d == null) return 'এখনো রক্ত দেননি';
    final days = DateTime.now().difference(d).inDays;
    if (days < 0) return 'এখনো রক্ত দেননি';
    if (days == 0) return 'আজ রক্ত দিয়েছেন';
    if (days < 60) return '$days দিন আগে';
    return '${(days / 30).floor()} মাস আগে';
  }

  String _tier(int n) => n >= 30
      ? 'প্ল্যাটিনাম ডোনার'
      : n >= 15
          ? 'গোল্ড ডোনার'
          : n >= 5
              ? 'সিলভার ডোনার'
              : 'ব্রোঞ্জ ডোনার';

  Future<void> _call() async {
    final d = _donor;
    if (d == null) return;
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

  Future<void> _whatsApp() async {
    final d = _donor;
    if (d == null) return;
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BackgroundDecor(
        child: SafeArea(
          child: StreamBuilder<Donor?>(
            stream: _userStream,
            builder: (ctx, snap) {
              final donor = snap.data ?? _donor;
              if (snap.hasError) {
                return const Center(
                  child: Text('প্রোফাইল লোড করা যায়নি',
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              if (donor == null && snap.connectionState != ConnectionState.waiting) {
                return const Center(
                  child: Text('ডোনার পাওয়া যায়নি',
                      style: TextStyle(color: AppColors.textSecondary)),
                );
              }
              _donor = donor;
              final d = donor;
              return Column(
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
                        Text('ডোনার প্রোফাইল',
                            style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: d == null
                          ? const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                  child: CircularProgressIndicator(color: AppColors.primary)),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _headerCard(d),
                                const SizedBox(height: 16),
                                _tierCard(d),
                                const SizedBox(height: 16),
                                _historyCard(),
                              ],
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _headerCard(Donor d) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDeep, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                child: Text(
                  d.name.isNotEmpty ? d.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        BloodGroupChip(group: d.bloodGroup, compact: true),
                        const SizedBox(width: 8),
                        if (d.verified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 13, color: AppColors.gold),
                                SizedBox(width: 4),
                                Text(
                                  'ভেরিফাইড',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'ভেরিফাইড নয়',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _statBox('${d.donations}', 'ডোনেশন'),
              const SizedBox(width: 10),
              _statBox(d.status == DonorStatus.available ? 'উপলব্ধ' : 'ব্যস্ত', 'অবস্থা'),
              const SizedBox(width: 10),
              _statBox(_lastDonationText(d.lastDonation).split(' ').first, 'সর্বশেষ'),
            ],
          ),
          const SizedBox(height: 16),
          if (d.showPhone && d.phone.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: _headerAction(
                    icon: Icons.phone_in_talk,
                    label: 'কল করুন',
                    onTap: _call,
                  ),
                ),
                if (_waOk) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _headerAction(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      onTap: _whatsApp,
                    ),
                  ),
                ],
              ],
            )
          else
            Container(
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                d.showPhone ? 'নম্বর দেওয়া নেই' : 'নম্বর লুকানো আছে',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tierCard(Donor d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tier(d.donations),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'এ পর্যন্ত ${d.donations} বার রক্ত দিয়েছেন; প্রতিবার রক্ত দেওয়া মানে ৩ জনের প্রাণ বাঁচানো।',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: StreamBuilder<List<DonationRecord>>(
        stream: _historyStream,
        builder: (ctx, snap) {
          if (snap.hasError) {
            return const Text(
              'ডোনেশন হিস্ট্রি দেখা যাচ্ছে না',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            );
          }
          final list = snap.data ?? const <DonationRecord>[];
          if (list.isEmpty) {
            return const Text(
              'এখনো কোনো ডোনেশন রেকর্ড নেই',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ডোনেশন হিস্ট্রি',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              for (final rec in list.take(10))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop, color: AppColors.critical, size: 17),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rec.patientName.isEmpty && rec.hospital.isEmpty
                              ? 'রক্ত দিয়েছেন'
                              : rec.hospital.isNotEmpty
                                  ? '${rec.patientName} (${rec.hospital})'
                                  : rec.patientName,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _shortDate(rec.date),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _shortDate(DateTime t) =>
      '${t.day}/${t.month}/${t.year}';
}