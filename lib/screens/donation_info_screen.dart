import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_card.dart';

class DonationInfoScreen extends StatelessWidget {
  const DonationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text('রক্তদানের উপকারিতা', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _HeroBanner(),
                      SizedBox(height: 22),
                      _SectionTitle(
                        icon: Icons.science_rounded,
                        title: 'বিজ্ঞান যা বলে',
                      ),
                      SizedBox(height: 12),
                      _FactTile(
                        icon: Icons.water_drop,
                        title: 'একবারে ৩ জনের প্রাণ বাঁচে',
                        body: 'একটি ডোনেশনে ৪৫০ মিলি রক্ত সংগ্রহ হয়, যা ভাগ করে ৩ জন রোগীকে দেওয়া যায়। বিশ্ব স্বাস্থ্য সংস্থার (WHO) মতে প্রতি ২ সেকেন্ডে কোথাও না কোথাও রক্তের প্রয়োজন হয়। বাংলাদেশে বছরে প্রায় ৭.৫ লক্ষ ব্যাগ রক্তের চাহিদা আছে।',
                      ),
                      SizedBox(height: 10),
                      _FactTile(
                        icon: Icons.recycling_rounded,
                        title: 'শরীর দ্রুত তা পূরণ করে',
                        body: 'রক্তদানের ২৪ ঘণ্টার মধ্যে প্লাজমা, ২ সপ্তাহে লোহিত রক্তকণিকার পরিমাণ স্বাভাবিক এবং ৪–৬ সপ্তাহের মধ্যে সম্পূর্ণ রক্ত পুনর্গঠিত হয়। তাই নিয়মিত (৩–৪ মাস পরপর) রক্তদান সম্পূর্ণ নিরাপদ।',
                      ),
                      SizedBox(height: 10),
                      _FactTile(
                        icon: Icons.favorite_rounded,
                        title: 'হৃদরোগের ঝুঁকি কমায়',
                        body: 'গবেষণায় দেখা গেছে, নিয়মিত রক্তদান রক্তে আয়রনের মাত্রা নিয়ন্ত্রণে রাখে। অতিরিক্ত আয়রন হৃদরোগ ও লিভারের সমস্যার সাথে যুক্ত — রক্তদান সেই ভার কমিয়ে হৃদপিণ্ড সুস্থ রাখে (American Journal of Epidemiology)।',
                      ),
                      SizedBox(height: 10),
                      _FactTile(
                        icon: Icons.local_fire_department_rounded,
                        title: '৬৫০ ক্যালোরি বার্ন হয়',
                        body: 'একটি রক্তদানে গড়ে প্রায় ৬৫০ ক্যালোরি খরচ হয়। অনেকের ধারণার বিপরীতে রক্তদান শরীর দুর্বল করে না — সঠিক নিয়ম মেনে দিলে শরীরে নতুন গঠন প্রক্রিয়াও সক্রিয় হয়।',
                      ),
                      SizedBox(height: 10),
                      _FactTile(
                        icon: Icons.health_and_safety_rounded,
                        title: 'বিনামূল্যে স্বাস্থ্য পরীক্ষা',
                        body: 'প্রতি ডোনেশনের আগে হিমোগ্লোবিন, রক্তচাপ, গ্রুপ ও হেপাটাইটিস/এইচআইভি স্ক্রিনিং করা হয়। অর্থাৎ আপনি প্রতিবার বিনামূল্যে একটি স্বাস্থ্য পরীক্ষাও পাচ্ছেন।',
                      ),
                      SizedBox(height: 22),
                      _SectionTitle(
                        icon: Icons.favorite_outline,
                        title: 'ডোনেট করতে কে পারবেন?',
                      ),
                      SizedBox(height: 12),
                      GlassCard(child: Text(
                        '• বয়স ১৮–৬০ বছর\n'
                        '• শরীরের ওজন ৪৫ কেজি বা তার বেশি\n'
                        '• হিমোগ্লোবিন ১২.৫ g/dL এর বেশি\n'
                        '• শেষ রক্তদানের ৩ মাস পার হয়েছে\n'
                        '• ফ্লু/সর্দি বা অন্য সংক্রমণ নেই\n'
                        '• খালি পেটে নয় — আগে খেয়ে আসুন',
                        style: TextStyle(fontSize: 13, height: 1.7, color: AppColors.textPrimary),
                      )),
                      SizedBox(height: 22),
                      _SectionTitle(
                        icon: Icons.verified_rounded,
                        title: 'মনে রাখুন',
                      ),
                      SizedBox(height: 12),
                      GlassCard(child: Text(
                        'ভালো ব্যাংকের মতোই, সঠিক সময়ে সঠিক গ্রুপের রক্ত না পেলে জীবন চলে যায়। আপনার সর্বশেষ রক্তদান কারও বাবার, কারও মায়ের বা সন্তানের জীবন বাঁচাতে পারে।',
                        style: TextStyle(fontSize: 13, height: 1.7, color: AppColors.textPrimary),
                      )),
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
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5470), Color(0xFFB71C1C)],
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
        children: const [
          Icon(Icons.water_drop, color: Colors.white, size: 34),
          SizedBox(height: 10),
          Text(
            'এক ফোঁটা রক্ত, একটি জীবন',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'রক্তদান শুধু অন্যের জন্যই নয় — আপনার শরীরের জন্যও উপকারী। এক ডোনেশনে আপনি ৩ জনের জীবন বাঁচাতে পারেন।',
            style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.critical, size: 19),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}