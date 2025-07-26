import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'email_notification_service.dart';

class TicketService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final Logger _logger = Logger();

  static Future<Map<String, dynamic>?> createTicketWithNotification({
    required String userId,
    required String title,
    required String description,
    required String location,
    required String priority,
  }) async {
    try {
      final userResponse = await _supabase
          .from('users')
          .select('name, email, department')
          .eq('id', userId)
          .single();
      final userName = userResponse['name'] ?? 'Unknown User';
      final userEmail =
          (userResponse['email'] as String?) ?? 'no-email@example.com';
      final userDepartment = userResponse['department'] ?? 'Not specified';

      final ticketResponse = await _supabase
          .from('tickets')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'location': location,
            'priority': priority.toLowerCase(),
            'status': 'pending',
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final ticketId = ticketResponse['id'];

      EmailNotificationService.sendNewTicketNotification(
        ticketId: ticketId,
        ticketTitle: title,
        ticketDescription: description,
        userEmail: userEmail,
        userName: userName,
        priority: priority,
        location: location,
        department: userDepartment,
      ).catchError((error) {
        _logger.e(
          'Email notification failed but ticket was created',
          error: error,
        );
        return false;
      });

      _logger.i('Ticket created successfully: $ticketId');
      return ticketResponse;
    } catch (error, stackTrace) {
      _logger.e(
        'Error creating ticket',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<bool> updateTicketWithNotification({
    required String ticketId,
    required String userId,
    required String ticketTitle,
    required String newStatus,
    required String newPriority,
  }) async {
    try {
      await _supabase.from('tickets').update({
        'status': newStatus.toLowerCase(),
        'priority': newPriority.toLowerCase(),
      }).eq('id', ticketId);

      final userResponse = await _supabase
          .from('users')
          .select('name, email')
          .eq('id', userId)
          .single();
      final userName = userResponse['name'] ?? 'User';
      final userEmail =
          (userResponse['email'] as String?) ?? 'no-reply@example.com';

      EmailNotificationService.sendTicketUpdateNotification(
        ticketId: ticketId,
        ticketTitle: ticketTitle,
        userEmail: userEmail,
        userName: userName,
        newStatus: newStatus,
        newPriority: newPriority,
      ).catchError((error) {
        _logger.e(
          'Email notification failed but ticket was updated',
          error: error,
        );
        return false;
      });

      await _supabase.from('notifications').insert({
        'user_id': userId,
        'message': 'Your ticket "$ticketTitle" is now marked as "$newStatus".',
      });

      _logger.i('Ticket $ticketId updated successfully to status: $newStatus');
      return true;
    } catch (error, stackTrace) {
      _logger.e(
        'Error updating ticket',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
