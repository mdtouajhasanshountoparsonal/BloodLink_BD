import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_user.dart';
import '../models/blood_request.dart';
import '../services/admin_service.dart';
import '../services/app_meta_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/blood_group_chip.dart';
import '../widgets/glass_card.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: BackgroundDecor(
          child: SafeArea(
            child: Column(
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
                      const Expanded(
                        child: Text('অ্যাডমিন প্যানেল',
                            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                      ),
                      Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    tabs: [
                      Tab(text: 'অ্যাপ'),
                      Tab(text: 'রিকোয়েস্ট'),
                      Tab(text: 'ইউজার'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    children: [
                      const _AppControlTab(),
                      _RequestsTab(),
                      const _UsersTab(),
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

class _AppControlTab extends StatefulWidget {
  const _AppControlTab();

  @override
  State<_AppControlTab> createState() => _AppControlTabState();
}

class _AppControlTabState extends State<_AppControlTab> {
  final _versionCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _noticeCtrl = TextEditingController();
  final _forceMsgCtrl = TextEditingController();
  bool _forceClose = false;
  bool _saving = false;

  AppUser? _admin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await AuthService.instance.currentUser();
    final snap = await AdminService.instance.fetchMeta();
    _urlCtrl.text = snap?['downloadUrl'] as String? ?? '';
    _versionCtrl.text = snap?['latestVersion'] as String? ?? AppMetaService.currentVersion;
    _noticeCtrl.text = snap?['notice'] as String? ?? '';
    _forceMsgCtrl.text = snap?['forceMessage'] as String? ?? '';
    final fc = snap?['forceClose'] as bool? ?? false;
    if (mounted) {
      setState(() {
        _admin = u;
        _forceClose = fc;
      });
    }
  }

  @override
  void dispose() {
    _versionCtrl.dispose();
    _urlCtrl.dispose();
    _noticeCtrl.dispose();
    _forceMsgCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final res = await AdminService.instance.saveAppMeta(
      forceClose: _forceClose,
      forceMessage: _forceMsgCtrl.text.trim(),
      latestVersion:
          _versionCtrl.text.trim().isEmpty ? null : _versionCtrl.text.trim(),
      downloadUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
      notice: _noticeCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(res.message)));
  }

  Future<void> _copyUid() async {
    final uid = _admin?.uid ?? '';
    await Clipboard.setData(ClipboardData(text: uid));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('UID কপি হয়েছে')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('আমার অ্যাডমিন আইডি (UID)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _admin?.uid ?? '...',
                        maxLines: 2,
                        style: TextStyle(
                          color: AppColors.info,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _copyUid,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
                        ),
                        child: const Text('কপি', style: TextStyle(color: AppColors.info, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'অ্যাডমিন: Firebase Console → appMeta/main → admins অ্যারেতে UID বসান।\nম্যানেজার (কো-অ্যাডমিন, শুধু রক্তদাতা তালিকা চালায়): managers অ্যারেতে UID বসান।',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field('নতুন ভার্সন (latestVersion)', _versionCtrl,
                    hint: 'যেমন 0.1.1 — অ্যাপে "নতুন ভার্সন" ব্যানার দেখাবে'),
                _field('ডাউনলোড লিংক (downloadUrl)', _urlCtrl,
                    hint: 'ওয়েবসাইট / APK লিংক'),
                _field('নোটিস বার্তা (notice)', _noticeCtrl,
                    hint: 'ব্যানারে দেখানো টেক্সট'),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _forceClose,
                  onChanged: (v) => setState(() => _forceClose = v),
                  activeTrackColor: AppColors.critical,
                  activeThumbColor: Colors.white,
                  title: const Text('অ্যাপ চিরতরে বন্ধ (Force Close)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text('ON করলে সবাই শুধু বন্ধ-স্ক্রিন দেখবে',
                      style: TextStyle(color: AppColors.critical, fontSize: 12)),
                ),
                if (_forceClose) _field('বন্ধের বার্তা (forceMessage)', _forceMsgCtrl),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_saving ? 'সংরক্ষণ হচ্ছে…' : 'সংরক্ষণ করুন'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'রুলস অনুযায়ী কেবল admins তালিকার UID এই সব পরিবর্তন করতে পারবে।',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BloodRequest>>(
      stream: AdminService.instance.allRequestsStream(),
      initialData: const [],
      builder: (context, snap) {
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return const Center(
            child: Text('কোনো রিকোয়েস্ট নেই',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = list[i];
            return GlassCard(
              radius: 18,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BloodGroupChip(group: r.bloodGroup, compact: true),
                      const SizedBox(width: 8),
                      Icon(r.urgency.color == AppColors.critical
                          ? Icons.emergency_rounded
                          : r.urgency.color == AppColors.urgent
                              ? Icons.schedule_rounded
                              : Icons.info_outline_rounded,
                          size: 14, color: r.urgency.color),
                      const SizedBox(width: 4),
                      Text(r.urgency.label,
                          style: TextStyle(color: r.urgency.color, fontSize: 11, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: r.status == 'active'
                              ? AppColors.normal.withValues(alpha: 0.15)
                              : AppColors.textSecondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(r.status,
                            style: TextStyle(
                                color: r.status == 'active' ? AppColors.normal : AppColors.textSecondary,
                                fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('রোগী: ${r.patientName} · ${r.bags} ব্যাগ',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text('${r.hospital}, ${r.area}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  Text('রিকোয়েস্টার: ${r.requesterName} (${r.requesterPhone})',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  if (r.isActive)
                    Text('মেয়াদ: ${r.remainingLabel()}',
                        style: const TextStyle(color: AppColors.urgent, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (r.isActive)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirm(context, 'রিকোয়েস্ট বন্ধ করবেন?', (msgr) async {
                              final ok = await AdminService.instance.closeRequest(r.id);
                              msgr
                                ..hideCurrentSnackBar()
                                ..showSnackBar(SnackBar(content: Text(ok ? 'বন্ধ হয়েছে' : 'ব্যর্থ')));
                            }),
                            style: _smallBtn(BorderSide(color: AppColors.urgent)),
                            icon: const Icon(Icons.stop_circle_outlined, size: 16, color: AppColors.urgent),
                            label: const Text('বন্ধ', style: TextStyle(color: AppColors.urgent, fontSize: 12)),
                          ),
                        ),
                      if (r.isActive) const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirm(context, 'রিকোয়েস্ট মুছবেন?', (msgr) async {
                            final ok = await AdminService.instance.deleteRequest(r.id);
                            msgr
                              ..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text(ok ? 'মুছে ফেলা হয়েছে' : 'ব্যর্থ')));
                          }),
                          style: _smallBtn(BorderSide(color: AppColors.critical)),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.critical),
                          label: const Text('ডিলিট', style: TextStyle(color: AppColors.critical, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  ButtonStyle _smallBtn(BorderSide side) => OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: side,
      );

  Future<void> _confirm(
      BuildContext context,
      String msg,
      Future<void> Function(ScaffoldMessengerState msgr) action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('নিশ্চিত করুন'),
        content: Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.critical),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );
    if (ok == true) {
      if (!context.mounted) return;
      final msgr = ScaffoldMessenger.of(context);
      await action(msgr);
    }
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: AdminService.instance.allUsersStream(),
      initialData: const [],
      builder: (context, snap) {
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return const Center(
            child: Text('এখনো কোনো ইউজার নেই',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final u = list[i];
            return GlassCard(
              radius: 18,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: u.banned
                          ? AppColors.critical.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.15),
                      border: Border.all(
                          color: u.banned ? AppColors.critical : AppColors.primary, width: 1.2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      u.name.characters.firstOrNull?.toUpperCase() ?? '?',
                      style: TextStyle(
                          color: u.banned ? AppColors.critical : AppColors.primary,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${u.bloodGroup} · ${u.donations} ডোনেশন',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text(u.phone.isEmpty ? '(নম্বর নেয়নি)' : u.phone,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!u.banned)
                    GestureDetector(
                      onTap: () => _toggle(context, u, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.critical.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.critical, width: 1),
                        ),
                        child: const Text('ব্যান',
                            style: TextStyle(color: AppColors.critical, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => _toggle(context, u, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.normal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.normal, width: 1),
                        ),
                        child: const Text('আনব্যান',
                            style: TextStyle(color: AppColors.normal, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggle(BuildContext context, AppUser u, bool banned) async {
    final ok = await AdminService.instance.setUserBanned(u.uid, banned);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ok ? (banned ? '${u.name} ব্যান হয়েছে' : 'আনব্যান হয়েছে') : 'ব্যর্থ')));
    }
  }
}