import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecuisine_mess/services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  List<dynamic> _headcountData = [];
  List<dynamic> _attendanceData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final hc = await _api.fetchHeadcountReport();
      final att = await _api.fetchAttendanceReport();
      setState(() {
        _headcountData = hc;
        _attendanceData = att;
      });
    } catch (_) {} finally {
      setState(() => _isLoading = false);
    }
  }

  // Generate pipe-delimited CSV string adhering strictly to '|' delimiter rule
  void _exportHeadcountCsv() {
    final buffer = StringBuffer();
    // Header with pipe separator
    buffer.writeln('Cuisine|Meal Type|Headcount');
    for (var row in _headcountData) {
      buffer.writeln('${row["cuisine_name"]}|${row["meal_type"]}|${row["headcount"]}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Headcount CSV (Pipe "|" delimited) copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportAttendanceCsv() {
    final buffer = StringBuffer();
    // Header with pipe separator
    buffer.writeln('Member Code|Member Name|Cuisine|Date|Meal Type|Token Number|Time');
    for (var row in _attendanceData) {
      buffer.writeln(
        '${row["member_id"]}|${row["name"]}|${row["cuisine_name"]}|${row["bill_date"]}|${row["meal_type"]}|${row["token_number"]}|${row["bill_time"]}'
      );
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance CSV (Pipe "|" delimited) copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reports & Analytics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Cuisine-wise headcount and customer meal attendance registers', style: TextStyle(color: Colors.black54)),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _loadReportData,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _tabController.index == 0 ? _exportHeadcountCsv : _exportAttendanceCsv,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export Pipe "|" CSV'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0F172A),
            unselectedLabelColor: Colors.black54,
            tabs: const [
              Tab(icon: Icon(Icons.pie_chart_outline), text: 'Cuisine x Meal Headcount'),
              Tab(icon: Icon(Icons.event_note), text: 'Customer Attendance Register'),
            ],
            onTap: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Headcount
                      Card(
                        child: _headcountData.isEmpty
                            ? const Center(child: Text('No headcount records found for today'))
                            : ListView.separated(
                                itemCount: _headcountData.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final row = _headcountData[index];
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFE0E7FF),
                                      child: Icon(Icons.groups, color: Color(0xFF3730A3)),
                                    ),
                                    title: Text(row['cuisine_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Meal Type: ${row["meal_type"]}'),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFF6EE7B7)),
                                      ),
                                      child: Text(
                                        '${row["headcount"]} Diners',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      // Tab 2: Attendance
                      Card(
                        child: _attendanceData.isEmpty
                            ? const Center(child: Text('No attendance records found for today'))
                            : ListView.separated(
                                itemCount: _attendanceData.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final row = _attendanceData[index];
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFF1F5F9),
                                      child: Icon(Icons.person, color: Color(0xFF0F172A)),
                                    ),
                                    title: Text(row['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${row["cuisine_name"]} • Token: ${row["token_number"]}'),
                                    trailing: Text(
                                      '${row["meal_type"]} @ ${row["bill_time"]}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
