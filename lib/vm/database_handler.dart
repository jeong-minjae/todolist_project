import 'package:myprogect/model/todolist.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


/*
  int? seq;
  String detail;
  String? date;
  String? lastdate;
  String addDetail;
  String import;



*/

class DatabaseHandler {
  //테이블 만들기
  Future<Database>initalizeDB() async{
    String path=await getDatabasesPath();

    return openDatabase(
      
       join(path,"todolist.db"),
       onCreate: (db, version)async {
         await db.execute(
          """
          create table todolist(
          seq integer primary key autoincrement,
          detail text,
          date date,
          lastdate date,
          addDetail text,
          import text,
          ischeck integer  
          )

          """
         );
       }, 
         version: 1,

    );
  }
  //테이블 불러오기 날짜 순서대로 정리
   Future<List<Todolist>> queryTodolist()async{
    final Database db =await initalizeDB();
    final List<Map<String,Object?>> queryResult =await db.rawQuery(
      """
      select *from todolist
      order by date asc
      """
    );
      return queryResult.map((e) => Todolist.fromMap(e)).toList();
   }
   //테이블 마감날짜 순서대로 정리
 Future<List<Todolist>> queryTodolistlastdate()async{
    final Database db =await initalizeDB();
    final List<Map<String,Object?>> queryResult =await db.rawQuery(
      """
      select *from todolist
      order by lastdate asc
      """
    );
      return queryResult.map((e) => Todolist.fromMap(e)).toList();
   }
//날짜에 따리 출력 마감일자로 정리

  //완료횟수 카운트 그래프에 쓸거임
  Future<List<Todolist>> queryTodolistcheck()async{
    final Database db =await initalizeDB();
    final List<Map<String,Object?>> queryResult =await db.rawQuery(
      """
     SELECT 
      seq,
      detail,
      addDetail,
      import,
      lastdate,
      substr(date, 1, 10) AS date,
      SUM(ischeck) AS ischeck
    FROM todolist
    GROUP BY substr(date, 1, 10)
    ORDER BY date
      
       
      """
    );
      return queryResult.map((e) => Todolist.fromMap(e)).toList();
   }

   //내가 입력한 데이터 테이블에 삽입
   Future<int> insertTodolist(Todolist todolist) async{
    int result=0;
    final Database db =await initalizeDB();
    result=await db.rawInsert(
      """
      insert into todolist
      (detail,date,addDetail,lastdate,import,ischeck)
      values
      (?,?,?,?,?,?)
      """,
      [
        todolist.detail,
        todolist.date,
        todolist.addDetail,
        todolist.lastdate,
        todolist.import,
        todolist.ischeck
      
      
      ]
    );
    return result;
   }
  //입력한데이터 수정 
   Future<int> updateTodolist(Todolist todolist)async{
      int result=0;
      final Database db = await initalizeDB();
      result = await db.rawUpdate( //여기 부분만 있으면된다
        """
        update todolist
        set detail=?,lastdate=?,addDetail=?,import=?,ischeck=?
        where seq=?

        """,
      [
        todolist.detail,
        todolist.lastdate,
        todolist.addDetail,
        todolist.import,
        todolist.ischeck,
        todolist.seq,


      ]
      );
   

      return result;

}


 //입력한 데이터 삭제
Future<void> deleteTodolist(int seq)async{
      
      final Database db = await initalizeDB();
       await db.rawUpdate( //여기 부분만 있으면된다
        """
        delete from todolist
        where seq=?

        """,
      [seq]
      );
     
      

  //삭제
}
}
/*
  int? seq;
  String detail;
  String? date;
  String? lastdate;
  String addDetail;
  String import;



*/