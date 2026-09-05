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
    Navigator.pop(context); // Close drawer (no-op if not open)
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Desktop: permanent sidebar
        if (width >= 900) {
          final extended = width >= 1100;
          return Scaffold(
            appBar: AppBar(
              title: Text(currentItem.label),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh,
                  tooltip: 'Rafraichir',
                ),
              ],
            ),
            body: Row(
              children: [
                _buildSidebar(context, extended: extended),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: currentScreen),
              ],
            ),
            floatingActionButton: (canWrite && currentItem.id != 'dashboard')
                ? FloatingActionButton.extended(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ajout - bientot disponible')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  )
                : null,
          );
        }

        // Mobile / tablet: drawer
        return Scaffold(
          appBar: AppBar(
            title: Text(currentItem.label),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refresh,
                tooltip: 'Rafraichir',
              ),
            ],
          ),
          drawer: Drawer(child: _buildSidebar(context, extended: true)),
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
      },
    );
  }

  Widget _buildSidebar(BuildContext context, {required bool extended}) {
    return Container(
      width: extended ? 260 : 72,
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: extended
                ? const EdgeInsets.fromLTRB(16, 24, 16, 20)
                : const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(color: Color(0xFF1B5E20)),
            child: extended
                ? Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        child: Text(
                          widget.profile.fullName.isNotEmpty
                              ? widget.profile.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.profile.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _roleLabel(widget.profile.role),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Text(
                          widget.profile.fullName.isNotEmpty
                              ? widget.profile.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFF1B5E20),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final selected = index == _currentIndex;
                return extended
                    ? ListTile(
                        leading: Icon(
                          _getIcon(item.icon),
                          color: selected ? const Color(0xFF1B5E20) : Colors.grey.shade600,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: selected ? const Color(0xFF1B5E20) : Colors.grey.shade800,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                        selected: selected,
                        selectedTileColor: const Color(0xFF1B5E20).withOpacity(0.08),
                        onTap: () => _navigateTo(index),
                      )
                    : InkWell(
                        onTap: () => _navigateTo(index),
                        child: Container(
                          height: 64,
                          alignment: Alignment.center,
                          color: selected ? const Color(0xFF1B5E20).withOpacity(0.08) : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getIcon(item.icon),
                                color: selected ? const Color(0xFF1B5E20) : Colors.grey.shade600,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: selected ? const Color(0xFF1B5E20) : Colors.grey.shade600,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
              },
            ),
          ),
          const Divider(height: 1),
          // Logout
          extended
              ? ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Deconnexion', style: TextStyle(color: Colors.red, fontSize: 14)),
                  onTap: () async {
                    await AuthService.signOut();
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red, size: 22),
                  tooltip: 'Deconnexion',
                  onPressed: () async {
                    await AuthService.signOut();
                  },
                ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    const labels = {
      'admin': 'Administrateur',
      'directeur': 'Directeur',
      'chef_agricole': 'Chef Agricole',
      'agent_qualite': 'Agent Qualite',
      'agent_rh': 'Agent RH',
      'agent_maintenance': 'Agent Maintenance',
      'agent_distribution': 'Agent Distribution',
      'agent_terrain': 'Agent Terrain',
    };
    return labels[role] ?? role;
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
