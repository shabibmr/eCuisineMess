import 'package:flutter/material.dart';
import '../models/cuisine.dart';
import '../services/api_service.dart';

class CuisinesScreen extends StatefulWidget {
  const CuisinesScreen({super.key});

  @override
  State<CuisinesScreen> createState() => _CuisinesScreenState();
}

class _CuisinesScreenState extends State<CuisinesScreen> {
  final ApiService _api = ApiService();
  List<Cuisine> _cuisines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCuisines();
  }

  Future<void> _loadCuisines() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.fetchCuisines();
      setState(() => _cuisines = list);
    } catch (_) {} finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Cuisines & Menu Mappings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Active meal packages and their entitled menu items', style: TextStyle(color: Colors.black54)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadCuisines,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cuisines.isEmpty
                    ? const Center(child: Text('No cuisines found'))
                    : ListView.builder(
                        itemCount: _cuisines.length,
                        itemBuilder: (context, index) {
                          final c = _cuisines[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${c.cuisineName} (${c.cuisineCode})',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Chip(
                                        label: Text('${c.items.length} items mapped', style: const TextStyle(fontSize: 12)),
                                        backgroundColor: Colors.blue.shade50,
                                      ),
                                    ],
                                  ),
                                  if (c.description != null && c.description!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4, bottom: 12),
                                      child: Text(c.description!, style: const TextStyle(color: Colors.black54)),
                                    ),
                                  const Divider(height: 20),
                                  const Text('Mapped Entitlement Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: c.items.map((itm) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          '${itm.itemName} (${itm.quantity.toStringAsFixed(0)} ${itm.unit})',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
