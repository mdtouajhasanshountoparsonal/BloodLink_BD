import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/blood_request.dart';
import '../services/auth_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../utils/blood_compat.dart';
import '../widgets/background_decor.dart';
import '../widgets/request_card.dart';
import 'request_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await AuthService.instance.currentUser();
    if (mounted) setState(() => _user = u);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    const Expanded(
                      child: Text(
                        'রক্তের নোটিফিকেশন',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StreamBuilder(
                      stream: RequestService.instance.requestsStream(),
                      builder: (context, snap) {
                        final n = _relevantOf(
                          snap.data ?? const <BloodRequest>[],
                        ).length;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: n > 0
                                ? AppColors.critical.withValues(alpha: 0.15)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: n > 0
                                  ? AppColors.critical
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            n > 0 ? '$n টি' : 'কিছু নেই',
                            style: TextStyle(
                              color: n > 0
                                  ? AppColors.critical
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder(
                  stream: RequestService.instance.requestsStream(),
                  builder: (context, snap) {
                    final list = _relevantOf(
                      snap.data ?? const <BloodRequest>[],
                    );
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    if (list.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 42,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 14),
                              Text(
                                'আপনার ব্লাড গ্রুপের জন্য এখনো কোনো রিকোয়েস্ট নেই',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final r = list[i];
                        return RequestCard(
                          request: r,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RequestDetailScreen(request: r),
                            ),
                          ),
                        );
                      },
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

  List<BloodRequest> _relevantOf(List<BloodRequest> all) {
    final group = _user?.bloodGroup;
    final list = all.where((r) {
      if (group == null) return true;
      if (group.isEmpty) return true;
      return BloodCompat.canDonateTo(
            donorGroup: group,
            receiverGroup: r.bloodGroup,
          ) ||
          BloodCompat.canDonateTo(
            donorGroup: r.bloodGroup,
            receiverGroup: group,
          );
    }).toList();

    int urgencyRank(Urgency u) => switch (u) {
      Urgency.critical => 0,
      Urgency.urgent => 1,
      Urgency.normal => 2,
    };

    list.sort((a, b) {
      final u = urgencyRank(a.urgency).compareTo(urgencyRank(b.urgency));
      if (u != 0) return u;
      final won = a.responseCount.compareTo(b.responseCount);
      if (won != 0) return won;
      return b.neededBy.compareTo(a.neededBy);
    });
    return list;
  }
}
