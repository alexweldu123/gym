import 'package:flutter/material.dart';
import 'package:gym/screens/admin/scanner_screen.dart';
import 'package:gym/screens/staff/members_list.dart';
import 'package:gym/screens/staff/staff_register_screen.dart';
import 'package:gym/screens/staff/attendance_list_screen.dart';
import '../../widgets/app_drawer.dart';

class StaffMainScreen extends StatefulWidget {
  const StaffMainScreen({super.key});

  @override
  State<StaffMainScreen> createState() => _StaffMainScreenState();
}

class _StaffMainScreenState extends State<StaffMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const StaffMembersList(),
    const StaffRegisterScreen(),
    const AttendanceListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Dashboard')),
      drawer: const AppDrawer(),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminScannerScreen()),
          );
        },
        elevation: 2.0,
        backgroundColor: Theme.of(context).primaryColor,
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
                icon: const Icon(Icons.people),
                color: _currentIndex == 0
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                onPressed: () => setState(() => _currentIndex = 0),
                tooltip: 'Members',
              ),
              IconButton(
                icon: const Icon(Icons.history),
                color: _currentIndex == 2
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                onPressed: () => setState(() => _currentIndex = 2),
                tooltip: 'Attendance',
              ),
              const SizedBox(width: 48), // Spacer for FAB
              IconButton(
                icon: const Icon(Icons.person_add),
                color: _currentIndex == 1
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                onPressed: () => setState(() => _currentIndex = 1),
                tooltip: 'Register',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
