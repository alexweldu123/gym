import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../config/theme_constants.dart';
import '../../models/user.dart';
import '../../models/attendance.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // Data
  List<User> _members = [];
  List<Attendance> _attendanceLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch Members
      final membersRes = await _apiService.get('/management/members');
      if (membersRes.statusCode == 200) {
        final List data = membersRes.data['data'];
        _members = data.map((json) => User.fromJson(json)).toList();
      }

      // Fetch Attendance (Last 30 days for reasonable sample)
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      _attendanceLogs = await _apiService.getAttendanceLogs(
        startDate: DateFormat('yyyy-MM-dd').format(thirtyDaysAgo),
        endDate: DateFormat('yyyy-MM-dd').format(now),
        limit: 2000,
      );
    } catch (e) {
      debugPrint("Error loading reports data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Reports & Analytics"),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Revenue"),
            Tab(text: "Members"),
            Tab(text: "Attendance"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRevenueTab(),
                _buildMembersTab(),
                _buildAttendanceTab(),
              ],
            ),
    );
  }

  // --- TABS ---

  Widget _buildRevenueTab() {
    // Calculate Revenue by Package
    // Map<PackageName, TotalAmount>
    Map<String, double> revenueByPackage = {};
    double totalRevenue = 0;

    final activeMembers = _members
        .where((m) => m.membershipStatus?.toLowerCase() == 'active')
        .toList();

    for (var member in activeMembers) {
      final pkgName = member.package?.name ?? "Unknown";
      final price = member.package?.price ?? 0.0;
      revenueByPackage[pkgName] = (revenueByPackage[pkgName] ?? 0) + price;
      totalRevenue += price;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            "Expected Monthly Revenue",
            "\$${totalRevenue.toStringAsFixed(2)}",
            Icons.monetization_on,
            Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            "Revenue Breakdown by Package",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...revenueByPackage.entries.map((e) {
            final percentage = totalRevenue > 0
                ? (e.value / totalRevenue)
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildProgressBar(
                label: e.key,
                value: "\$${e.value.toStringAsFixed(0)}",
                percentage: percentage,
                color: Colors.blueAccent,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    int total = _members.length;
    int active = _members
        .where((m) => m.membershipStatus?.toLowerCase() == 'active')
        .length;
    int inactive = total - active;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Total",
                  "$total",
                  Icons.group,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Active",
                  "$active",
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            "Inactive",
            "$inactive",
            Icons.cancel,
            Colors.redAccent,
          ),

          const SizedBox(height: 24),
          // Simple visual distribution
          Container(
            height: 20,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[800],
            ),
            child: Row(
              children: [
                if (total > 0)
                  Expanded(
                    flex: active,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
                if (total > 0)
                  Expanded(
                    flex: inactive,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Active", style: TextStyle(color: Colors.green)),
              Text("Inactive", style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    // Busiest Days
    // Map<Weekday, Count>
    Map<int, int> daysCount = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (var log in _attendanceLogs) {
      daysCount[log.scanTime.weekday] =
          (daysCount[log.scanTime.weekday] ?? 0) + 1;
    }

    final totalScans = _attendanceLogs.length;
    final avgPerDay = totalScans > 0
        ? (totalScans / 30).toStringAsFixed(1)
        : "0";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            "Total Scans (Last 30 Days)",
            "$totalScans",
            Icons.qr_code,
            AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            "Avg Scans / Day",
            avgPerDay,
            Icons.trending_up,
            Colors.orange,
          ),
          const SizedBox(height: 24),
          const Text(
            "Busiest Days of Week",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...[1, 2, 3, 4, 5, 6, 7].map((day) {
            final count = daysCount[day] ?? 0;
            final max = daysCount.values.reduce((a, b) => a > b ? a : b);
            final percentage = max > 0 ? count / max : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      _weekdayName(day),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage == 0
                              ? 0.01
                              : percentage, // avoid 0 width issues
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "$count",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _weekdayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required String value,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textPrimary)),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppColors.surfaceVariant,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
