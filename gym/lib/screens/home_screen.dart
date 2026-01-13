import 'package:flutter/material.dart';
import 'package:gym/screens/admin/admin_main_screen.dart';
import 'package:gym/screens/staff/staff_main_screen.dart';
import 'package:gym/screens/trainer/trainer_dashboard.dart';
import 'package:gym/screens/member/member_main_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return const Center(child: Text("Checking Session..."));
    }

    if (user.isAdmin) {
      return const AdminMainScreen();
    } else if (user.isStaff) {
      return const StaffMainScreen();
    } else if (user.isTrainer) {
      return const TrainerDashboard(); // Trainer can stay as is for now or get similar update later
    } else {
      return const MemberMainScreen();
    }
  }
}
