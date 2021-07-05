// import 'package:flutter/material.dart';
// import 'dart:async';


// class SplashScreen extends StatefulWidget {
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {

//   @override
//   void initState() {
//     super.initState();
//     Timer(Duration(seconds: 25),() => Navigator.of(context).pushReplacementNamed('/HomeScreen'));
//   }

  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(color: Colors.white),
//       child: Center(
//         child: Container(
//           height: 230,
//           width: 230,
//           child: Image.asset('assets/images/mym_logo.png'),
//         ),
//       ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/homeScreen.dart';
import '../screens/loginScreen.dart';
import '../stores/login_store.dart';
import '../theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key key}) : super(key: key);
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    Provider.of<LoginStore>(context, listen: false).isAlreadyAuthenticated().then((result) {
      if (result) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomePage()), (Route<dynamic> route) => false);
      } else {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (Route<dynamic> route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.primaryColor,
    );
  }
}