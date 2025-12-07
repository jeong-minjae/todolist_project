import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myprogect/model/todolist.dart';
import 'package:myprogect/vm/database_handler.dart';

class UpdateDetail extends StatefulWidget {
  const UpdateDetail({super.key});

  @override
  State<UpdateDetail> createState() => _UpdateDetailState();
}

class _UpdateDetailState extends State<UpdateDetail> {
  late DatabaseHandler handler;
  late TextEditingController detailcontroller;
  late TextEditingController adddetailcontroller;
  late TextEditingController importcontroller;
  late TextEditingController lastdatecontroller;

  var value = Get.arguments ?? "__";
  @override
  void initState() {
    super.initState();
    detailcontroller = TextEditingController();
    lastdatecontroller = TextEditingController();
    adddetailcontroller = TextEditingController();
    importcontroller = TextEditingController();
    handler = DatabaseHandler();

    detailcontroller.text = value[0];
    lastdatecontroller.text = value[1];
    adddetailcontroller.text = value[2];
    importcontroller.text = value[3];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(title: Text("작업사항 수정"),
       backgroundColor: Theme.of(context).colorScheme.primaryContainer,
       ),

      body: Center(
        child: Column(
          children: [
            TextField(
              controller: detailcontroller,
              decoration: InputDecoration(labelText: "작업 수정"),
            ),
            TextField(
              controller: lastdatecontroller,
              decoration: InputDecoration(labelText: "마감일 수정"),
            ),
            TextField(
              controller: adddetailcontroller,
              decoration: InputDecoration(labelText: "추가내용 수정"),
            ),
            TextField(
              controller: importcontroller,
              decoration: InputDecoration(labelText: "중요도 수정"),
            ),

            ElevatedButton(
              onPressed: () {
                updateAction();
              },
              child: Text("수정"),
            ),
          ],
        ),
      ),
    );
  } //build

  Future updateAction() async {
    //File Type Byte Type으로 변환하기

    var todolistUpdate = Todolist(
      seq: value[4],
      detail: detailcontroller.text,
      lastdate: lastdatecontroller.text,
      addDetail: adddetailcontroller.text,
      import: importcontroller.text,
    );

    int check = await handler.updateTodolist(todolistUpdate);
    if (check == 0) {
      //Error
    } else {
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
}//class