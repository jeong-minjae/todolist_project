import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myprogect/view/home.dart';
import 'package:intl/date_symbol_data_local.dart';   // ← 추가
void main() async{
  runApp(const MyApp());
   await initializeDateFormatting('ko_KR', null);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
     
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
       
      
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      locale: const Locale("ko","KR"),
      home: const Home(),
    );
  }
}

