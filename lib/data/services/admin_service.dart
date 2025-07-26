import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_gen/widgets/user_profile.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  final logger = Logger();

  // Check if user already exists
  Future<bool> userExists(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      logger.e('Error checking if user exists', error: e);
      return false;
    }
  }

  // This Create a new user with better error handling
  Future<UserProfile?> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
    required String department,
  }) async {
    try {
      //This Line Checks if user already exists first
      final exists = await userExists(email);
      if (exists) {
        throw Exception('A user with email "$email" already exists');
      }

      final response = await _supabase.functions.invoke(
        'create-user',
        body: {
          'email': email,
          'password': password,
          'name': name,
          'role': role,
          'department': department,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        String errorMessage = 'Failed to create user';

        if (errorData != null && errorData['error'] != null) {
          final error = errorData['error'].toString();

          // Customize error messages for better UX
          if (error.contains('already been registered')) {
            errorMessage = 'A user with this email address already exists';
          } else if (error.contains('Invalid email')) {
            errorMessage = 'Please enter a valid email address';
          } else if (error.contains('Password')) {
            errorMessage = 'Password must be at least 6 characters long';
          } else {
            errorMessage = error;
          }
        }

        throw Exception(errorMessage);
      }

      // Refresh users list to get the new user
      final users = await getAllUsers();
      return users.firstWhere(
        (user) => user.email == email,
        orElse: () => throw Exception('User created but not found in database'),
      );
    } catch (e) {
      logger.e('Error creating user', error: e);
      rethrow;
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      final response = await _supabase.functions.invoke(
        'update-user-role',
        body: {
          'userId': userId,
          'newRole': newRole,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        String errorMessage = 'Failed to update user role';

        if (errorData != null && errorData['error'] != null) {
          errorMessage = errorData['error'].toString();
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      logger.e('Error updating user role', error: e);
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'delete-user',
        body: {
          'userId': userId,
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        String errorMessage = 'Failed to delete user';

        if (errorData != null && errorData['error'] != null) {
          errorMessage = errorData['error'].toString();
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      logger.e('Error deleting user', error: e);
      rethrow;
    }
  }

  Future<List<UserProfile>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((user) => UserProfile.fromJson(user))
          .toList();
    } catch (e) {
      logger.e('Error fetching users', error: e);
      rethrow;
    }
  }
}
