import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../trainer/history_screen.dart'; // Reuse history screen for now

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  late int _timestamp;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${user?.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your Member QR Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Status: ${user?.membershipStatus?.toUpperCase() ?? "UNKNOWN"}',
              style: TextStyle(
                color: user?.membershipStatus == 'active'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: QrImageView(
                data:
                    '{"member_id": ${user?.id}, "role": "member", "timestamp": $_timestamp}',
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 10),
            Text('Refreshes automatically (Ts: $_timestamp)'),
            const SizedBox(height: 30),
            if (user?.assignedTrainerId != null)
              Text(
                'Assigned Trainer ID: ${user?.assignedTrainerId}',
              ), // TODO: Fetch Trainer Name
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttendanceHistoryScreen(),
                  ),
                );
              },
              child: const Text('View Attendance History'),
            ),
          ],
        ),
      ),
    );
  }
}
