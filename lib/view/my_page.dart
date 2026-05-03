import 'package:flutter/material.dart';
import 'package:myprogect/model/todolist.dart';
import 'package:myprogect/vm/database_handler.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key, required this.refreshToken});

  final int refreshToken;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late final TooltipBehavior tooltipBehavior;
  late final DatabaseHandler handler;
  late Future<List<Todolist>> reportFuture;

  @override
  void initState() {
    super.initState();
    tooltipBehavior = TooltipBehavior(enable: true);
    handler = DatabaseHandler();
    reportFuture = handler.queryTodolist();
  }

  @override
  void didUpdateWidget(covariant MyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      refreshReport();
    }
  }

  void refreshReport() {
    setState(() {
      reportFuture = handler.queryTodolist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리포트'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: refreshReport,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Todolist>>(
        future: reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final todos = snapshot.data ?? [];
          if (todos.isEmpty) {
            return const Center(
              child: Text(
                '아직 분석할 데이터가 없어요.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            );
          }

          final total = todos.length;
          final done = todos.where((item) => item.ischeck == 1).length;
          final undone = total - done;
          final weeklyData = _buildWeeklyData(todos);

          return RefreshIndicator(
            onRefresh: () async => refreshReport(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ReportCountCard(
                        title: '\uC804\uCCB4',
                        count: total,
                        color: const Color(0xFF111827),
                        icon: Icons.list_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ReportCountCard(
                        title: '\uC644\uB8CC',
                        count: done,
                        color: const Color(0xFF2563EB),
                        icon: Icons.done_all_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ReportCountCard(
                        title: '\uBBF8\uC644\uB8CC',
                        count: undone,
                        color: const Color(0xFFF97316),
                        icon: Icons.pending_actions_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: SizedBox(
                    height: 340,
                    child: SfCartesianChart(
                      title: ChartTitle(
                        text: '\uCD5C\uADFC 7\uC77C \uB9AC\uD3EC\uD2B8',
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      legend: const Legend(isVisible: true),
                      tooltipBehavior: tooltipBehavior,
                      plotAreaBorderWidth: 0,
                      primaryXAxis: CategoryAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                        labelIntersectAction: AxisLabelIntersectAction.rotate45,
                      ),
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        interval: 1,
                        majorGridLines: const MajorGridLines(
                          color: Color(0xFFE5E7EB),
                        ),
                      ),
                      series: [
                        ColumnSeries<_DailyReport, String>(
                          name: '\uC644\uB8CC',
                          dataSource: weeklyData,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          color: const Color(0xFF2563EB),
                          xValueMapper: (report, _) => report.label,
                          yValueMapper: (report, _) => report.done,
                        ),
                        ColumnSeries<_DailyReport, String>(
                          name: '\uBBF8\uC644\uB8CC',
                          dataSource: weeklyData,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          color: const Color(0xFFF97316),
                          xValueMapper: (report, _) => report.label,
                          yValueMapper: (report, _) => report.undone,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_DailyReport> _buildWeeklyData(List<Todolist> todos) {
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));

    return List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final key = _dateKey(day);
      final dayTodos = todos.where((item) {
        final date = item.date;
        return date != null &&
            date.length >= 10 &&
            date.substring(0, 10) == key;
      }).toList();
      final done = dayTodos.where((item) => item.ischeck == 1).length;

      return _DailyReport(
        label: '${day.month}/${day.day}',
        total: dayTodos.length,
        done: done,
        undone: dayTodos.length - done,
      );
    });
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _ReportCountCard extends StatelessWidget {
  const _ReportCountCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE5E7EB),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count개',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyReport {
  const _DailyReport({
    required this.label,
    required this.total,
    required this.done,
    required this.undone,
  });

  final String label;
  final int total;
  final int done;
  final int undone;
}
