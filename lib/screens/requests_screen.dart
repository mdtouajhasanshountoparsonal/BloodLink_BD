import 'package:flutter/material.dart';

import '../models/blood_request.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/request_card.dart';
import 'request_detail_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  static const _filters = ['সব', 'জরুরি', 'দ্রুত', 'সাধারণ'];
  String _filter = 'সব';
  final _search = TextEditingController();

  Urgency? _urgencyOf(String label) => switch (label) {
    'জরুরি' => Urgency.critical,
    'দ্রুত' => Urgency.urgent,
    'সাধারণ' => Urgency.normal,
    _ => null,
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'রক্তের রিকোয়েস্ট',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'সক্রিয়',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'গ্রুপ, এলাকা বা হাসপাতাল খুঁজুন',
                    prefixIcon: Icon(Icons.search_rounded, size: 21),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final f = _filters[i];
                      final selected = f == _filter;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder(
                    stream: RequestService.instance.requestsStream(
                      urgency: _urgencyOf(_filter),
                      query: _search.text.trim(),
                    ),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'রিকোয়েস্ট লোড করা যায়নি',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () => setState(() {}),
                                child: const Text('আবার চেষ্টা করুন'),
                              ),
                            ],
                          ),
                        );
                      }
                      final results = snap.data ?? const <BloodRequest>[];
                      if (results.isEmpty) {
                        return const Center(
                          child: Text(
                            'কোনো রিকোয়েস্ট পাওয়া যায়নি',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.only(top: 4),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => RequestCard(
                          request: results[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RequestDetailScreen(request: results[i]),
                            ),
                          ),
                        ),
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
}
