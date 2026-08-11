import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/nav_config.dart';
import 'dashboard_screen.dart';
import 'data_table_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile profile;

  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<NavItem> _navItems;
  int _currentIndex = 0;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _navItems = NavConfig.getNavForRole(widget.profile.role);
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
    Navigator.pop(context); // Close drawer
  }

  void _refresh() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _navItems[_currentIndex];
    final isAdmin = ['admin', 'directeur'].contains(widget.profile.role);
    final canWrite = isAdmin;

    Widget currentScreen;
    if (currentItem.id == 'dashboard') {
      currentScreen = DashboardScreen(profile: widget.profile, key: ValueKey('dashboard_$_refreshKey'));
    } else {
      currentScreen = DataTableScreen(
        key: ValueKey('${currentItem.id}_$_refreshKey'),
        navItem: currentItem,
        canWrite: canWrite,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentItem.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1B5E20)),
              accountName: Text(widget.profile.fullName),
              accountEmail: Text(widget.profile.email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.profile.fullName.isNotEmpty
                      ? widget.profile.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  return ListTile(
                    leading: Icon(_getIcon(item.icon)),
                    title: Text(item.label),
                    selected: index == _currentIndex,
                    selectedTileColor: const Color(0xFF1B5E20).withOpacity(0.1),
                    onTap: () => _navigateTo(index),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Deconnexion', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await AuthService.signOut();
                // AuthGate listens to onAuthStateChange and will
                // automatically show the login screen.
              },
            ),
          ],
        ),
      ),
      body: currentScreen,
      floatingActionButton: (canWrite && currentItem.id != 'dashboard')
          ? FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ajout - bientot disponible')),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  IconData _getIcon(String name) {
    const icons = {
      'dashboard': Icons.dashboard,
      'grass': Icons.grass,
      'factory': Icons.factory,
      'verified': Icons.verified,
      'shopping_cart': Icons.shopping_cart,
      'local_shipping': Icons.local_shipping,
      'people': Icons.people,
      'schedule': Icons.schedule,
      'payments': Icons.payments,
      'beach_access': Icons.beach_access,
      'school': Icons.school,
      'precision_manufacturing': Icons.precision_manufacturing,
      'build': Icons.build,
      'account_balance': Icons.account_balance,
      'inventory': Icons.inventory,
      'science': Icons.science,
      'cloud': Icons.cloud,
      'agriculture': Icons.agriculture,
      'assignment': Icons.assignment,
      'biotech': Icons.biotech,
      'edit_note': Icons.edit_note,
      'folder': Icons.folder,
    };
    return icons[name] ?? Icons.circle;
  }
}
