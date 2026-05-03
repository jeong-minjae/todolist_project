import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myprogect/model/todolist.dart';
import 'package:myprogect/view/update_detail.dart';
import 'package:myprogect/vm/database_handler.dart';

const List<String> priorityOptions = ['\uC0C1', '\uC911', '\uD558'];

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late DatabaseHandler handler;
  late TextEditingController detailController;
  late TextEditingController dateController;
  late TextEditingController memoController;
  late TextEditingController priorityController;

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    detailController = TextEditingController();
    dateController = TextEditingController();
    memoController = TextEditingController();
    priorityController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      reloadData();
    }
  }

  @override
  void dispose() {
    detailController.dispose();
    dateController.dispose();
    memoController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 할 일'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: reloadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Todolist>>(
        future: handler.queryTodolist(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          final doneCount = items.where((item) => item.ischeck == 1).length;

          if (items.isEmpty) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    child: _SummaryPanel(total: items.length, done: doneCount),
                  ),
                ),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                ),
              ],
            );
          }

          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            header: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _SummaryPanel(total: items.length, done: doneCount),
            ),
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) =>
                reorderItems(items, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                key: ValueKey(item.seq),
                padding: const EdgeInsets.only(bottom: 12),
                child: _TodoCard(
                  item: item,
                  index: index,
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => UpdateDetail(todo: item),
                        ),
                      )
                      .then((_) => reloadData()),
                  onChanged: (value) async {
                    try {
                      item.ischeck = value ? 1 : 0;
                      await handler.updateTodolist(item);
                      reloadData();
                    } catch (error) {
                      Get.snackbar('수정 실패', error.toString());
                    }
                  },
                  onDelete: () async {
                    try {
                      await handler.deleteTodolist(item.seq!);
                      reloadData();
                    } catch (error) {
                      Get.snackbar('삭제 실패', error.toString());
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'main_add_todo_fab',
        onPressed: showAddTodoSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('추가'),
      ),
    );
  }

  Future<void> showAddTodoSheet() async {
    clearInputs();
    await Get.bottomSheet(
      _TodoEditorSheet(
        title: '새 할 일',
        detailController: detailController,
        dateController: dateController,
        memoController: memoController,
        priorityController: priorityController,
        onPickDate: () => pickDate(dateController),
        onSave: insertAction,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> pickDate(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null || !mounted) return;

    controller.text = dateKey(pickedDate);
  }

  Future<void> insertAction() async {
    if (detailController.text.trim().isEmpty) {
      Get.snackbar('입력 필요', '할 일을 입력해주세요.');
      return;
    }

    final todolistInsert = Todolist(
      detail: detailController.text.trim(),
      date: dateController.text.trim().isEmpty
          ? dateKey(DateTime.now())
          : dateController.text.trim(),
      addDetail: memoController.text.trim(),
      import: priorityController.text.trim(),
      ischeck: 0,
    );
    try {
      final check = await handler.insertTodolist(todolistInsert);
      if (check != 0) {
        Get.back();
        clearInputs();
        reloadData();
        Get.snackbar('저장 완료', '할 일이 추가되었습니다.');
      }
    } catch (error) {
      Get.snackbar('저장 실패', error.toString());
    }
  }

  void clearInputs() {
    detailController.clear();
    dateController.clear();
    memoController.clear();
    priorityController.clear();
  }

  void reloadData() {
    setState(() {});
  }

  Future<void> reorderItems(
    List<Todolist> items,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    if (oldIndex == newIndex) return;

    final movedItem = items[oldIndex];
    final targetItem = items[newIndex];
    if (todoDateKey(movedItem) != todoDateKey(targetItem)) {
      Get.snackbar('순서 변경', '같은 날짜 안에서만 순서를 바꿀 수 있어요.');
      return;
    }

    final reordered = List<Todolist>.from(items);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    final dateItems = reordered
        .where((todo) => todoDateKey(todo) == todoDateKey(item))
        .toList();

    await handler.updateTodoOrder(dateItems);
    reloadData();
  }

  String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String todoDateKey(Todolist todo) {
    final date = todo.date;
    if (date == null || date.length < 10) return '';
    return date.substring(0, 10);
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.total, required this.done});

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '집중할 일을 정리해요',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\uC804\uCCB4 $total\uAC1C \u00B7 \uC644\uB8CC $done\uAC1C \u00B7 \uBBF8\uC644\uB8CC ${total - done}\uAC1C',
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: ratio,
              backgroundColor: const Color(0xFF374151),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF60A5FA)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onChanged,
    required this.onDelete,
  });

  final Todolist item;
  final int index;
  final VoidCallback onTap;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final checked = item.ischeck == 1;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: (value) => onChanged(value ?? false),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: checked
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        decoration: checked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.date?.isNotEmpty == true
                                ? item.date!.substring(0, 10)
                                : '날짜 없음',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (item.import.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _PriorityBadge(priority: item.import),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '삭제',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        priority,
        style: const TextStyle(
          color: Color(0xFFC2410C),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Color(0xFF2563EB),
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '아직 등록된 할 일이 없어요',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            '아래 추가 버튼으로 오늘 할 일을 만들어보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _TodoEditorSheet extends StatelessWidget {
  const _TodoEditorSheet({
    required this.title,
    required this.detailController,
    required this.dateController,
    required this.memoController,
    required this.priorityController,
    required this.onPickDate,
    required this.onSave,
  });

  final String title;
  final TextEditingController detailController;
  final TextEditingController dateController;
  final TextEditingController memoController;
  final TextEditingController priorityController;
  final VoidCallback onPickDate;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(28),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: detailController,
                  decoration: const InputDecoration(
                    labelText: '할 일',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  onTap: onPickDate,
                  decoration: const InputDecoration(
                    labelText: '시작 날짜',
                    prefixIcon: Icon(Icons.event_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                _PriorityField(controller: priorityController),
                const SizedBox(height: 12),
                TextField(
                  controller: memoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '메모',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('저장하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
