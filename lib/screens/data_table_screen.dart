import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/nav_config.dart';

class DataTableScreen extends StatefulWidget {
  final NavItem navItem;
  final bool canWrite;

  const DataTableScreen({super.key, required this.navItem, required this.canWrite});

  @override
  State<DataTableScreen> createState() => _DataTableScreenState();
}

class _DataTableScreenState extends State<DataTableScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _data = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await SupabaseService.client
          .from(widget.navItem.table)
          .select()
          .order('created_at', ascending: false)
          .limit(200);

      setState(() {
        _data = List<Map<String, dynamic>>.from(result);
        _filteredData = _data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredData = _data;
      } else {
        _filteredData = _data.where((row) {
          return row.values.any((v) => v.toString().toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  Color _getStatusColor(String statut) {
    final positive = ['actif', 'present', 'livree', 'terminee', 'validee', 'payee', 'approuve', 'certifie', 'excellent', 'bon', 'oui', 'conforme', 'true'];
    final negative = ['alerte', 'critique', 'retard', 'suspendu', 'annulee', 'refuse', 'mauvais', 'hors_service', 'non', 'non conforme', 'false'];
    final lower = statut.toLowerCase();
    if (positive.contains(lower)) return const Color(0xFF2E7D32);
    if (negative.contains(lower)) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final columns = widget.navItem.columns;
    final isWide = MediaQuery.of(context).size.width > 600;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () { _searchController.clear(); _filter(''); },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        
        if (_filteredData.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'Aucune donnée disponible',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ),
          )
        else if (isWide)
          // Table view on wide screens
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      ...columns.map((c) => DataColumn(
                        label: Text(
                          NavConfig.getLabel(c),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )),
                      if (widget.canWrite)
                        const DataColumn(label: Text('Actions')),
                    ],
                    rows: _filteredData.map((row) {
                      return DataRow(
                        cells: [
                          ...columns.map((c) {
                            final val = row[c];
                            String display = val?.toString() ?? '-';
                            if (val is bool) display = val ? 'Oui' : 'Non';
                            
                            if (c == 'statut' || c == 'etat' || c == 'etat_global' || c == 'statut_qualite' || c == 'conforme') {
                              if (val != null) {
                                return DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(display).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      display,
                                      style: TextStyle(
                                        color: _getStatusColor(display),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                            return DataCell(Text(display));
                          }),
                          if (widget.canWrite)
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => _showEditDialog(row),
                                    tooltip: 'Modifier',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                    onPressed: () => _confirmDelete(row),
                                    tooltip: 'Supprimer',
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          )
        else
          // Card list view on narrow screens
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filteredData.length,
              itemBuilder: (context, index) {
                final row = _filteredData[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    title: Text(
                      row[columns.first]?.toString() ?? 'Sans titre',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: columns.length > 1
                        ? Text(
                            '${columns[1]}: ${row[columns[1]] ?? '-'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          )
                        : null,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: columns.map((c) {
                            final val = row[c];
                            String display = val?.toString() ?? '-';
                            if (val is bool) display = val ? 'Oui' : 'Non';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      NavConfig.getLabel(c),
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      display,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (widget.canWrite)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Modifier'),
                                onPressed: () => _showEditDialog(row),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete, size: 18),
                                label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                onPressed: () => _confirmDelete(row),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showEditDialog(Map<String, dynamic> row) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modification - bientôt disponible')),
    );
  }

  void _confirmDelete(Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet enregistrement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SupabaseService.client
                    .from(widget.navItem.table)
                    .delete()
                    .eq('id', row['id']);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Supprimé'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
