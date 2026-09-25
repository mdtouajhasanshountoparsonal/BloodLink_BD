import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/blood_list_entry.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/blood_list_service.dart';
import '../services/contact_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_card.dart';
import '../widgets/roster_swim.dart';

/// কার্ড থেকে ডিটেলস পেজ — অ্যানিমেশনসহ (slide + fade)
Route<void> bloodListEntryDetailRoute(BloodListEntry entry, {String? role}) {
  return PageRouteBuilder(
    pageBuilder: (_, _, _) =>
        BloodListEntryDetailScreen(entry: entry, role: role),
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (_, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class BloodListEntryDetailScreen extends StatefulWidget {
  const BloodListEntryDetailScreen({super.key, required this.entry, this.role});

  final BloodListEntry entry;

  /// এন্ট্রি কে যোগ করেছে (ডিজাইন ব্যাজ দেখানোর জন্য): 'admin' | 'manager' | null
  final String? role;

  @override
  State<BloodListEntryDetailScreen> createState() =>
      _BloodListEntryDetailScreenState();
}

class _BloodListEntryDetailScreenState
    extends State<BloodListEntryDetailScreen> {
  late BloodListEntry _entry;
  bool _isAdmin = false;
  bool _isManager = false;
  bool _waOk = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _load();
    ContactService.instance.whatsappInstalled().then((ok) {
      if (mounted) setState(() => _waOk = ok);
    });
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

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _call(String phone) async {
    final ok = await launchUrl(ContactService.instance.callUri(phone));
    if (!ok) _toast('কল খোলা যায়নি');
  }

  Future<void> _wa(String phone) async {
    final ok = await ContactService.instance.openWhatsapp(
      phone,
      text: 'রক্ত দরকার — BloodLink BD',
    );
    if (!ok) _toast('WhatsApp খোলা যায়নি');
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

  /// অ্যাডমিন/ম্যানেজার এন্ট্রি এডিট করতে পারে।
  Future<void> _editEntry() async {
    final edited =
        await showModalBottomSheet<
          ({
            String name,
            String bloodGroup,
            List<String> phones,
            String email,
            String area,
            String note,
          })
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _EditEntrySheet(entry: _entry),
        );
    if (edited == null || !mounted) return;
    setState(() => _busy = true);
    final res = await BloodListService.instance.updateEntry(
      id: _entry.id,
      name: edited.name,
      bloodGroup: edited.bloodGroup,
      phones: edited.phones,
      email: edited.email,
      area: edited.area,
      note: edited.note,
    );
    if (res.ok && mounted) {
      setState(() {
        _entry = _entry.copyWith(
          name: edited.name,
          bloodGroup: edited.bloodGroup,
          phones: edited.phones,
          email: edited.email,
          area: edited.area,
          note: edited.note,
        );
      });
    }
    if (mounted) _toast(res.message);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _toggleVerified() async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await BloodListService.instance.setVerified(
      _entry.id,
      !_entry.verified,
    );
    if (res.ok && mounted) {
      setState(() => _entry = _entry.copyWith(verified: !_entry.verified));
    }
    if (mounted) _toast(res.message);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _confirmDelete() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('মুছে ফেলবেন?'),
        content: Text('"${_entry.name}" তালিকা থেকে মুছে ফেলা হবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('না'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    final res = await BloodListService.instance.deleteEntry(_entry.id);
    _toast(res.message);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final e = _entry;
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
                    const Text(
                      'রক্তদাতার তথ্য',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerCard(e),
                      const SizedBox(height: 14),
                      if (e.note.isNotEmpty) ...[
                        _section('অতিরিক্ত তথ্য', [
                          _row_(icon: Icons.notes_rounded, title: e.note),
                        ]),
                        const SizedBox(height: 14),
                      ],
                      _section('যোগাযোগ', _contactRows(e)),
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

  Widget _headerCard(BloodListEntry e) {
    final (roleLabel, roleColor, roleIcon) = switch (widget.role) {
      'admin' => ('অ্যাডমিন', AppColors.gold, Icons.shield_outlined),
      'manager' => (
        'ম্যানেজার',
        AppColors.info,
        Icons.admin_panel_settings_outlined,
      ),
      _ => (null, null, null),
    };
    return Hero(
      tag: 'blood-avatar-${e.id}',
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SwimmingAvatar(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      e.name.trim().isEmpty ? '?' : e.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (roleLabel != null)
                            _chip(roleLabel, roleColor!, roleIcon!),
                          if (e.verified)
                            _chip(
                              'ভেরিফাইড',
                              AppColors.normal,
                              Icons.verified_rounded,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    e.bloodGroup,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (e.area.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      e.area,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_isAdmin || _isManager) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _busy ? null : _editEntry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'এডিট',
                              style: TextStyle(
                                color: AppColors.info,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isAdmin) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _busy ? null : _toggleVerified,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: e.verified
                                ? AppColors.normal.withValues(alpha: 0.12)
                                : AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.normal.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                e.verified
                                    ? Icons.verified_rounded
                                    : Icons.gpp_maybe_outlined,
                                size: 15,
                                color: AppColors.normal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                e.verified ? 'ভেরিফাইড ✓' : 'ভেরিফাই করুন',
                                style: const TextStyle(
                                  color: AppColors.normal,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _confirmDelete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.critical.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.critical.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                size: 15,
                                color: AppColors.critical,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'মুছুন',
                                style: TextStyle(
                                  color: AppColors.critical,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: IgnorePointer(
                child: WaterRipple(color: AppColors.primary, height: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  List<Widget> _contactRows(BloodListEntry e) {
    final rows = <Widget>[];
    for (var i = 0; i < e.phones.length; i++) {
      final phone = e.phones[i];
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i == e.phones.length - 1 ? 0 : 8),
          child: Row(
            children: [
              const Icon(
                Icons.call_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              _actionBtn(
                Icons.phone_in_talk,
                AppColors.normal,
                () => _call(phone),
              ),
              if (_waOk) ...[
                const SizedBox(width: 6),
                _actionBtn(
                  Icons.chat_rounded,
                  AppColors.info,
                  () => _wa(phone),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (e.phones.isEmpty) {
      rows.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'নম্বর দেওয়া নেই',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ),
      );
    }
    if (e.email.isNotEmpty) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: e.phones.isEmpty ? 0 : 10),
          child: Row(
            children: [
              const Icon(
                Icons.mail_outline_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                  ),
                ),
              ),
              _actionBtn(
                Icons.send_outlined,
                AppColors.gold,
                () => _email(e.email),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _row_({required IconData icon, required String title}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
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

const List<String> _bloodGroups = [
  'A+',
  'A-',
  'B+',
  'B-',
  'O+',
  'O-',
  'AB+',
  'AB-',
];

class _EditEntrySheet extends StatefulWidget {
  const _EditEntrySheet({required this.entry});

  final BloodListEntry entry;

  @override
  State<_EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends State<_EditEntrySheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.entry.name,
  );
  late final TextEditingController _phone1 = TextEditingController(
    text: widget.entry.phones.isNotEmpty ? widget.entry.phones[0] : '',
  );
  late final TextEditingController _phone2 = TextEditingController(
    text: widget.entry.phones.length > 1 ? widget.entry.phones[1] : '',
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.entry.email,
  );
  late final TextEditingController _area = TextEditingController(
    text: widget.entry.area,
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.entry.note,
  );
  late String _blood = widget.entry.bloodGroup;

  @override
  void dispose() {
    _name.dispose();
    _phone1.dispose();
    _phone2.dispose();
    _email.dispose();
    _area.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final phones = [
      _phone1.text.trim(),
      _phone2.text.trim(),
    ].where((p) => p.isNotEmpty).toList();
    if (_name.text.trim().isEmpty ||
        !_bloodGroups.contains(_blood) ||
        phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('নাম, রক্তের গ্রুপ ও কমপক্ষে একটি নম্বর দিন'),
        ),
      );
      return;
    }
    Navigator.of(context).pop((
      name: _name.text.trim(),
      bloodGroup: _blood,
      phones: phones,
      email: _email.text.trim(),
      area: _area.text.trim(),
      note: _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'এন্ট্রি এডিট করুন',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(_name, 'নাম', prefix: Icons.person_outline),
                  const SizedBox(height: 12),
                  const Text(
                    'রক্তের গ্রুপ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in _bloodGroups)
                        GestureDetector(
                          onTap: () => setState(() => _blood = g),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _blood == g
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _blood == g
                                    ? AppColors.primary
                                    : AppColors.surfaceHigh,
                              ),
                            ),
                            child: Text(
                              g,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _blood == g
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(_phone1, 'ফোন ১ *', prefix: Icons.call_outlined),
                  const SizedBox(height: 12),
                  _field(
                    _phone2,
                    'ফোন ২ (ঐচ্ছিক)',
                    prefix: Icons.call_outlined,
                  ),
                  const SizedBox(height: 12),
                  _field(_email, 'ইমেইল (ঐচ্ছিক)', prefix: Icons.mail_outline),
                  const SizedBox(height: 12),
                  _field(_area, 'এলাকা (ঐচ্ছিক)', prefix: Icons.place_outlined),
                  const SizedBox(height: 12),
                  _field(
                    _note,
                    'নোট (ঐচ্ছিক)',
                    prefix: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'সেভ করুন',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    IconData? prefix,
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix == null ? null : Icon(prefix, size: 18),
        filled: true,
        fillColor: AppColors.surfaceHigh.withValues(alpha: 0.5),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12.5,
        ),
        prefixIconColor: AppColors.textSecondary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceHigh),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
