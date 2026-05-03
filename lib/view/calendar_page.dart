import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myprogect/model/todolist.dart';
import 'package:myprogect/view/update_detail.dart';
import 'package:myprogect/vm/database_handler.dart';
import 'package:table_calendar/table_calendar.dart';

const List<String> priorityOptions = ['\uC0C1', '\uC911', '\uD558'];

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final DatabaseHandler handler;
  late final TextEditingController detailController;
  late final TextEditingController memoController;
  late final TextEditingController priorityController;

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  Map<String, List<Todolist>> eventsByDate = {};

  @override
  void initState() {
    super.initState();
    handler = DatabaseHandler();
    detailController = TextEditingController();
    memoController = TextEditingController();
    priorityController = TextEditingController();
    loadEvents();
  }

  @override
  void didUpdateWidget(covariant CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      loadEvents();
    }
  }

  @override
  void dispose() {
    detailController.dispose();
    memoController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  Future<void> loadEvents() async {
    final todos = await handler.queryTodolist();
    final nextEvents = <String, List<Todolist>>{};

    for (final item in todos) {
      final dateText = item.date;
      if (dateText == null || dateText.length < 10) continue;

      final key = dateText.substring(0, 10);
      nextEvents.putIfAbsent(key, () => <Todolist>[]).add(item);
    }

    if (!mounted) return;
    setState(() {
      eventsByDate = nextEvents;
    });
  }

  String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  List<Todolist> itemsForDay(DateTime day) {
    return eventsByDate[dateKey(day)] ?? const <Todolist>[];
  }

  List<Todolist> selectedItems() {
    return itemsForDay(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    final items = selectedItems();

    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TableCalendar<Todolist>(
                locale: 'ko_KR',
                focusedDay: focusedDay,
                firstDay: DateTime(2024, 1, 1),
                lastDay: DateTime(2030, 12, 31),
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                eventLoader: itemsForDay,
                onDaySelected: (selected, focused) {
                  setState(() {
                    selectedDay = selected;
                    focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  focusedDay = focused;
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Color(0xFFF97316),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Color(0xFFDBEAFE),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w800,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${dateKey(selectedDay)} 일정',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: showAddTodoSheet,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('추가'),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      '선택한 날짜에 일정이 없어요.',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: items.length,
                    onReorder: (oldIndex, newIndex) =>
                        reorderItems(items, oldIndex, newIndex),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Padding(
                        key: ValueKey(item.seq),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CalendarTodoCard(
                          item: item,
                          index: index,
                          onTap: () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => UpdateDetail(todo: item),
                                ),
                              )
                              .then((_) => loadEvents()),
                          onChanged: (checked) async {
                            item.ischeck = checked ? 1 : 0;
                            await handler.updateTodolist(item);
                            await loadEvents();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_add_todo_fab',
        onPressed: showAddTodoSheet,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> showAddTodoSheet() async {
    detailController.clear();
    memoController.clear();
    priorityController.clear();

    await Get.bottomSheet(
      SafeArea(
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
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '일정 추가',
                          style: TextStyle(
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
                      onPressed: insertAction,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('저장하기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> insertAction() async {
    if (detailController.text.trim().isEmpty) {
      Get.snackbar('입력 필요', '할 일을 입력해주세요.');
      return;
    }

    final todo = Todolist(
      detail: detailController.text.trim(),
      addDetail: memoController.text.trim(),
      date: dateKey(selectedDay),
      import: priorityController.text.trim(),
      ischeck: 0,
    );
    try {
      final check = await handler.insertTodolist(todo);
      if (check > 0) {
        Get.back();
        await loadEvents();
        Get.snackbar('저장 완료', '일정이 추가되었습니다.');
      }
    } catch (error) {
      Get.snackbar('저장 실패', error.toString());
    }
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

    final reordered = List<Todolist>.from(items);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    await handler.updateTodoOrder(reordered);
    await loadEvents();
  }
}

class _CalendarTodoCard extends StatelessWidget {
  const _CalendarTodoCard({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onChanged,
  });

  final Todolist item;
  final int index;
  final VoidCallback onTap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final checked = item.ischeck == 1;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: checked
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF111827),
                      decoration: checked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
            if (item.import.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  item.import,
                  style: const TextStyle(
                    color: Color(0xFFC2410C),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
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
