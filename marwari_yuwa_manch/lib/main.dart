// import 'package:flutter/material.dart';
// import './screens/splashScreen.dart';
// import './screens/homeScreen.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: new SplashScreen(),
//       routes: <String, WidgetBuilder>{
//       '/HomeScreen': (BuildContext context) => HomeScreen()
//       }
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './screens/splashScreen.dart';
import './stores/login_store.dart';

void main() => runApp(App());

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LoginStore>(
          create: (_) => LoginStore(),
        )
      ],
      child: const MaterialApp(
        home: SplashPage(),
      ),
    );
  }
}