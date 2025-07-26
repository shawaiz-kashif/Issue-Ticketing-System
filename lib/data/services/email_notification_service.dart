import 'dart:convert'; // Required for jsonEncode
import 'package:http/http.dart' as http; // Import http package
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailNotificationService {
  static const String serviceId = 'service_fkp3f3j';
  static const String templateId = 'template_p623yki';
  static const String publicKey =
      'rgn_CcPiyDnuqsemE'; // This is the EmailJS Public Key
  static const String emailJsApiUrl =
      'https://api.emailjs.com/api/v1.0/email/send';

  static final Logger _logger = Logger();

  static Future<bool> sendNewTicketNotification({
    required String ticketId,
    required String ticketTitle,
    required String ticketDescription,
    required String userEmail,
    required String userName,
    required String priority,
    required String location,
    required String department,
  }) async {
    try {
      final adminResponse = await Supabase.instance.client
          .from('users')
          .select('email, name')
          .eq('role', 'admin')
          .limit(1)
          .single();

      final adminEmail = adminResponse['email'] ?? 'admin@yourcompany.com';
      final adminName = adminResponse['name'] ?? 'Admin';

      final Map<String, dynamic> templateParams = {
        'to_email': adminEmail,
        'to_name': adminName,
        'ticket_id': ticketId,
        'ticket_title': ticketTitle,
        'ticket_description': ticketDescription,
        'user_email': userEmail,
        'user_name': userName,
        'priority': priority,
        'location': location,
        'department': department,
        'created_at': DateTime.now().toIso8601String(),
        'dashboard_url':
            'https://yourapp.com/admin/tickets/$ticketId', // Replace with your actual URL
      };

      final requestBody = jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': templateParams,
      });

      _logger.d('EmailJS Request URL: $emailJsApiUrl');
      _logger.d('EmailJS Request Headers: {Content-Type: application/json}');
      _logger.d('EmailJS Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(emailJsApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      _logger.d('EmailJS Response Status Code: ${response.statusCode}');
      _logger.d('EmailJS Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _logger.i(
            '✅ Admin email notification sent successfully for ticket: $ticketId');
        return true;
      } else {
        _logger.e(
          '❌ Failed to send admin email notification.',
          error: 'Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (error, stackTrace) {
      _logger.e('❌ Error sending admin email notification',
          error: error, stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> sendTicketUpdateNotification({
    required String ticketId,
    required String ticketTitle,
    required String userEmail,
    required String userName,
    required String newStatus,
    required String newPriority,
  }) async {
    try {
      final Map<String, dynamic> templateParams = {
        'to_email': userEmail,
        'to_name': userName,
        'ticket_id': ticketId,
        'ticket_title': ticketTitle,
        'new_status': newStatus,
        'new_priority': newPriority,
        'updated_at': DateTime.now().toIso8601String(),
      };

      const String updateTemplateId = 'template_p623yki';

      final requestBody = jsonEncode({
        'service_id': serviceId,
        'template_id': updateTemplateId,
        'user_id': publicKey,
        'template_params': templateParams,
      });

      _logger.d('EmailJS Update Request URL: $emailJsApiUrl');
      _logger.d(
          'EmailJS Update Request Headers: {Content-Type: application/json}');
      _logger.d('EmailJS Update Request Body: $requestBody');

      final response = await http.post(
        Uri.parse(emailJsApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      _logger.d('EmailJS Update Response Status Code: ${response.statusCode}');
      _logger.d('EmailJS Update Response Body: ${response.body}');

      if (response.statusCode == 200) {
        _logger.i(
            '✅ User email notification sent successfully for ticket update: $ticketId');
        return true;
      } else {
        _logger.e(
            '❌ Failed to send user email notification. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (error, stackTrace) {
      _logger.e('❌ Error sending user email notification',
          error: error, stackTrace: stackTrace);
      return false;
    }
  }
}
