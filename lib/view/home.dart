import 'package:flutter/material.dart';
import 'package:myprogect/view/calendar_page.dart';
import 'package:myprogect/view/main_page.dart';
import 'package:myprogect/view/my_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int selectedIndex = 0;
  int mainRefreshToken = 0;
  int calendarRefreshToken = 0;
  int reportRefreshToken = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      MainPage(refreshToken: mainRefreshToken),
      CalendarPage(refreshToken: calendarRefreshToken),
      MyPage(refreshToken: reportRefreshToken),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NavigationBar(
              height: 72,
              selectedIndex: selectedIndex,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFEFF6FF),
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                setState(() {
                  selectedIndex = index;
                  if (index == 0) {
                    mainRefreshToken++;
                  }
                  if (index == 1) {
                    calendarRefreshToken++;
                  }
                  if (index == 2) {
                    reportRefreshToken++;
                  }
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.checklist_rounded),
                  selectedIcon: Icon(Icons.checklist_rounded),
                  label: '할 일',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: '캘린더',
                ),
                NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: '리포트',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
