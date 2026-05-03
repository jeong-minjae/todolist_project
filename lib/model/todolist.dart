class Todolist {
  int? seq;
  String detail;
  String? date;
  String addDetail;
  String import;
  int? ischeck;
  int? sortOrder;

  Todolist({
    this.seq,
    required this.detail,
    this.date,
    required this.addDetail,
    required this.import,
    this.ischeck = 0,
    this.sortOrder,
  });

  Todolist.fromMap(Map<String, dynamic> res)
    : seq = res['seq'],
      detail = res['detail'] ?? '',
      date = res['date'],
      addDetail = res['addDetail'] ?? '',
      import = res['import'] ?? '',
      ischeck = res['ischeck'] ?? 0,
      sortOrder = res['sortOrder'];
}
