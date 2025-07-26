import 'package:flutter/material.dart';
import 'package:ticket_gen/screens/Admin%20Dashboard%20Screens/admin_dashboard.dart';
import 'package:ticket_gen/features/auth/presentation/login_screen.dart';
import 'package:ticket_gen/user/presentation/pages/user_home_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String userhomepage = '/user-home-page';
  static const String adminPanel = '/admin';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case userhomepage:
        return MaterialPageRoute(builder: (_) => const UserHomePage());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('No route defined for \${settings.name}')),
          ),
        );
    }
  }
}
