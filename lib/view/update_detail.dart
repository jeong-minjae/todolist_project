import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myprogect/model/todolist.dart';
import 'package:myprogect/vm/database_handler.dart';

const List<String> priorityOptions = ['\uC0C1', '\uC911', '\uD558'];

class UpdateDetail extends StatefulWidget {
  const UpdateDetail({super.key, this.todo});

  final Todolist? todo;

  @override
  State<UpdateDetail> createState() => _UpdateDetailState();
}

class _UpdateDetailState extends State<UpdateDetail> {
  late DatabaseHandler handler;
  late TextEditingController detailController;
  late TextEditingController memoController;
  late TextEditingController priorityController;

  late final Todolist todo;

  @override
  void initState() {
    super.initState();
    todo = widget.todo ?? _todoFromLegacyArguments();
    detailController = TextEditingController(text: todo.detail);
    memoController = TextEditingController(text: todo.addDetail);
    priorityController = TextEditingController(text: todo.import);
    handler = DatabaseHandler();
  }

  @override
  void dispose() {
    detailController.dispose();
    memoController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('할 일 수정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: detailController,
                  decoration: const InputDecoration(
                    labelText: '할 일',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                _PriorityField(controller: priorityController),
                const SizedBox(height: 12),
                TextField(
                  controller: memoController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: '메모',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: updateAction,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('변경사항 저장'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updateAction() async {
    if (detailController.text.trim().isEmpty) {
      Get.snackbar('입력 필요', '할 일을 입력해주세요.');
      return;
    }

    final todolistUpdate = Todolist(
      seq: todo.seq,
      detail: detailController.text.trim(),
      date: todo.date,
      addDetail: memoController.text.trim(),
      import: priorityController.text.trim(),
      ischeck: todo.ischeck,
      sortOrder: todo.sortOrder,
    );
    try {
      final check = await handler.updateTodolist(todolistUpdate);
      if (check != 0) {
        Get.back();
        Get.snackbar('저장 완료', '수정한 내용이 반영되었습니다.');
      }
    } catch (error) {
      Get.snackbar('저장 실패', error.toString());
    }
  }

  Todolist _todoFromLegacyArguments() {
    final value = Get.arguments;
    if (value is List && value.length >= 5) {
      return Todolist(
        detail: value[0] ?? '',
        addDetail: value[2] ?? '',
        import: value[3] ?? '',
        seq: value[4],
        date: value.length > 5 ? value[5] : null,
        ischeck: value.length > 6 ? value[6] : 0,
        sortOrder: value.length > 7 ? value[7] : null,
      );
    }

    return Todolist(detail: '', addDetail: '', import: '');
  }
}

class _PriorityField extends StatelessWidget {
  const _PriorityField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '\uC911\uC694\uB3C4',
        prefixIcon: Icon(Icons.priority_high_rounded),
      ),
      child: StatefulBuilder(
        builder: (context, setState) {
          return Wrap(
            spacing: 8,
            children: priorityOptions.map((priority) {
              final selected = controller.text == priority;
              return ChoiceChip(
                label: Text(priority),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    controller.text = priority;
                  });
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
