import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  final UserProfile profile;
  const DashboardScreen({super.key, required this.profile});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  final Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentProduction = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final client = SupabaseService.client;
      final role = widget.profile.role;
      final isAdmin = ['admin', 'directeur', 'chef_agricole', 'chef_production'].contains(role);

      if (isAdmin) {
        // Fetch stats in parallel
        final results = await Future.wait([
          client.from('parcelles').select('superficie_ha').then((r) => r),
          client.from('production_journaliere').select('canne_broyee_t').order('date_prod', ascending: false).limit(7).then((r) => r),
          client.from('employes').select('id').then((r) => r),
          client.from('stocks_produits').select('quantite_t').then((r) => r),
        ]);

        double totalSuperficie = 0;
        for (var row in results[0] as List) {
          totalSuperficie += (row['superficie_ha'] as num?)?.toDouble() ?? 0;
        }

        double totalCanne = 0;
        for (var row in results[1] as List) {
          totalCanne += (row['canne_broyee_t'] as num?)?.toDouble() ?? 0;
        }

        _stats['superficie'] = totalSuperficie.toStringAsFixed(0);
        _stats['canne_7j'] = totalCanne.toStringAsFixed(0);
        _stats['employes'] = (results[2] as List).length.toString();
        
        double totalStock = 0;
        for (var row in results[3] as List) {
          totalStock += (row['quantite_t'] as num?)?.toDouble() ?? 0;
        }
        _stats['stocks'] = totalStock.toStringAsFixed(0);

        // Recent production
        final prodResult = await client
            .from('production_journaliere')
            .select()
            .order('date_prod', ascending: false)
            .limit(7);
        _recentProduction = List<Map<String, dynamic>>.from(prodResult);
      } else {
        // Limited stats for field agents
        final parcelles = await client.from('parcelles').select('superficie_ha,statut');
        double totalSup = 0;
        int actives = 0;
        for (var row in parcelles as List) {
          totalSup += (row['superficie_ha'] as num?)?.toDouble() ?? 0;
          if (row['statut'] == 'actif' || row['statut'] == 'Actif') actives++;
        }
        _stats['superficie'] = totalSup.toStringAsFixed(0);
        _stats['parcelles_actives'] = actives.toString();
        
        final meteo = await client
            .from('donnees_meteo')
            .select()
            .order('date_observation', ascending: false)
            .limit(1);
        if (meteo.isNotEmpty) {
          _stats['temp'] = '${(meteo[0]['temperature_c'] ?? 0)}°C';
          _stats['conditions'] = meteo[0]['conditions'] ?? '-';
        }
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isAdmin = ['admin', 'directeur', 'chef_agricole', 'chef_production'].contains(widget.profile.role);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: isAdmin ? _adminStatCards() : _agentStatCards(),
          ),
          if (isAdmin && _recentProduction.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Production récente (7 jours)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Canne (t)'), numeric: true),
                      DataColumn(label: Text('Sucre blanc (t)'), numeric: true),
                      DataColumn(label: Text('Sucre roux (t)'), numeric: true),
                      DataColumn(label: Text('Rendement'), numeric: true),
                    ],
                    rows: _recentProduction.map((p) {
                      return DataRow(cells: [
                        DataCell(Text(p['date_prod']?.toString().substring(0, 10) ?? '-')),
                        DataCell(Text('${p['canne_broyee_t'] ?? 0}')),
                        DataCell(Text('${p['sucre_blanc_t'] ?? 0}')),
                        DataCell(Text('${p['sucre_roux_t'] ?? 0}')),
                        DataCell(Text('${p['rendement_pct'] ?? 0}%')),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _adminStatCards() {
    return [
      _statCard('Superficie totale', '${_stats['superficie'] ?? 0} ha', Icons.grass),
      _statCard('Canne brûlée (7j)', '${_stats['canne_7j'] ?? 0} t', Icons.factory),
      _statCard('Employés', '${_stats['employes'] ?? 0}', Icons.people),
      _statCard('Stocks', '${_stats['stocks'] ?? 0} t', Icons.inventory),
    ];
  }

  List<Widget> _agentStatCards() {
    return [
      _statCard('Superficie', '${_stats['superficie'] ?? 0} ha', Icons.grass),
      _statCard('Parcelles actives', '${_stats['parcelles_actives'] ?? 0}', Icons.eco),
      _statCard('Température', _stats['temp'] ?? '-', Icons.thermostat),
      _statCard('Conditions', _stats['conditions'] ?? '-', Icons.cloud),
    ];
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1B5E20), size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
