import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../updates/providers/update_provider.dart';
import 'caretaker_dashboard_screen.dart';
import 'caretaker_requests_screen.dart';
import 'caretaker_units_screen.dart';
import 'caretaker_jobs_screen.dart';
import 'caretaker_tasks_screen.dart';
import 'caretaker_profile_screen.dart';

class CaretakerShell extends ConsumerStatefulWidget {
  const CaretakerShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<CaretakerShell> createState() => _CaretakerShellState();
}

class _CaretakerShellState extends ConsumerState<CaretakerShell> {
  late int _currentIndex = widget.initialIndex;

  final List<Widget> _screens = const [
    CaretakerDashboardScreen(),
    CaretakerRequestsScreen(),
    CaretakerUnitsScreen(),
    CaretakerJobsScreen(),
    CaretakerTasksScreen(),
    CaretakerProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateControllerProvider).checkAndPrompt();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.send_outlined), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Units'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.build_outlined), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
