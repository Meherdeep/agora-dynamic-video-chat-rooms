import 'package:agora_dynamic_channels/pages/callpage.dart';
import 'package:agora_dynamic_channels/pages/homepage.dart';
import 'package:agora_dynamic_channels/pages/lobby.dart';
import 'package:agora_dynamic_channels/pages/loginpage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
      routes: {
        CallPage.routeName: (context) => CallPage(),
        LobbyPage.routeName: (context) => LobbyPage(),
        LoginPage.routeName: (context) => LoginPage(),
      },
    );
  }
}
