import 'package:flutter/material.dart';
import 'package:myprogect/view/calendar_page.dart';
import 'package:myprogect/view/main_page.dart';
import 'package:myprogect/view/my_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  /*
  int? seq;
  String detail;
  String? date;
  String? lastdate;
  String addDetail;
  String import;



*/
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: controller,
        children: [MainPage(), CalendarPage(), MyPage()],
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        height: 80,
        child: TabBar(
          controller: controller,
          labelColor: Colors.amber,
          indicatorColor: Colors.red,
          indicatorWeight: 5,

          tabs: [
            Tab(icon: Icon(Icons.add), text: "Work"),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: "Calendar"),
            Tab(icon: Icon(Icons.face), text: "Mypage"),
          ],
        ),
      ),
    );
  } //build
} //class
