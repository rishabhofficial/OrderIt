import 'package:flutter/material.dart';
import 'package:startup_namer/ui/splashScreen.dart';
import './ui/splashScreen.dart';
import './ui/home.dart';
import './ui/login.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(primaryColor: Color.fromRGBO(58, 66, 86, 1.0)),
      home: new SplashScreen(),
      routes: <String, WidgetBuilder>{
      '/HomeScreen': (BuildContext context) => Home() 
      }
    );
  }
}
