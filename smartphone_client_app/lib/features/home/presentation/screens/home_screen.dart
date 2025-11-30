import 'package:flutter/material.dart';
import 'package:smartphone_client_app/features/auth/data/models/user.dart';
import 'package:smartphone_client_app/core/security/secure_storage_service.dart';
import '../widgets/access_tab.dart';
import '../widgets/history_tab.dart';
import '../widgets/management_tab.dart';
import '../widgets/account_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  late PageController _pageController;

  final SecureStorageService _secureStorageService = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadUserRole();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Load user role from secure storage to determine if user is admin
  Future<void> _loadUserRole() async {
    try {
      final userJson = await _secureStorageService.getUserData();
      if (userJson != null) {
        final user = User.fromJson(userJson);
        setState(() {
          _isAdmin = user.role == 'admin';
        });
      }
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  /// Called when user taps a bottom navigation item
  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Called when user swipes to change pages
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Get the list of tabs based on user role
  /// Regular users: Access, History, Account
  /// Admin users: Access, History, Management, Account
  List<Widget> _getTabs() {
    if (_isAdmin) {
      return const [AccessTab(), HistoryTab(), ManagementTab(), AccountTab()];
    } else {
      return const [AccessTab(), HistoryTab(), AccountTab()];
    }
  }

  /// Get bottom navigation bar items based on user role
  List<BottomNavigationBarItem> _getNavItems() {
    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.door_sliding),
        label: 'Access',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'History',
      ),
    ];

    // Add Management tab for admins
    if (_isAdmin) {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Management',
        ),
      );
    }

    // Add Account tab last (for all users)
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.account_circle),
        label: 'Account',
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabs();

    return Scaffold(
      body: SafeArea(
        bottom: false, // Let content scroll under bottom nav
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: tabs,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: _getNavItems(),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
