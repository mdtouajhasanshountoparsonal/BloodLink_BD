import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/blood_list_entry.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/blood_list_service.dart';
import '../services/contact_service.dart';
import '../theme/app_colors.dart';
import '../utils/blood_compat.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_card.dart';
import '../widgets/roster_swim.dart';
import 'blood_list_detail_screen.dart';

class BloodListScreen extends StatefulWidget {
  const BloodListScreen({super.key});

  @override
  State<BloodListScreen> createState() => _BloodListScreenState();
}

class _BloodListScreenState extends State<BloodListScreen> {
  bool _isAdmin = false;
  bool _isManager = false;
  bool _waOk = false;
  String _filter = 'সব';
  List<String> _adminUids = const [];
  List<String> _managerUids = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadRoles();
    ContactService.instance.whatsappInstalled().then((ok) {
      if (mounted) setState(() => _waOk = ok);
    });
  }

  Future<void> _loadRoles() async {
    final r = await AdminService.instance.fetchRoles();
    if (!mounted) return;
    setState(() {
      _adminUids = r.admins;
      _managerUids = r.managers;
    });
  }

  String? _roleOf(String uid) {
    if (uid.isEmpty) return null;
    if (_adminUids.contains(uid)) return 'admin';
    if (_managerUids.contains(uid)) return 'manager';
    return null;
  }

  Future<void> _load() async {
    final u = await AuthService.instance.currentUser();
    final admin = await AdminService.instance.isAdmin(u);
    final manager = await AdminService.instance.isManager(u);
    if (!mounted) return;
    setState(() {
      _isAdmin = admin;
      _isManager = manager;
    });
  }

  bool get _canWrite => _isAdmin || _isManager;

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _call(String phone) async {
    if (phone.isEmpty) return;
    final ok = await launchUrl(ContactService.instance.callUri(phone));
    if (!ok) _toast('কল খোলা যায়নি');
  }

  Future<void> _wa(String phone) async {
    if (phone.isEmpty) return;
    final ok = await ContactService.instance.openWhatsapp(
      phone,
      text: 'রক্ত দরকার — BloodLink',
    );
    if (!ok) _toast('WhatsApp খোলা যায়নি');
  }

  Future<void> _openAddSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddEntrySheet(),
    );
    if (mounted) _toast('রিফ্রেশ হচ্ছে…');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: _canWrite
          ? FloatingActionButton(
              onPressed: _openAddSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_add_alt_1_rounded),
            )
          : null,
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
                      'রক্তদাতা তালিকা',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _canWrite
                      ? 'নাম ও একাধিক নম্বর যোগ করুন; অ্যাডমিন ভেরিফাই করতে পারেন।'
                      : 'ব্যাজ দেখলে বোঝা যায় কে অ্যাডমিন, কে ম্যানেজার, কে ভেরিফাইড।',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _filterBar(),
              const SizedBox(height: 4),
              Expanded(
                child: StreamBuilder<List<BloodListEntry>>(
                  stream: BloodListService.instance.entriesStream(),
                  builder: (ctx, snap) {
                    if (snap.hasError) {
                      return const Center(
                        child: Text(
                          'তালিকা লোড করা যায়নি',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    final list = snap.data ?? const <BloodListEntry>[];
                    final filtered = _filter == 'সব'
                        ? list
                        : list.where((e) => e.bloodGroup == _filter).toList();
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'এখনো কেউ যোগ হয়নি',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'এই গ্রুপে কেউ নেই',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _entryCard(filtered[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterBar() {
    final groups = ['সব', ...BloodCompat.groups];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final g in groups)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = g),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _filter == g
                        ? AppColors.primary
                        : AppColors.surfaceHigh.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _filter == g
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    g,
                    style: TextStyle(
                      color: _filter == g
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _entryCard(BloodListEntry e) {
    final role = _roleOf(e.addedBy);
    final shortPhone = e.phones.isEmpty ? '' : e.phones.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        onTap: () =>
            Navigator.of(context)
                .push(bloodListEntryDetailRoute(e, role: role)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Hero(
                  tag: 'blood-avatar-${e.id}',
                  child: SwimmingAvatar(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        e.name.trim().isEmpty ? '?' : e.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          if (role == 'admin')
                            _badgeChip(
                              label: 'অ্যাডমিন',
                              color: AppColors.gold,
                              icon: Icons.shield_outlined,
                            ),
                          if (role == 'manager')
                            _badgeChip(
                              label: 'ম্যানেজার',
                              color: AppColors.info,
                              icon: Icons.admin_panel_settings_outlined,
                            ),
                          if (e.verified)
                            _badgeChip(
                              label: 'ভেরিফাইড',
                              color: AppColors.normal,
                              icon: Icons.verified_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (e.bloodGroup.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      e.bloodGroup,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.place_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    e.area.isEmpty
                        ? (shortPhone.isEmpty
                              ? 'ঠিকানা দেওয়া নেই'
                              : shortPhone)
                        : (shortPhone.isEmpty
                              ? e.area
                              : '${e.area} · $shortPhone'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                if (role != null || e.verified)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (shortPhone.isNotEmpty) ...[
                  _quickBtn(
                    icon: Icons.phone_in_talk,
                    label: 'কল',
                    color: AppColors.normal,
                    onTap: () => _call(shortPhone),
                  ),
                  if (_waOk) ...[
                    const SizedBox(width: 6),
                    _quickBtn(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      color: AppColors.info,
                      onTap: () => _wa(shortPhone),
                    ),
                  ],
                ],
                if (e.email.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _quickBtn(
                    icon: Icons.send_outlined,
                    label: 'ইমেইল',
                    color: AppColors.gold,
                    onTap: () => _email(e.email),
                  ),
                ],
                if (shortPhone.isEmpty && e.email.isEmpty)
                  const Text(
                    'যোগাযোগের তথ্য নেই',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            IgnorePointer(
              child: WaterRipple(color: AppColors.primary, height: 7),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _email(String email) async {
    final uri = ContactService.instance.mailUri(
      email,
      subject: 'রক্ত দরকার — BloodLink BD',
      body: 'আসসালামু আলাইকুম,\n\nরক্ত দরকার এমন পরিস্থিতিতে BloodLink BD অ্যাপের তালিকা থেকে আপনার ইমেইল পেয়েছি।',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _toast('ইমেইল অ্যাপ খোলা যায়নি');
  }

  Widget _quickBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final List<TextEditingController> _phoneCtrls = [TextEditingController()];
  String _bloodGroup = 'O+';
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _areaCtrl.dispose();
    _noteCtrl.dispose();
    for (final c in _phoneCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPhone() {
    if (_phoneCtrls.length >= BloodListService.maxPhones) return;
    setState(() => _phoneCtrls.add(TextEditingController()));
  }

  void _removePhone(int i) {
    if (_phoneCtrls.length <= 1) return;
    setState(() => _phoneCtrls.removeAt(i).dispose());
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phones = _phoneCtrls
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('নাম দিন')));
      return;
    }
    if (phones.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('অন্তত ১টি নম্বর দিন')));
      return;
    }
    setState(() => _busy = true);
    final res = await BloodListService.instance.addEntry(
      name: name,
      bloodGroup: _bloodGroup,
      phones: phones,
      email: _emailCtrl.text,
      area: _areaCtrl.text,
      note: _noteCtrl.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(res.message)));
    if (res.ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'নতুন রক্তদাতা যোগ করুন',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _field('নাম', _nameCtrl, hint: 'নাম ও পদবি'),
            const SizedBox(height: 12),
            Text('রক্তের গ্রুপ', style: _labelStyle()),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in BloodCompat.groups)
                  GestureDetector(
                    onTap: () => setState(() => _bloodGroup = g),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _bloodGroup == g
                            ? AppColors.primary
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _bloodGroup == g
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        g,
                        style: TextStyle(
                          color: _bloodGroup == g
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'নম্বর (একাধিক) — ${_phoneCtrls.length}/${BloodListService.maxPhones}',
              style: _labelStyle(),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < _phoneCtrls.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneCtrls[i],
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: _decoration('018XXXXXXXX'),
                      ),
                    ),
                    if (i > 0)
                      IconButton(
                        onPressed: () => _removePhone(i),
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.critical,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            GestureDetector(
              onTap: _addPhone,
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'আরেকটা নম্বর যোগ করুন',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _field('ইমেইল (ঐচ্ছিক)', _emailCtrl, hint: 'email@example.com'),
            const SizedBox(height: 12),
            _field('এলাকা (ঐচ্ছিক)', _areaCtrl, hint: 'ঢাকা, ধানমন্ডি…'),
            const SizedBox(height: 12),
            _field(
              'অতিরিক্ত তথ্য (ঐচ্ছিক)',
              _noteCtrl,
              hint: 'যেমন: নিয়মিত ডোনার, উপলব্ধতার সময়…',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: Text(_busy ? 'যোগ হচ্ছে…' : 'তালিকায় যোগ করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() =>
      const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700);

  Widget _field(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: 13.5),
          decoration: _decoration(hint ?? ''),
        ),
      ],
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
    filled: true,
    fillColor: AppColors.surfaceHigh.withValues(alpha: 0.6),
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );
}
