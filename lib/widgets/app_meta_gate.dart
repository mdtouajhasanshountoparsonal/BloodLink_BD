import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_meta_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_card.dart';

/// রুট গেট: চালুই 'অ্যাপ বন্ধ' (force close) বা 'আপডেট আছে' দেখায়।
class AppMetaGate extends StatefulWidget {
  const AppMetaGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppMetaGate> createState() => _AppMetaGateState();
}

class _AppMetaGateState extends State<AppMetaGate> {
  StreamSubscription<AppMeta>? _sub;
  AppMeta? _meta;
  bool _dismissedUpdate = false;

  @override
  void initState() {
    super.initState();
    _sub = AppMetaService.instance.metaStream().listen(
      (meta) {
        if (mounted) setState(() => _meta = meta);
      },
      onError: (Object _) {
        if (_meta == null && mounted) {
          setState(() => _meta = const AppMeta());
        }
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    if (meta != null && meta.forceClose) {
      return _BlockedScreen(message: meta.forceMessage);
    }
    return Column(
      children: [
        if (meta != null && meta.hasUpdate && !_dismissedUpdate)
          _UpdateBanner(
            meta: meta,
            onClose: () => setState(() => _dismissedUpdate = true),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.meta, required this.onClose});

  final AppMeta meta;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDeep,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDeep, AppColors.primary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.system_update_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'নতুন ভার্সন ${meta.latestVersion}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      meta.notice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final ok = await launchUrl(
                    Uri.parse(
                      meta.downloadUrl.isNotEmpty
                          ? meta.downloadUrl
                          : AppMetaService.defaultDownloadUrl,
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text('ডাউনলোড পেজ খোলা যায়নি'),
                        ),
                      );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'ডাউনলোড',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'বন্ধ করো',
                icon: const Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlockedScreen extends StatelessWidget {
  const _BlockedScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BackgroundDecor(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: GlassCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.critical.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.critical, width: 2),
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        color: AppColors.critical,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'অ্যাপটি বন্ধ আছে',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'প্রশাসনিক সিদ্ধান্তে এই ভার্সনটি বন্ধ রাখা হয়েছে। নতুন আপডেটের জন্য অফিসিয়াল ওয়েবসাইট দেখুন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 11.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
