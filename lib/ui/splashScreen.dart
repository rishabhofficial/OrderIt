import 'package:flutter/material.dart';
import 'dart:async';
import 'home.dart';


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2),() => Navigator.of(context).pushReplacementNamed('/HomeScreen'));
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Colors.black),
      child: Center(
        child: Container(
          child: Image.asset('asset/Orderit.jpg'),
        ),
      ),
      ),
    );
  }
}