import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myprogect/model/todolist.dart';
import 'package:myprogect/view/update_detail.dart';
import 'package:myprogect/vm/database_handler.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:collection';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late TextEditingController detailcontroller;
  late TextEditingController adddetailcontroller;
  late TextEditingController importcontroller;
  late TextEditingController lastdatecontroller;

  late DatabaseHandler handler;

  DateTime today = DateTime.now();

  LinkedHashMap<DateTime, List<Todolist>> kEvents =
      LinkedHashMap<DateTime, List<Todolist>>(
        equals: isSameDay,
        hashCode: getHashCode,
      );

  ValueNotifier<List<Todolist>> selectedEvents = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    detailcontroller = TextEditingController();
    adddetailcontroller = TextEditingController();
    importcontroller = TextEditingController();
    lastdatecontroller = TextEditingController();
    handler = DatabaseHandler();

    loadEvents(); // 캘린더 초기 로드
  }

  static int getHashCode(DateTime key) {
    return key.day + key.month + key.year;
  }

  /// 날짜 선택
  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
      selectedEvents.value = getEventsForDay(day);
    });
  }

  Future<void> loadEvents() async {
    List<Todolist> todolist = await handler.queryTodolistlastdate();

    LinkedHashMap<DateTime, List<Todolist>> d =
        LinkedHashMap<DateTime, List<Todolist>>();

    for (var item in todolist) {
      if (item.date == null) continue;

      final date = DateTime.parse(item.date!);

      final key = DateTime(date.year, date.month, date.day);

      d.putIfAbsent(key, () => []);
      d[key]!.add(item);
    }

    kEvents
      ..clear()
      ..addAll(d);

    setState(() {});
    selectedEvents.value = getEventsForDay(today);
  }

  List<Todolist> getEventsForDay(DateTime day) {
    return kEvents[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: Text("캘린더"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Center(
                child: Text(
                  "To Do List",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
              title: Text("설정"),
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
              title: Text("피드백"),
            ),
            ListTile(
              leading: Icon(Icons.facebook),
              iconColor: Theme.of(context).colorScheme.onPrimaryContainer,
              title: Text("팔로우"),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Text("날짜 " + today.toString().substring(0, 10)),

          // 캘린더 위젯
          TableCalendar<Todolist>(
            locale: 'ko_KR',
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: today,
            selectedDayPredicate: (day) => isSameDay(day, today),
            eventLoader: getEventsForDay,
            onDaySelected: _onDaySelected,

            calendarBuilders: CalendarBuilders(),
          ),

          // 선택한 날짜 일정 리스트
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: selectedEvents,
              builder: (context, value, child) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final item = value[index];
                    return Container(
                      child: ListTile(
                        onTap: () => Get.to(
                          UpdateDetail(),
                          arguments: [
                            item.detail,
                            item.lastdate,
                            item.addDetail,
                            item.import,
                            item.seq,
                          ],
                        )!.then((value) => loadEvents()),
                        leading: Theme(
                           data: ThemeData(
                                      useMaterial3: false,
                                    ),
                          child: Switch(
                            activeThumbColor: Colors.green,
                            value: item.ischeck == 1,
                            onChanged: (value) async {
                              item.ischeck = value ? 1 : 0;
                              await handler.updateTodolist(
                                Todolist(
                                  seq: item.seq,
                                  detail: item.detail,
                                  lastdate: item.lastdate,
                                  addDetail: item.addDetail,
                                  import: item.import,
                                  ischeck: item.ischeck,
                                 
                                ),
                              );
                              loadEvents();
                              setState(() {});
                            },
                          ),
                        ),
                        title: Text("작업 : ${item.detail}",
                         style: TextStyle(
                            decoration: item.ischeck == 1
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),),
                        subtitle: Text("마감일 : ${item.lastdate.toString()}"),
                        trailing: Text(
                          "중요도 : ${item.import}",
                         
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      /// 일정 추가 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          dialogAction();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  /// 일정 입력
  Future insertAction() async {
    var todolistInsert = Todolist(
      detail: detailcontroller.text,
      addDetail: adddetailcontroller.text,
      date: today.toString().substring(0, 10),
      lastdate: lastdatecontroller.text,
      import: importcontroller.text,
    );

    int check = await handler.insertTodolist(todolistInsert);
    if (check > 0) {
      _showDialog();
      loadEvents(); // 캘린더 동기화
    }
  }

  /// 입력 완료 알림창
  _showDialog() {
    Get.defaultDialog(
      title: '입력완료',
      middleText: '성공적으로 저장되었습니다.',
      barrierDismissible: false,
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
            Get.back();
            detailcontroller.clear();
            adddetailcontroller.clear();
            lastdatecontroller.clear();
            importcontroller.clear();
          },
          child: Text("OK"),
        ),
      ],
    );
  }

  /// 일정 입력 dialog
  dialogAction() {
    Get.dialog(
      AlertDialog(
        title: Text('Todo 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: detailcontroller,
              decoration: InputDecoration(labelText: '작업 내용'),
            ),
            TextField(
              controller: adddetailcontroller,
              decoration: InputDecoration(labelText: '메모'),
            ),
            GestureDetector(
              onTap: () {},
              child: TextField(
                controller: lastdatecontroller,
                decoration: InputDecoration(labelText: '마감일'),
              ),
            ),
            TextField(
              controller: importcontroller,
              decoration: InputDecoration(labelText: '중요도'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              insertAction();
            },
            child: Text("추가하기"),
          ),
        ],
      ),
    );
  } //build
} //class
