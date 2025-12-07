class Todolist {
  int? seq;
  String detail;
  String? date;
  String? lastdate;
  String addDetail;
  String import;
  int? ischeck;
  
  Todolist(
    {
      this.seq,
      required this.detail,
      this.date,
      this.lastdate,
      required this.addDetail,
      required this.import,
       this.ischeck=0,
    }
  );

  Todolist.fromMap(Map<String,dynamic> res)
  :seq=res['seq'],
  detail=res['detail']??'',
  date=res['date'],
  lastdate=res['lastdate']??'',
  addDetail=res['addDetail']??'',
  import=res['import']??'',
  ischeck=res['ischeck']??0;
  

}