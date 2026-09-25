import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_user.dart';
import '../models/blood_list_entry.dart';
import '../models/blood_request.dart';
import '../models/donor.dart';
import '../services/auth_service.dart';
import '../services/blood_list_service.dart';
import '../services/contact_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../utils/blood_compat.dart';
import '../utils/match_score.dart';
import '../widgets/background_decor.dart';
import '../widgets/blood_group_chip.dart';
import '../widgets/donor_card.dart';
import 'blood_list_screen.dart';
import 'chat_screen.dart';
import 'donor_profile_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.request});

  final BloodRequest request;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  AppUser? _user;
  BloodRequest? _request;
  List<RequestResponse> _responses = const [];
  StreamSubscription<BloodRequest>? _sub;
  StreamSubscription<List<RequestResponse>>? _respSub;
  StreamSubscription<Donor?>? _cdSub;
  String? _confirmedDonorName;
  bool _busy = false;
  bool _fulfillFired = false;
  bool _waOk = false;

  @override
  void initState() {
    super.initState();
    _load();
    ContactService.instance.whatsappInstalled().then((ok) {
      if (mounted) setState(() => _waOk = ok);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _respSub?.cancel();
    _cdSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final u = await AuthService.instance.currentUser();
    if (mounted) setState(() => _user = u);
    // রিকোয়েস্টের live অবস্থা (মেয়াদ শেষ হলে অটো আপডেট)
    _sub = RequestService.instance.requestStream(widget.request.id).listen((r) {
      if (!mounted) return;
      RequestService.instance.expireIfOverdue(r);
      if (r.confirmedDonor != null &&
          r.confirmedDonor!.isNotEmpty &&
          _confirmedDonorName == null) {
        _cdSub = RequestService.instance
            .userStreamByUid(r.confirmedDonor!)
            .listen((d) {
              if (mounted && d != null) {
                setState(() => _confirmedDonorName = d.name);
              }
            });
      }
      setState(() => _request = r);
    });
    _respSub = RequestService.instance
        .responsesStream(widget.request.id)
        .listen((list) {
          if (!mounted) return;
          setState(() => _responses = list);
          // ব্যাগের চাহিদা পূরণ হলে রিকোয়েস্ট 'fulfilled' করে দিই
          if (!_r.isClosed && !_fulfillFired) {
            final confirmed = list.where((x) => x.status == 'donate').length;
            if (confirmed >= _r.bags) {
              _fulfillFired = true;
              RequestService.instance.fulfill(_r.id);
            }
          }
        });
  }

  BloodRequest get _r => _request ?? widget.request;

  int get _confirmed => _responses.where((x) => x.status == 'donate').length;

  Future<void> _respond(String status) async {
    final user = _user;
    if (user == null || _busy) return;
    if (_r.isExpired) {
      _toast('এই রিকোয়েস্টের মেয়াদ শেষ হয়ে গেছে');
      return;
    }
    setState(() => _busy = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      await RequestService.instance.respond(
        requestId: widget.request.id,
        uid: user.uid,
        name: user.name,
        bloodGroup: user.bloodGroup,
        status: status,
        phone: user.phone,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == 'donate'
                ? 'ধন্যবাদ! হাসপাতালে জানান দেওয়া হবে'
                : 'আপনার সাড়া দেওয়া হয়েছে',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সাড়া পাঠানো ব্যর্থ হয়েছে')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rebroadcast() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await RequestService.instance.rebroadcast(
        _r.id,
        BloodRequest.lifetimeFor(_r.urgency),
      );
      if (mounted) {
        _toast('রিকোয়েস্ট পুনরায় সক্রিয় করা হয়েছে');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('পুনরায় পাঠানো ব্যর্থ হয়েছে')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// মালিক নিজেই 'রক্ত সম্পন্ন' চিহ্নিত করে রিকোয়েস্ট বন্ধ করা
  Future<void> _closeRequest() async {
    if (_busy || _r.isClosed) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('রক্ত সম্পন্ন হয়েছে?'),
        content: const Text(
          'আপনি কি নিশ্চিত রক্ত পাওয়া গেছে? রিকোয়েস্ট বন্ধ হয়ে যাবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'না',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'হ্যাঁ, সম্পন্ন',
              style: TextStyle(
                color: AppColors.normal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await RequestService.instance.closeRequest(_r.id);
      _toast('রিকোয়েস্ট বন্ধ করা হয়েছে');
    } catch (_) {
      _toast('ব্যর্থ হয়েছে, আবার চেষ্টা করুন');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// মালিক একজন ডোনারকে কনফার্ম করলে ডোনারের প্রোফাইলে রেকর্ড চলে যায়
  Future<void> _confirmDonor(RequestResponse donor) async {
    if (_busy || _r.isClosed || _r.confirmedDonor != null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${donor.name} কনফার্ম করবেন?'),
        content: Text(
          'রক্ত দেওয়ার পর ${donor.name}-এর প্রোফাইলে ১টি ডোনেশন রেকর্ড হয়ে যাবে এবং রিকোয়েস্ট বন্ধ হবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'বাতিল',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'কনফার্ম',
              style: TextStyle(
                color: AppColors.normal,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final r = _r;
    setState(() => _busy = true);
    try {
      await RequestService.instance.confirmDonation(
        requestId: r.id,
        donorUid: donor.uid,
        donorGroup: donor.bloodGroup,
        patientName: r.patientName,
        hospital: r.hospital,
      );
      _toast('${donor.name} কনফার্ম হয়েছে, রেকর্ড সেভ হয়েছে');
    } catch (_) {
      _toast('কনফার্ম ব্যর্থ হয়েছে। আবার চেষ্টা করুন');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openProfile(String uid) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DonorProfileScreen(donorUid: uid)),
    );
  }

  Future<void> _openChat() {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          requestId: widget.request.id,
          title: 'রোগী: ${widget.request.patientName}',
        ),
      ),
    );
  }

  Future<void> _callDonor(Donor d) async {
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

  Future<void> _waTo(String phone, {String? text}) async {
    if (phone.isEmpty) return;
    final ok = await ContactService.instance.openWhatsapp(phone, text: text);
    if (!ok) _toast('WhatsApp খোলা যায়নি');
  }

  Future<void> _roCall(BloodListEntry e) async {
    if (e.phones.isEmpty) return;
    final ok = await launchUrl(ContactService.instance.callUri(e.phones.first));
    if (!ok) _toast('কল খোলা যায়নি');
  }

  Future<void> _roWa(BloodListEntry e) async {
    if (e.phones.isEmpty) return;
    await _waTo(e.phones.first, text: 'রক্ত দরকার: ${_r.patientName}');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;

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
                      'রিকোয়েস্টের বিস্তারিত',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'ডোনারদের সাথে চ্যাট',
                      onPressed: _openChat,
                      icon: const Icon(Icons.chat_bubble_outline, size: 21),
                      color: AppColors.info,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _hero(r, _confirmed),
                      if (r.isExpired) ...[
                        const SizedBox(height: 12),
                        _expiryBanner(r),
                      ],
                      if (r.isFulfilled) ...[
                        const SizedBox(height: 12),
                        _fulfilledBanner(r),
                      ],
                      const SizedBox(height: 16),
                      _infoCard(r),
                      const SizedBox(height: 16),
                      _responsesSection(),
                      const SizedBox(height: 22),
                      StreamBuilder(
                        stream: RequestService.instance.donorsStream(),
                        builder: (context, snap) {
                          final all = snap.data ?? const <Donor>[];
                          final matches =
                              all
                                  .map(
                                    (d) => _SmartEntry(
                                      donor: d,
                                      score: MatchScorer.compute(
                                        receiverGroup: r.bloodGroup,
                                        donorGroup: d.bloodGroup,
                                        distanceKm: d.distanceKm,
                                        available:
                                            d.status == DonorStatus.available,
                                        verified: d.verified,
                                        donations: d.donations,
                                      ),
                                    ),
                                  )
                                  .where((e) => e.score.compatible)
                                  .toList()
                                ..sort(
                                  (a, b) =>
                                      b.score.total.compareTo(a.score.total),
                                );

                          if (matches.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.bolt,
                                    color: AppColors.gold,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'স্মার্ট ম্যাচ',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${r.bloodGroup} জন্য সেরা ডোনার',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              for (final e in matches.take(3))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GestureDetector(
                                    onTap: () => _openProfile(e.donor.uid),
                                    child: DonorCard(
                                      donor: e.donor,
                                      score: e.score.total,
                                      onCall: () => _callDonor(e.donor),
                                      onChat: _openChat,
                                      onWhatsApp:
                                          _waOk &&
                                              e.donor.phone.isNotEmpty &&
                                              e.donor.showPhone
                                          ? () => _waTo(
                                              e.donor.phone,
                                              text:
                                                  'রক্ত দরকার: ${r.patientName}',
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _rosterSuggestions(r),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rosterSuggestions(BloodRequest r) {
    return StreamBuilder<List<BloodListEntry>>(
      stream: BloodListService.instance.entriesStream(),
      builder: (context, snap) {
        final all = snap.data ?? const <BloodListEntry>[];
        final compatible =
            BloodCompat.compatibleDonorsFor[r.bloodGroup] ?? const [];
        final matches = all
            .where((e) => compatible.contains(e.bloodGroup))
            .take(3)
            .toList();
        if (matches.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.format_list_numbered_rounded,
                  color: AppColors.info,
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Text(
                  'রক্তদাতা তালিকা থেকে পরামর্শ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 10),
              child: Text(
                '${r.bloodGroup} (কম্প্যাটিবল) — ভেরিফাইড প্রথমে',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ),
            for (final e in matches)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SuggestedRosterTile(
                  entry: e,
                  onCall: () => _roCall(e),
                  onWa: _waOk ? () => _roWa(e) : null,
                  onViewAll: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BloodListScreen()),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _hero(BloodRequest r, int confirmed) {
    final ratio = (confirmed / r.bags).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [r.urgency.color, r.urgency.color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: r.urgency.color.withValues(alpha: 0.35),
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
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  r.bloodGroup,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.patientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${r.bags} ব্যাগ প্রয়োজন • ${_fmtDateTime(r.neededBy)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop,
                  color: confirmed >= r.bags ? AppColors.normal : Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  confirmed >= r.bags
                      ? 'ব্যাগ পূর্ণ ✓'
                      : '$confirmed/${r.bags} ব্যাগ রিজার্ভড',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: confirmed >= r.bags ? AppColors.normal : Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  r.urgency.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${r.responseCount} জন সাড়া দিয়েছেন',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _responsesSection() {
    final r = _r;
    final donors = _responses.where((x) => x.isDonors).toList();
    final my = _user == null
        ? null
        : _responses.where((x) => x.uid == _user!.uid).firstOrNull;
    final isOwner = _user != null && r.uid.isNotEmpty && r.uid == _user!.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'আপনার প্রতিক্রিয়া',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${donors.length} জন ডোনার',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _actionButtons(my?.status, enabled: !r.isClosed),
        if (isOwner && !r.isClosed) ...[
          const SizedBox(height: 12),
          _ownerActions(),
        ],
        if (donors.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'যাঁরা সাড়া দিয়েছেন',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final d in donors.take(8))
            _ResponderTile(
              response: d,
              requestId: r.id,
              requestTitle: 'রোগী: ${r.patientName}',
              isOwner: isOwner && !r.isClosed,
              canConfirm: d.status == 'donate' && r.confirmedDonor == null,
              waAvailable: _waOk,
              onConfirm: () => _confirmDonor(d),
              onTapProfile: () => _openProfile(d.uid),
              onWhatsApp: () => _waTo(
                d.phone,
                text: 'রক্ত দরকার: ${r.patientName} — BloodLink',
              ),
            ),
        ],
      ],
    );
  }

  /// রিকোয়েস্ট মালিকের কন্ট্রোল — 'রক্ত সম্পন্ন' চিহ্নিতকরণ
  Widget _ownerActions() {
    return GestureDetector(
      onTap: _busy ? null : _closeRequest,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.normal, width: 1.5),
          color: AppColors.normal.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 18,
              color: AppColors.normal,
            ),
            const SizedBox(width: 8),
            Text(
              _busy ? 'হচ্ছে...' : 'রক্ত সম্পন্ন — রিকোয়েস্ট বন্ধ করুন',
              style: const TextStyle(
                color: AppColors.normal,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fulfilledBanner(BloodRequest r) {
    final name = _confirmedDonorName;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.normal.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.normal.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.normal,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'রক্ত পাওয়া গেছে — ধন্যবাদ!',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
                if (name != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'ডোনার: $name',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _expiryBanner(BloodRequest r) {
    final amOwner = _user != null && r.isMine && r.uid == _user!.uid;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.critical.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.critical.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer_off_rounded,
                color: AppColors.critical,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'এই রিকোয়েস্টের মেয়াদ শেষ হয়ে গেছে',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            r.rebroadcastCount > 0
                ? '${r.rebroadcastCount} বার পুনরায় পাঠানো হয়েছে'
                : 'আর সাড়া দেওয়া যাবে না',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
          if (amOwner) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _busy ? null : _rebroadcast,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.critical,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _busy ? 'পাঠানো হচ্ছে...' : 'পুনরায় পাঠান',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard(BloodRequest r) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _row(Icons.local_hospital_outlined, 'হাসপাতাল', r.hospital),
          const SizedBox(height: 12),
          _row(
            Icons.place_outlined,
            'এলাকা',
            '${r.area} • ${r.distanceKm.toStringAsFixed(1)} km',
          ),
          const SizedBox(height: 12),
          _row(Icons.bloodtype_outlined, 'রক্তের গ্রুপ', r.bloodGroup),
          if (r.requesterName.isNotEmpty) ...[
            const SizedBox(height: 12),
            _row(Icons.person_outline, 'রিকোয়েস্টকর্তা', r.requesterName),
          ],
          if (r.requesterPhone.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _contactBig(
                    icon: Icons.call_rounded,
                    color: AppColors.normal,
                    label: 'রিকোয়েস্টকর্তাকে কল',
                    onTap: () => _callRequester(r),
                  ),
                ),
                if (_waOk) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _contactBig(
                      icon: Icons.chat_rounded,
                      color: AppColors.normal,
                      label: 'WhatsApp',
                      onTap: () => _waTo(
                        r.requesterPhone,
                        text: 'রক্ত দরকার: ${r.patientName} — BloodLink',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactBig({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 1.3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callRequester(BloodRequest r) async {
    if (r.requesterPhone.isEmpty) return;
    final ok = await launchUrl(Uri(scheme: 'tel', path: r.requesterPhone));
    if (!ok) _toast('কল খোলা যায়নি');
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _actionButtons(String? myStatus, {required bool enabled}) {
    return Row(
      children: [
        _respButton(
          'donate',
          'ডোনেট করব',
          Icons.favorite_rounded,
          AppColors.normal,
          myStatus == 'donate',
          enabled,
        ),
        const SizedBox(width: 10),
        _respButton(
          'maybe',
          'হয়তো',
          Icons.help_outline_rounded,
          AppColors.urgent,
          myStatus == 'maybe',
          enabled,
        ),
        const SizedBox(width: 10),
        _respButton(
          'cant',
          'পারব না',
          Icons.close_rounded,
          AppColors.critical,
          myStatus == 'cant',
          enabled,
        ),
      ],
    );
  }

  Widget _respButton(
    String status,
    String label,
    IconData icon,
    Color color,
    bool active,
    bool enabled,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: (enabled && !_busy) ? () => _respond(status) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? color : AppColors.border,
              width: active ? 1.6 : 1,
            ),
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Column(
              children: [
                Icon(
                  icon,
                  color: active ? color : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? color : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDateTime(DateTime t) {
    return '${t.day}/${t.month}/${t.year} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

class _SmartEntry {
  const _SmartEntry({required this.donor, required this.score});

  final Donor donor;
  final MatchScore score;
}

class _ResponderTile extends StatelessWidget {
  const _ResponderTile({
    required this.response,
    required this.requestId,
    required this.requestTitle,
    this.isOwner = false,
    this.canConfirm = false,
    this.waAvailable = false,
    this.onConfirm,
    this.onTapProfile,
    this.onWhatsApp,
  });

  final RequestResponse response;
  final String requestId;
  final String requestTitle;
  final bool isOwner;
  final bool canConfirm;
  final bool waAvailable;
  final VoidCallback? onConfirm;
  final VoidCallback? onTapProfile;
  final VoidCallback? onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final color = response.status == 'donate'
        ? AppColors.normal
        : AppColors.urgent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTapProfile,
            child: BloodGroupChip(group: response.bloodGroup, compact: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onTapProfile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    response.status == 'donate' ? 'ডোনেট করবেন' : 'হয়তো',
                    style: TextStyle(
                      color: color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOwner && canConfirm) ...[
            GestureDetector(
              onTap: onConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.normal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.normal, width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 15,
                      color: AppColors.normal,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'কনফার্ম',
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
            const SizedBox(width: 8),
          ],
          if (response.phone.isNotEmpty)
            _RoundAction(
              icon: Icons.phone_in_talk,
              color: AppColors.normal,
              onTap: () async {
                final ok = await launchUrl(
                  ContactService.instance.callUri(response.phone),
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('কল খোলা যায়নি')),
                    );
                }
              },
            ),
          if (waAvailable && response.phone.isNotEmpty) ...[
            const SizedBox(width: 8),
            _RoundAction(
              icon: Icons.chat_rounded,
              color: AppColors.normal,
              onTap: onWhatsApp,
            ),
          ],
          const SizedBox(width: 8),
          _RoundAction(
            icon: Icons.chat_bubble_outline,
            color: AppColors.info,
            tooltip: 'মেসেজ (লক করা আছে)',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ChatScreen(requestId: requestId, title: requestTitle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

class _SuggestedRosterTile extends StatelessWidget {
  const _SuggestedRosterTile({
    required this.entry,
    required this.onCall,
    required this.onViewAll,
    this.onWa,
  });

  final BloodListEntry entry;
  final VoidCallback onCall;
  final VoidCallback? onWa;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              e.name.trim().isEmpty ? '?' : e.name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.info,
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
          GestureDetector(
            onTap: onCall,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
          if (onWa != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onWa,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: AppColors.info,
                  size: 16,
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
