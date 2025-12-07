import 'package:flutter/material.dart';
import 'package:myprogect/model/todolist.dart';
import 'package:myprogect/vm/database_handler.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  late TooltipBehavior tooltipBehavior;
  late DatabaseHandler handler;
  @override
  void initState() {
    super.initState();
    tooltipBehavior = TooltipBehavior(enable: true);
    handler =DatabaseHandler();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(title: Text("마이페이지"),
      
       backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      centerTitle: true,),
       drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
           DrawerHeader(
            
            child: Center(
              child: Text("To Do List",
                         style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30,
                         ),),
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
        mainAxisAlignment: MainAxisAlignment.center,
       
        children: [
    
         
           FutureBuilder(
            future: handler.queryTodolistcheck(),
            builder: (context, snapshot) {
            return  snapshot.hasData && snapshot.data!.isNotEmpty
            ?SizedBox(
              width: 380,
              height: 270,

              child: SfCartesianChart(
                title: ChartTitle(
                  text: "일일 작업 완료 횟수",
                  textStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15
                  )
                  
                ),
                tooltipBehavior: tooltipBehavior,

                series: [
                  
                  ColumnSeries<Todolist,Object>(
                    dataSource: snapshot.data!,
                    xValueMapper: (todolist,_) =>todolist.date, 
                    yValueMapper: (todolist, _) => todolist.ischeck ,
                    ),
                ],
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(text: "일자"),
                  
                  labelIntersectAction: AxisLabelIntersectAction.rotate45,
                ),

                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: '작업완료수'),
                ),
              ),
            )
            :Center(
               child: Text("데이터가 없습니다"),
            );
            },
            
            ),
            
        
        ],
      ),
    );
  }
}
