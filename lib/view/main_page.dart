import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:myprogect/model/todolist.dart';
import 'package:myprogect/view/update_detail.dart';
import 'package:myprogect/vm/database_handler.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late DatabaseHandler handler;
  late TextEditingController detailcontroller;
  late TextEditingController datecontroller;
  late TextEditingController adddetailcontroller;
  late TextEditingController importcontroller;
  late TextEditingController lastdatecontroller;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    detailcontroller = TextEditingController();
    datecontroller = TextEditingController();
    adddetailcontroller = TextEditingController();
    importcontroller = TextEditingController();
    lastdatecontroller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: Text("작업"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
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
      body: FutureBuilder(
        future: handler.queryTodolist(),
        builder: (context, snapshot) {
          return snapshot.hasData && snapshot.data!.isNotEmpty
              ? ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var item = snapshot.data![index];

                    return GestureDetector(
                      onTap: () => Get.to(
                        UpdateDetail(),
                        arguments: [
                          item.detail,
                          item.lastdate,
                          item.addDetail,
                          item.import,
                          item.seq,
                        ],
                      )!.then((value) => reloadData()),
                      child: Slidable(
                        endActionPane: ActionPane(
                          motion: BehindMotion(),
                          children: [
                            SlidableAction(
                              backgroundColor: Colors.red,
                              icon: Icons.delete,
                              label: "Delete",
                              onPressed: (context) async {
                                await handler.deleteTodolist(item.seq!);
                                setState(() {});
                              },
                            ),
                          ],
                        ),

                        /// ---------- ListTile 형태로 변경된 부분 ----------
                        child: ListTile(
                          tileColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          leading: Theme(
                           data: ThemeData(
                                      useMaterial3: false,
                                    ),
                            child: Switch(
                              activeThumbColor: Colors.green,
                              value: item.ischeck == 1,
                              onChanged: (value) async {
                                item.ischeck = value ? 1 : 0;
                                await handler.updateTodolist(item);
                                setState(() {});
                              },
                            ),
                          ),
                          title: Text(
                            item.detail,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: item.ischeck == 1
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            item.date ?? "",
                            style: TextStyle(fontSize: 13),
                          ),
                          trailing: Icon(Icons.chevron_right),
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text(
                    "일정이 없습니다 +버튼을 눌러 일정을 추가해주세여",
                  ),
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          dialogAction();
        },
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        child: Icon(Icons.add_outlined),
      ),
    );
  }

  // ---------------------- dialog ----------------------
  dialogAction() {
    Get.dialog(
      AlertDialog(
        title: Text('Todo list'),
        content: Text("추가할 내용을 입력 하세요"),
        actions: [
          Column(
            children: [
              TextField(
                controller: detailcontroller,
                decoration: InputDecoration(labelText: '작업할 내용'),
              ),
              TextField(
                controller: datecontroller,
                decoration: InputDecoration(labelText: '생성일'),
                readOnly: true,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());

                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (pickedDate == null) return;

                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (pickedTime == null) return;

                  DateTime fullDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  datecontroller.text =
                      fullDateTime.toString().substring(0, 16);
                },
              ),
              TextField(
                controller: adddetailcontroller,
                decoration: InputDecoration(labelText: '메모'),
              ),
              TextField(
                controller: lastdatecontroller,
                decoration: InputDecoration(labelText: '마감일'),
                readOnly: true,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());

                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (pickedDate == null) return;

                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (pickedTime == null) return;

                  DateTime fullDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  lastdatecontroller.text =
                      fullDateTime.toString().substring(0, 16);
                },
              ),
              TextField(
                controller: importcontroller,
                decoration: InputDecoration(labelText: '중요도'),
              ),
              TextButton(
                onPressed: () {
                  insertAction();
                  reloadData();
                },
                child: Text("추가하기"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future insertAction() async {
    var todolistInsert = Todolist(
      detail: detailcontroller.text,
      date: datecontroller.text,
      addDetail: adddetailcontroller.text,
      lastdate: lastdatecontroller.text,
      import: importcontroller.text,
      ischeck: 0,
    );

    int check = await handler.insertTodolist(todolistInsert);
    if (check != 0) {
      _showDialog();
    }
  }

  _showDialog() {
    Get.defaultDialog(
      title: '입력결과',
      middleText: '입력이 완료되었습니다',
      barrierDismissible: false,
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
            Get.back();
          },
          child: Text("OK"),
        ),
      ],
    );
  }

  reloadData() {
    handler.queryTodolist();
    setState(() {});
  }
}
