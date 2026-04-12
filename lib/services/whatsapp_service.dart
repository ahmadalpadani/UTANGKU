import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import '../models/debt_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class WhatsAppService {
  // Open WhatsApp with pre-filled message
  Future<void> sendReminder(DebtModel debt) async {
    if (debt.phoneNumber == null || debt.phoneNumber!.isEmpty) {
      throw Exception('Nomor telepon tidak tersedia');
    }

    final message = _generateReminderMessage(debt);
    final link = WhatsAppUnilink(
      phoneNumber: debt.phoneNumber!,
      text: message,
    );

    try {
      await launchUrl(link.asUri());
    } catch (e) {
      throw Exception('Gagal membuka WhatsApp: $e');
    }
  }

  // Generate reminder message
  String _generateReminderMessage(DebtModel debt) {
    final amount = debt.formattedAmount;
    final dueDate = debt.dueDate != null
        ? DateFormatter.formatDate(debt.dueDate!)
        : 'segera';

    String message = AppConstants.defaultReminderMessage;
    message = message.replaceAll('{name}', debt.name);
    message = message.replaceAll('{amount}', amount);
    message = message.replaceAll('{due_date}', dueDate);

    return message;
  }

  // Open WhatsApp chat without message
  Future<void> openChat(String phoneNumber) async {
    final link = WhatsAppUnilink(
      phoneNumber: phoneNumber,
      text: '',
    );

    try {
      await launchUrl(link.asUri());
    } catch (e) {
      throw Exception('Gagal membuka WhatsApp: $e');
    }
  }

  // Format phone number to international format (62 for Indonesia)
  String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If starts with 0, replace with 62
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    }

    // If doesn't start with 62, add it
    if (!cleaned.startsWith('62')) {
      cleaned = '62$cleaned';
    }

    return cleaned;
  }

  // Validate phone number
  bool isValidPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length >= 10 && cleaned.length <= 15;
  }
}
