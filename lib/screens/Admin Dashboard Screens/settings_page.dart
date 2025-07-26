import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final SupabaseClient _supabaseClient;
  late final TabController _tabController;

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  late final ValueNotifier<ScreenSize> _screenSize;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _supabaseClient = Supabase.instance.client;
    _tabController = TabController(length: 1, vsync: this);

    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _screenSize = ValueNotifier<ScreenSize>(ScreenSize.mobile);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateScreenSize();
  }

  void _updateScreenSize() {
    final width = MediaQuery.of(context).size.width;
    final newSize = width < 600
        ? ScreenSize.mobile
        : width > 768
            ? ScreenSize.tablet
            : ScreenSize.desktop;

    if (_screenSize.value != newSize) {
      _screenSize.value = newSize;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _isLoading.dispose();
    _screenSize.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) return;

      final response = await _supabaseClient
          .from('users')
          .select('name, email')
          .eq('id', user.id)
          .single();

      if (mounted) {
        _nameController.text = response['name'] ?? '';
        _emailController.text = response['email'] ?? user.email ?? '';
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading profile: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Name cannot be empty', isError: true);
      return;
    }

    _isLoading.value = true;

    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) return;

      await _supabaseClient.from('users').update({
        'name': name,
        'email': _emailController.text.trim(),
      }).eq('id', user.id);

      if (mounted) {
        _showSnackBar('Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating profile: ${e.toString()}', isError: true);
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate inputs
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar('All password fields are required', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }

    _isLoading.value = true;

    try {
      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        _showSnackBar('Password changed successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error changing password: ${e.toString()}',
            isError: true);
      }
    } finally {
      _isLoading.value = false;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return ValueListenableBuilder<ScreenSize>(
      valueListenable: _screenSize,
      builder: (context, screenSize, child) {
        return Container(
          key: const ValueKey('settings'),
          child: Column(
            children: [
              _SettingsHeader(screenSize: screenSize),
              _SettingsTabBar(
                tabController: _tabController,
                screenSize: screenSize,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ProfileTabContent(
                      screenSize: screenSize,
                      nameController: _nameController,
                      emailController: _emailController,
                      currentPasswordController: _currentPasswordController,
                      newPasswordController: _newPasswordController,
                      confirmPasswordController: _confirmPasswordController,
                      isLoading: _isLoading,
                      onUpdateProfile: _updateProfile,
                      onChangePassword: _changePassword,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum ScreenSize { mobile, tablet, desktop }

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.screenSize});

  final ScreenSize screenSize;

  @override
  Widget build(BuildContext context) {
    final isMobile = screenSize == ScreenSize.mobile;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.settings_outlined,
            color: Color(0xFF667EEA),
            size: 28,
          ),
          SizedBox(width: 12),
          Text(
            'System Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}

class _SettingsTabBar extends StatelessWidget {
  const _SettingsTabBar({
    required this.tabController,
    required this.screenSize,
  });

  final TabController tabController;
  final ScreenSize screenSize;

  @override
  Widget build(BuildContext context) {
    final isMobile = screenSize == ScreenSize.mobile;

    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        labelColor: const Color(0xFF667EEA),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF667EEA),
        isScrollable: isMobile,
        tabs: const [
          Tab(icon: Icon(Icons.person), text: 'Profile'),
        ],
      ),
    );
  }
}

class _ProfileTabContent extends StatelessWidget {
  const _ProfileTabContent({
    required this.screenSize,
    required this.nameController,
    required this.emailController,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.onUpdateProfile,
    required this.onChangePassword,
  });

  final ScreenSize screenSize;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final ValueNotifier<bool> isLoading;
  final VoidCallback onUpdateProfile;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    final isMobile = screenSize == ScreenSize.mobile;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileInformationCard(
            nameController: nameController,
            emailController: emailController,
            isLoading: isLoading,
            onUpdateProfile: onUpdateProfile,
          ),
          const SizedBox(height: 20),
          _ChangePasswordCard(
            currentPasswordController: currentPasswordController,
            newPasswordController: newPasswordController,
            confirmPasswordController: confirmPasswordController,
            isLoading: isLoading,
            onChangePassword: onChangePassword,
          ),
        ],
      ),
    );
  }
}

class _ProfileInformationCard extends StatelessWidget {
  const _ProfileInformationCard({
    required this.nameController,
    required this.emailController,
    required this.isLoading,
    required this.onUpdateProfile,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final ValueNotifier<bool> isLoading;
  final VoidCallback onUpdateProfile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, loading, child) {
                  return ElevatedButton.icon(
                    onPressed: loading ? null : onUpdateProfile,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Update Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordCard extends StatelessWidget {
  const _ChangePasswordCard({
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isLoading,
    required this.onChangePassword,
  });

  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final ValueNotifier<bool> isLoading;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, loading, child) {
                  return ElevatedButton.icon(
                    onPressed: loading ? null : onChangePassword,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.security),
                    label: const Text('Change Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
