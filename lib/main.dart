import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_gen/core/widgets/navigation.dart';
import 'package:ticket_gen/core/utils/splash_decider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'Enter her your Supbase URl',
    anonKey: 'Enter her your Supabase Anon Key',
    debug: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fault Reporting App',
      theme: ThemeData(primarySwatch: Colors.blue),
      onGenerateRoute: AppRoutes.generateRoute,
      home: const SplashDecider(),
    );
  }
}
