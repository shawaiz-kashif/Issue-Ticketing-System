import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_gen/core/widgets/navigation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for local storage

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _rememberMe = false; // New state for remember me checkbox
  late SharedPreferences _prefs; // SharedPreferences instance

  late final AnimationController _animationController;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences(); // Initialize SharedPreferences and load saved data
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/background.jpg'), context);
      precacheImage(const AssetImage('assets/logo.png'), context);
    });
  }

  // Method to initialize SharedPreferences and load saved email/rememberMe state
  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final savedEmail = _prefs.getString('remembered_email');
    final savedRememberMe = _prefs.getBool('remember_me') ?? false;

    if (savedEmail != null && savedRememberMe) {
      _emailController.text = savedEmail;
      setState(() {
        _rememberMe = savedRememberMe;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final userId = res.user?.id;
      if (userId == null) throw 'User not found';

      // Save or remove email based on the "Remember Me" checkbox state
      if (_rememberMe) {
        await _prefs.setString(
            'remembered_email', _emailController.text.trim());
        await _prefs.setBool('remember_me', true);
      } else {
        await _prefs.remove('remembered_email');
        await _prefs.setBool('remember_me', false);
      }

      final userResponse = await supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      final role = userResponse?['role'];
      if (!mounted) return;
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else if (role == 'user') {
        Navigator.pushReplacementNamed(context, AppRoutes.userhomepage);
      } else {
        throw 'Access denied: Unknown role.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 400 : double.infinity,
                    ),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white.withOpacity(0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              height: 80,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!_isLoading) {
                                  _login();
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (bool? newValue) {
                                    setState(() {
                                      _rememberMe = newValue ?? false;
                                    });
                                  },
                                ),
                                const Text('Remember Me'),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
