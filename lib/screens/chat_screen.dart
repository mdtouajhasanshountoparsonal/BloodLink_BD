import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_user.dart';
import '../models/blood_request.dart';
import '../services/auth_service.dart';
import '../services/contact_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.requestId, required this.title});

  final String requestId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  AppUser? _user;
  bool _waOk = false;
  BloodRequest? _request;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await AuthService.instance.currentUser();
    if (mounted) setState(() => _user = u);
    ContactService.instance.whatsappInstalled().then((ok) {
      if (mounted) setState(() => _waOk = ok);
    });
    RequestService.instance.requestStream(widget.requestId).listen((r) {
      if (mounted) setState(() => _request = r);
    });
  }

  Future<void> _call(String phone) async {
    final ok = await launchUrl(ContactService.instance.callUri(phone));
    if (!ok && mounted) _toast('কল খোলা যায়নি');
  }

  Future<void> _wa(String phone) async {
    final ok = await ContactService.instance.openWhatsapp(
      phone,
      text: '${widget.title} — BloodLink',
    );
    if (!ok && mounted) _toast('WhatsApp খোলা যায়নি');
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'রিকোয়েস্ট চ্যাট',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            widget.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.lock_outline,
                      size: 17,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: StreamBuilder(
                  stream: RequestService.instance.chatStream(widget.requestId),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }
                    final messages = snap.data ?? const <ChatMessage>[];
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'এখনো কোনো মেসেজ নেই।\n\nফ্রি প্ল্যানে নতুন মেসেজ লেখা বন্ধ — যোগাযোগের জন্য নিচের কল/WhatsApp ব্যাবহার করুন।',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      itemCount: messages.length,
                      itemBuilder: (context, i) => _Bubble(
                        msg: messages[i],
                        mine: messages[i].from == _user?.uid,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                child: _lockedComposer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lockedComposer() {
    final phone = _request?.requesterPhone ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lock_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'মেসেজ লেখা লক করা আছে (ফ্রি প্ল্যানে কোটা বাঁচাতে)। যোগাযোগের জন্য:',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _lockAction(
                    icon: Icons.phone_in_talk,
                    color: AppColors.normal,
                    label: 'কল করুন',
                    onTap: () => _call(phone),
                  ),
                ),
                if (_waOk) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _lockAction(
                      icon: Icons.chat_rounded,
                      color: AppColors.normal,
                      label: 'WhatsApp',
                      onTap: () => _wa(phone),
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

  Widget _lockAction({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.mine});

  final ChatMessage msg;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final color = mine ? AppColors.primary : AppColors.surfaceHigh;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(13, 9, 13, 7),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!mine) ...[
              Text(
                msg.fromName,
                style: const TextStyle(
                  color: AppColors.info,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
            ],
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 3),
            Text(
              _time(msg.createdAt),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
