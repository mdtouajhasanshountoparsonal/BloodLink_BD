import 'package:url_launcher/url_launcher.dart';

/// যোগাযোগ: সরাসরি কল + WhatsApp (ফ্রি প্ল্যানে মেসেজিং বন্ধ — তাই মেসেজ দরকার হলে
/// নম্বরে WhatsApp থাকলে ব্যবহার হয়)।
class ContactService {
  ContactService._();
  static final ContactService instance = ContactService._();

  /// কল করার URI
  Uri callUri(String phone) => Uri(scheme: 'tel', path: phone);

  bool isValidPhone(String phone) => phone.trim().isNotEmpty;

  /// WhatsApp-এর জন্য আন্তর্জাতিক ফরম্যাট (BD: 0XX... → 880XX...)
  String waNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (digits.length == 11 && digits.startsWith('01')) return '88$digits';
    if (digits.length == 10 && digits.startsWith('1')) return '880$digits';
    return digits;
  }

  /// অ্যাপে WhatsApp আছে কি না (নম্বরে অ্যাকাউন্ট আছে কি না জানা যায় না —
  /// খুললে নিজেই জানাবে)
  Future<bool> whatsappInstalled() async {
    try {
      return await canLaunchUrl(Uri(scheme: 'whatsapp', host: '', path: 'send'));
    } catch (_) {
      return false;
    }
  }

  Future<bool> openWhatsapp(String phone, {String? text}) async {
    final num = waNumber(phone);
    if (num.isEmpty) return false;
    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/$num',
      queryParameters: text == null || text.isEmpty ? null : {'text': text},
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}