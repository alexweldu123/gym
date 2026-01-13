import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import 'history_screen.dart';

class MemberMainScreen extends StatefulWidget {
  const MemberMainScreen({super.key});

  @override
  State<MemberMainScreen> createState() => _MemberMainScreenState();
}

class _MemberMainScreenState extends State<MemberMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const MemberHomeTab(),
      HistoryScreen(),
      const Center(child: Text("Profile (Placeholder)")),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('GymOS Member')),
      drawer: const AppDrawer(),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class MemberHomeTab extends StatefulWidget {
  const MemberHomeTab({super.key});

  @override
  State<MemberHomeTab> createState() => _MemberHomeTabState();
}

class _MemberHomeTabState extends State<MemberHomeTab> {
  late int _timestamp;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        });
      }
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

    return Center(
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
        ],
      ),
    );
  }
}
