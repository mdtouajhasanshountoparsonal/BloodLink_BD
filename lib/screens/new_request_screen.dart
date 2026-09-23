import 'package:flutter/material.dart';

import '../models/blood_request.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_button.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  static const _groups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  final _patient = TextEditingController();
  final _hospital = TextEditingController();
  final _area = TextEditingController();
  String _bloodGroup = 'O+';
  int _bags = 1;
  Urgency _urgency = Urgency.critical;
  DateTime _neededBy = DateTime.now().add(const Duration(hours: 6));
  bool _busy = false;

  @override
  void dispose() {
    _patient.dispose();
    _hospital.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_patient.text.trim().isEmpty ||
        _hospital.text.trim().isEmpty ||
        _area.text.trim().isEmpty) {
      _toast('রোগীর নাম, হাসপাতাল আর এলাকা দিন');
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final user = await AuthService.instance.currentUser();
      final pos = await LocationService.instance.currentPosition();
      await RequestService.instance.addRequest(
        BloodRequest(
          id: '',
          uid: user?.uid ?? '',
          requesterName: user?.name ?? '',
          requesterPhone: user?.phone ?? '',
          patientName: _patient.text.trim(),
          bloodGroup: _bloodGroup,
          hospital: _hospital.text.trim(),
          area: _area.text.trim(),
          distanceKm: 0,
          bags: _bags,
          urgency: _urgency,
          neededBy: _neededBy,
          latitude: pos?.latitude,
          longitude: pos?.longitude,
        ),
      );
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('রিকোয়েস্ট পাঠানো হয়েছে')),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('রিকোয়েস্ট পাঠানো ব্যর্থ হয়েছে');
      }
    }
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text('ইমার্জেন্সি রিকোয়েস্ট', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
                const SizedBox(height: 24),
                _fieldLabel('রোগীর নাম'),
                const SizedBox(height: 10),
                TextField(
                  controller: _patient,
                  decoration: const InputDecoration(
                    hintText: 'রোগীর নাম',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 21),
                  ),
                ),
                const SizedBox(height: 18),
                _fieldLabel('ব্লাড গ্রুপ'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final g in _groups)
                      GestureDetector(
                        onTap: () => setState(() => _bloodGroup = g),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: _bloodGroup == g ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: _bloodGroup == g ? AppColors.primary : AppColors.border),
                          ),
                          child: Text(
                            g,
                            style: TextStyle(
                              color: _bloodGroup == g ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _fieldLabel('হাসপাতাল'),
                const SizedBox(height: 10),
                TextField(
                  controller: _hospital,
                  decoration: const InputDecoration(
                    hintText: 'হাসপাতালের নাম',
                    prefixIcon: Icon(Icons.local_hospital_outlined, size: 21),
                  ),
                ),
                const SizedBox(height: 18),
                _fieldLabel('এলাকা'),
                const SizedBox(height: 10),
                TextField(
                  controller: _area,
                  decoration: const InputDecoration(
                    hintText: 'থানা / এলাকা',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 21),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _fieldLabel('ব্যাগ সংখ্যা')),
                    Expanded(child: _fieldLabel('প্রয়োজনীয় সময়')),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _bags = _bags > 1 ? _bags - 1 : 1),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 22),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '$_bags',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _bags++),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDateTime(context),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule, size: 19, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _fmt(_neededBy),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _fieldLabel('জরুরি লেভেল'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final u in Urgency.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _urgency = u),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _urgency == u ? u.color.withValues(alpha: 0.18) : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _urgency == u ? u.color : AppColors.border,
                                  width: _urgency == u ? 1.6 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: u.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(u.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'রিকোয়েস্ট ${BloodRequest.lifetimeFor(_urgency).inHours} ঘণ্টা সক্রিয় থাকবে — মেয়াদ শেষে পুনরায় পাঠাতে পারবেন',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
                const SizedBox(height: 28),
                GlassButton(
                  label: _busy ? 'পাঠানো হচ্ছে...' : 'রিকোয়েস্ট পাঠান',
                  icon: _busy ? null : Icons.send_rounded,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime t) {
    final d = '${t.day}/${t.month}/${t.year}';
    final time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '$d $time';
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700));
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _neededBy,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_neededBy));
    if (time == null) return;
    setState(() {
      _neededBy = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }
}