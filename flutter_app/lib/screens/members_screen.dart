import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/api_service.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final ApiService _api = ApiService();
  List<Member> _members = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.fetchMembers(search: _searchQuery);
      setState(() => _members = list);
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
                  Text('Members Register', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Manage diners, RFID card links, assigned cuisine & subscription validity', style: TextStyle(color: Colors.black54)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadMembers,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by member name, code, or RFID tag...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) {
              _searchQuery = val;
              _loadMembers();
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? const Center(child: Text('No members found'))
                    : Card(
                        child: ListView.separated(
                          itemCount: _members.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final m = _members[index];
                            final isExpired = m.status == 'EXPIRED' || m.daysLeft < 0;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isExpired ? Colors.red.shade100 : Colors.blue.shade100,
                                child: Icon(
                                  Icons.credit_card,
                                  color: isExpired ? Colors.red.shade800 : Colors.blue.shade800,
                                ),
                              ),
                              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Code: ${m.memberCode} • RFID: ${m.rfidTag} • Phone: ${m.phone ?? "N/A"}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    m.cuisineName ?? 'No Cuisine Assigned',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    isExpired ? 'EXPIRED' : '${m.daysLeft} days remaining',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isExpired ? Colors.red : Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
