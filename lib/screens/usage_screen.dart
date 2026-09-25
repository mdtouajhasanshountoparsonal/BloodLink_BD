import 'package:flutter/material.dart';

import '../services/usage_counter.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key});

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  @override
  Widget build(BuildContext context) {
    final reads = UsageCounter.instance.totalReadsToday();
    final writes = UsageCounter.instance.totalWritesToday();
    final readLimit = SparkLimits.readsPerDay;
    final writeLimit = SparkLimits.writesPerDay;
    final readPct = (reads / readLimit).clamp(0, 1).toDouble();
    final writePct = (writes / writeLimit).clamp(0, 1).toDouble();
    final byUid = UsageCounter.instance.writesTodayByUid();
    final readsColl = UsageCounter.instance.readsTodayByCollection();
    final writesColl = UsageCounter.instance.writesTodayByCollection();

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
                      'ব্যবহার ও কোটা',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'এটা এই ডিভাইস/অ্যাপের আনুমানিক হিসাব। আসল সংখ্যা Firebase Console-এ দেখুন।',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    _limitCard(
                      icon: Icons.download_rounded,
                      color: AppColors.info,
                      title: 'রিড (আজ)',
                      value: reads,
                      limit: readLimit,
                      pct: readPct,
                      unit: 'পড়া',
                    ),
                    const SizedBox(height: 12),
                    _limitCard(
                      icon: Icons.upload_rounded,
                      color: AppColors.primary,
                      title: 'রাইট (আজ)',
                      value: writes,
                      limit: writeLimit,
                      pct: writePct,
                      unit: 'লেখা',
                    ),
                    const SizedBox(height: 12),
                    _storageCard(),
                    const SizedBox(height: 20),
                    const Text(
                      'গত ৭ দিন',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _weekBars(),
                    const SizedBox(height: 20),
                    const Text(
                      'দিনভিত্তিক ব্যবহার (গত ১৪ দিন)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _dailyList(),
                    if (byUid.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'আজকের রাইট — অ্যাকাউন্ট অনুযায়ী (এই ডিভাইস)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...byUid.map(
                        (e) => _kvTile(
                          '${e.$1.substring(0, 6)}…',
                          e.$2,
                          AppColors.gold,
                        ),
                      ),
                    ],
                    if (writesColl.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'আজকের রাইট — বিষয় অনুযায়ী',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...writesColl.map(
                        (e) => _kvTile(e.$1, e.$2, AppColors.primary),
                      ),
                    ],
                    if (readsColl.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'আজকের রিড — বিষয় অনুযায়ী',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...readsColl.map(
                        (e) => _kvTile(e.$1, e.$2, AppColors.info),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
                      'Spark (ঢু-রে ফ্রি): ৫০,০০০ রিড/দিন, ২০,০০০ রাইট/দিন, ১ GB স্টোরেজ, ১০ GB/মাস ডাউনলোড।\nবাড়তে গেলে Blaze-এ ফ্রি-কোটা শেষ হলে চার্জ লাগতে পারে।',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _limitCard({
    required IconData icon,
    required Color color,
    required String title,
    required int value,
    required int limit,
    required double pct,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$value / $limit $unit',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct >= 1
                ? 'কোটা পূর্ণ! বাড়ানোর জন্য Blaze-এ যেতে হবে।'
                : '${(pct * 100).toStringAsFixed(1)}% ব্যবহৃত — বাকি ${limit - value}',
            style: TextStyle(
              color: pct >= 1 ? AppColors.critical : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _storageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage_rounded, size: 18, color: AppColors.gold),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'স্টোরেজ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${SparkLimits.storageGb} GB ফ্রি',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekBars() {
    final reads = UsageCounter.instance.lastSevenDaysReads();
    final writes = UsageCounter.instance.lastSevenDaysWrites();
    final maxR = reads.map((e) => e.$2).fold(1, (a, b) => a > b ? a : b);
    final maxW = writes.map((e) => e.$2).fold(1, (a, b) => a > b ? a : b);
    return Column(
      children: [
        _weekBarRow('রিড', reads, maxR, AppColors.info),
        const SizedBox(height: 8),
        _weekBarRow('রাইট', writes, maxW, AppColors.primary),
      ],
    );
  }

  Widget _weekBarRow(
    String label,
    List<(String, int)> data,
    int maxValue,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Row(
            children: data.map((e) {
              final w = (e.$2 / maxValue).clamp(0.06, 1.0);
              return Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 44,
                        color: AppColors.border,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(height: 44 * w, color: color),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.$1,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _dailyList() {
    final data = UsageCounter.instance.dailySummary(days: 14);
    final maxTotal = data
        .map((e) => e.reads + e.writes)
        .fold(1, (a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [for (final d in data) _dailyRow(d, maxTotal)]),
    );
  }

  Widget _dailyRow(({String label, int reads, int writes}) d, int maxTotal) {
    final total = d.reads + d.writes;
    final ratio = total == 0
        ? 0.0
        : (total / maxTotal).clamp(0.0, 1.0).toDouble();
    final color = ratio >= 0.66
        ? AppColors.critical
        : ratio >= 0.33
        ? AppColors.urgent
        : total == 0
        ? AppColors.border
        : AppColors.normal;
    final label = total == 0
        ? 'ব্যবহার নেই'
        : ratio >= 0.66
        ? 'বেশি'
        : ratio >= 0.33
        ? 'মাঝারি'
        : 'কম';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              d.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    width: double.infinity,
                    color: AppColors.surfaceHigh,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ratio == 0 ? null : ratio,
                      child: Container(height: 8, color: color),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'রিড ${d.reads} · রাইট ${d.writes}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 66,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: total == 0 ? AppColors.textSecondary : color,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvTile(String k, int v, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$v',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
