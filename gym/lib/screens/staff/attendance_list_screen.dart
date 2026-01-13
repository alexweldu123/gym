import 'package:flutter/material.dart';
import 'package:gym/models/attendance.dart';
import 'package:gym/services/api_service.dart';
import 'package:intl/intl.dart';

class AttendanceListScreen extends StatefulWidget {
  const AttendanceListScreen({super.key});

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();
  List<Attendance> _logs = [];
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _fetchLogs();
      }
    }
  }

  Future<void> _fetchLogs() async {
    if (_isLoading && _page > 1) return;
    setState(() => _isLoading = true);

    try {
      final logs = await _api.getAttendanceLogs(
        page: _page,
        startDate: _startDate != null
            ? DateFormat('yyyy-MM-dd').format(_startDate!)
            : null,
        endDate: _endDate != null
            ? DateFormat('yyyy-MM-dd').format(_endDate!)
            : null,
      );
      setState(() {
        if (_page == 1) {
          _logs = logs;
        } else {
          _logs.addAll(logs);
        }
        _hasMore = logs.length == 20; // Assuming limit is 20
        _page++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _refresh() async {
    _page = 1;
    _hasMore = true;
    _logs.clear();
    await _fetchLogs();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.lime,
              onPrimary: Colors.black,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _refresh();
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null, // Title removed as requested
        backgroundColor: Colors.black,
        actions: [
          if (_startDate != null)
            IconButton(
              icon: const Icon(Icons.filter_list_off, color: Colors.redAccent),
              onPressed: _clearFilter,
              tooltip: 'Clear Filter',
            ),
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: _startDate != null ? Colors.lime : Colors.white,
            ),
            onPressed: _selectDateRange,
            tooltip: 'Filter by Date',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _logs.isEmpty && !_isLoading
            ? Center(
                child: Text(
                  "No logs found.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                itemCount: _logs.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _logs.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final item = _logs[index];
                  final trainerName = item.trainer?['name'] ?? 'Unknown Member';
                  final adminName =
                      item.admin?['name'] ?? 'Staff #${item.scannedBy}';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: Colors.grey[900],
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            item.trainer?['membership_status'] == 'active'
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          color: item.trainer?['membership_status'] == 'active'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      title: Text(
                        trainerName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Scanned by: $adminName",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, y h:mm a').format(item.scanTime),
                            style: TextStyle(color: Colors.lime, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
