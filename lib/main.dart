import 'package:flutter/material.dart';
import 'package:startup_namer/ui/partyReport.dart';
import 'package:startup_namer/ui/splashScreen.dart';
import './ui/splashScreen.dart';
import './ui/home.dart';
import 'package:firebase_core/firebase_core.dart';
import './ui/partyReport.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Flutter Demo',
        theme: new ThemeData(primaryColor: Color.fromRGBO(58, 66, 86, 1.0)),
        home: new SplashScreen(),
        routes: <String, WidgetBuilder>{
          '/HomeScreen': (BuildContext context) => Home()
        });
  }
}
