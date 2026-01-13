import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import 'history_screen.dart';

class TrainerDashboard extends StatefulWidget {
  const TrainerDashboard({super.key});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> {
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
              'Your Attendance QR Code',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: QrImageView(
                data: '{"trainer_id": ${user?.id}, "timestamp": $_timestamp}',
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 10),
            Text('Refreshes automatically (Ts: $_timestamp)'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AttendanceHistoryScreen(),
                  ),
                );
              },
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
}
