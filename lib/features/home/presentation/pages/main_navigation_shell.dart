import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cms/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:cms/features/approvals/presentation/bloc/approvals_state.dart';
import 'package:cms/features/approvals/presentation/pages/approvals_page.dart';
import 'home_page.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      // const PulsePage(),   // Hidden — Pulse
      // const AlertsPage(), // Hidden — Alerts
      const ApprovalsPage(),
      // const DailyTaskPage(), // Hidden — Tasks
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BlocBuilder<ApprovalsBloc, ApprovalsState>(
        builder: (context, approvalsState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                    // Hidden — Pulse
                    // _buildNavItem(
                    //   1,
                    //   Icons.show_chart_outlined,
                    //   Icons.show_chart,
                    //   'Pulse',
                    // ),
                    // Hidden — Alerts
                    // _buildNavItem(
                    //   2,
                    //   Icons.warning_amber_rounded,
                    //   Icons.warning_rounded,
                    //   'Alerts',
                    //   badgeCount: 2,
                    // ),
                    _buildNavItem(
                      1,
                      Icons.verified_outlined,
                      Icons.verified,
                      'Approvals',
                      badgeCount: approvalsState.pendingCount,
                    ),
                    // Hidden — Tasks
                    // _buildNavItem(
                    //   4,
                    //   Icons.assignment_outlined,
                    //   Icons.assignment,
                    //   'Tasks',
                    //   badgeCount: 3,
                    // ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData solidIcon,
    String label, {
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    final themeColor = const Color(0xFF319F77); // High-fidelity deep teal

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? solidIcon : outlineIcon,
                  color: isSelected ? themeColor : Colors.grey.shade500,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? themeColor : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} // end DailyTaskView
