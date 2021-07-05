import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/login_store.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

Widget eventCalender() {
  return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Container(
    child: SfCalendar(
        view: CalendarView.month,
    ),
  ),
      ));
}

  List<Widget> _children;
  _HomePageState() {
    _children = [Container(),Container(),
      eventCalender()
  ];
 }
  @override
  Widget build(BuildContext context) {
    return Consumer<LoginStore>(
      builder: (_, loginStore, __) {
        return Scaffold(
          body: _children[_selectedIndex],
          drawer: new Drawer(
        child: new ListView(
          children: <Widget>[
            new UserAccountsDrawerHeader(
              accountName: new Text("Pratap Kumar"),
              accountEmail: new Text("kprathap23@gmail.com"),
              decoration: new BoxDecoration(
                color: MyColors.primaryColor
                // image: new DecorationImage(
                //   image: new ExactAssetImage('assets/images/lake.jpeg'),
                //   fit: BoxFit.cover,
                // ),
              ),
              currentAccountPicture: CircleAvatar(
                  backgroundImage: NetworkImage(
                      "https://randomuser.me/api/portraits/men/46.jpg")),
            ),
            new ListTile(
                leading: Icon(Icons.apps),
                title: new Text("Apps"),
                onTap: () {
                  Navigator.pop(context);
                }),
            new ListTile(
                leading: Icon(Icons.dashboard),
                title: new Text("Docs"),
                onTap: () {
                  Navigator.pop(context);
                }),
            new Divider(),
            new ListTile(
                leading: Icon(Icons.info),
                title: new Text("About"),
                onTap: () {
                  Navigator.pop(context);
                }),
            new ListTile(
                leading: Icon(Icons.power_settings_new),
                title: new Text("Signout"),
                onTap: () {
                  loginStore.signOut(context);
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
          backgroundColor: Colors.white,
          bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: MyColors.primaryColor,
        onTap: _onItemTapped,
      ),
    );
          // body: Center(
          //   child: Container(
          //     margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          //     child: RaisedButton(
          //       onPressed: () {
          //         loginStore.signOut(context);
          //       },
          //       color: MyColors.primaryColor,
          //       shape: const RoundedRectangleBorder(
          //           borderRadius: BorderRadius.all(Radius.circular(14))
          //       ),
          //       child: Container(
          //         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          //         child: Row(
          //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //           children: <Widget>[
          //             Text('Sign Out', style: TextStyle(color: Colors.white),),
          //             Container(
          //               padding: const EdgeInsets.all(8),
          //               decoration: BoxDecoration(
          //                 borderRadius: const BorderRadius.all(Radius.circular(20)),
          //                 color: MyColors.primaryColorLight,
          //               ),
          //               child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16,),
          //             )
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          //),
        //);
      },
    );
  }
}