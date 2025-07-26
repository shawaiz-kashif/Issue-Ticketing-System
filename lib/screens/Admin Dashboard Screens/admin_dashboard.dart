import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_gen/screens/Admin%20Dashboard%20Screens/create_user_id.dart';
import 'package:ticket_gen/screens/Admin%20Dashboard%20Screens/general_page.dart';
import 'package:ticket_gen/screens/Admin%20Dashboard%20Screens/reports_page.dart';
import 'package:ticket_gen/screens/Admin%20Dashboard%20Screens/settings_page.dart';
import 'package:ticket_gen/screens/Admin%20Dashboard%20Screens/ticket_page.dart';
import 'package:ticket_gen/widgets/sidebar_menu_item.dart'; // Keep this import

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  int _selectedIndex = 0;
  // Removed: bool _isCollapsed = false; // No longer needed
  // _hoveredIndex is managed locally by SidebarMenuItem

  // Animation controllers
  late AnimationController _pageTransitionController;
  // Removed: late AnimationController _sidebarController; // No longer needed
  // _menuItemController is removed as its animations are handled by TweenAnimationBuilder in SidebarMenuItem

  // Animations
  late Animation<double> _pageSlideAnimation;
  late Animation<double> _pageFadeAnimation;

  final List<String> menuItems = const [
    'General',
    'Tickets',
    'Users',
    'Reports',
    'Settings',
  ];
  final List<IconData> menuIcons = const [
    Icons.dashboard_outlined,
    Icons.confirmation_number_outlined,
    Icons.engineering_outlined,
    Icons.analytics_outlined,
    Icons.settings_outlined,
  ];
  final List<IconData> menuIconsFilled = const [
    Icons.dashboard,
    Icons.confirmation_number,
    Icons.engineering,
    Icons.analytics,
    Icons.settings,
  ];

  late final List<Widget> pages = const [
    GeneralPage(),
    TicketPage(),
    CreateUserId(),
    ReportsPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pageSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeOutCubic,
    ));
    _pageFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageTransitionController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    _pageTransitionController.forward();
  }

  @override
  void dispose() {
    _pageTransitionController.dispose();
    super.dispose();
  }

  void _onMenuItemTap(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
      _pageTransitionController.reset();
      _pageTransitionController.forward();
    }
  }

  // Removed: void _toggleSidebar() method

  void _logout() async {
    await supabase.auth.signOut();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? user?.email ?? 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        // Keep Row for sidebar + main content layout
        children: [
          // Fixed-width Sidebar (always expanded)
          Container(
            // Changed from AnimatedContainer as width is fixed
            width: 280, // Fixed width, no longer dependent on _isCollapsed
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header (no collapse animation)
                Container(
                  // Changed from AnimatedContainer
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 500),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1 * value),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white.withOpacity(value),
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // Admin Panel text is always visible
                      const Expanded(
                        child: Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Removed: IconButton for _toggleSidebar
                      // If you want a static menu icon here, you can add it:
                      // const Icon(Icons.menu, color: Colors.white),
                    ],
                  ),
                ),
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.white24), // Simpler divider
                // Menu Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: menuItems.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return SidebarMenuItem(
                        title: menuItems[index],
                        icon: menuIcons[index],
                        filledIcon: menuIconsFilled[index],
                        isSelected: _selectedIndex == index,
                        onTap: () => _onMenuItemTap(index),
                        index: index,
                      );
                    },
                  ),
                ),
                // User Info (always visible, no collapsed state)
                Container(
                  // Changed from AnimatedContainer
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.5 + (0.5 * value),
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              radius: 18,
                              child: Text(
                                userName.isNotEmpty
                                    ? userName.substring(0, 1).toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              child: Text(
                                userName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const Text(
                              'Administrator',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area with Animations
          Expanded(
            child: Column(
              children: [
                // Enhanced Animated App Bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.3, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    menuItems[_selectedIndex],
                                    key: ValueKey(_selectedIndex),
                                    style: TextStyle(
                                      fontSize: isNarrow ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1F2937),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (!isNarrow)
                                  Text(
                                    'IT Fault Management System',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                              ],
                            ),
                          ),
                          // Right side with animations - Wrapped in Flexible to prevent overflow
                          Flexible(
                            // This Flexible is crucial for preventing overflow in the app bar
                            child: isNarrow
                                ? AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      onPressed: _logout,
                                      icon: Icon(
                                        Icons.logout,
                                        color: Colors.red.shade600,
                                      ),
                                      tooltip: 'Logout',
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TweenAnimationBuilder<double>(
                                        duration:
                                            const Duration(milliseconds: 800),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Transform.translate(
                                            offset: Offset(30 * (1 - value), 0),
                                            child: AnimatedOpacity(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              opacity: value,
                                              child: Container(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 200),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF667EEA)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.person,
                                                      size: 14,
                                                      color: Color(0xFF667EEA),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        'Welcome, $userName',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color:
                                                              Color(0xFF667EEA),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          onPressed: _logout,
                                          icon: Icon(
                                            Icons.logout,
                                            color: Colors.red.shade600,
                                          ),
                                          tooltip: 'Logout',
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Animated Page Content
                Expanded(
                  child: AnimatedBuilder(
                    animation: _pageTransitionController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          30 * (1 - _pageSlideAnimation.value),
                          0,
                        ),
                        child: FadeTransition(
                          opacity: _pageFadeAnimation,
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: pages,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
