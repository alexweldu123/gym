import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import 'scanner_screen.dart';
import 'admin_dashboard.dart';
import 'reports_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboard(), // Replace with Stats Widget
    const AdminScannerScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      drawer: const AppDrawer(),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _currentIndex = 1), // Scan is index 1
        elevation: 2.0,
        backgroundColor: _currentIndex == 1
            ? Theme.of(context).primaryColor
            : Colors.grey,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.dashboard),
                color: _currentIndex == 0
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                onPressed: () => setState(() => _currentIndex = 0),
                tooltip: 'Dashboard',
              ),
              const SizedBox(width: 48), // Spacer for FAB
              IconButton(
                icon: const Icon(Icons.analytics),
                color: _currentIndex == 2
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                onPressed: () => setState(() => _currentIndex = 2),
                tooltip: 'Reports',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
