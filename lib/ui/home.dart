import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:startup_namer/model.dart';

import './company.dart';
import './letterheadList.dart';
import './party.dart';
import './partyReport.dart';
import './product.dart';
import './profile.dart';
import './sentProduct.dart';

class Home extends StatelessWidget {
  Future<List<String>> populateComp() async {
    List<String> _companies = [];
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection("Company")
        .orderBy('compName')
        .get();

    snapshot.docs.forEach((element) {
      if (!_companies.contains(element.data()['compName'])) {
        _companies.add(element.data()['compName']);
      }
    });

    return _companies;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
      bottomNavigationBar: new BottomAppBar(
        color: Color.fromRGBO(58, 66, 86, 1.0),
        shape: CircularNotchedRectangle(),
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.sort),
              color: Colors.white,
              onPressed: () {
                // Directory appDocDirectory = await getApplicationDocumentsDirectory();
                // bool check = await File(appDocDirectory.path + "/" + "mankind.xlsx").exists();
                // print("Check iss ===============>>>>>" + check.toString());
                // Test test = new Test();
                // test.sptest;
              },
            ),
            IconButton(
              icon: Icon(Icons.person),
              color: Colors.white,
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ProfileForm()));
              },
            ),
          ],
        ),
      ),
      body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                elevation: 0.1,
                backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
                expandedHeight: 230.0,
                floating: true,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Text("Order History",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.0,
                        )),
                    background: Image.network(
                      "https://images.pexels.com/photos/396547/pexels-photo-396547.jpeg?auto=compress&cs=tinysrgb&h=350",
                      fit: BoxFit.cover,
                    )),
              ),
            ];
          },
          body: Container(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("Orders")
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  return ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: snapshot.data.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot prodList = snapshot.data.docs[index];
                      return Column(children: <Widget>[
                        Card(
                          elevation: 100.0,
                          shadowColor: Colors.black,
                          margin: new EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 6.0),
                          child: Container(
                            decoration: BoxDecoration(
                                color: Color.fromRGBO(64, 75, 96, .9)),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              leading: Container(
                                padding: EdgeInsets.only(right: 12.0, top: 10),
                                decoration: new BoxDecoration(
                                    border: new Border(
                                        right: new BorderSide(
                                            width: 1.0,
                                            color: Colors.white24))),
                                child: prodList['isSent']
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.green,
                                        size: 35,
                                      )
                                    : Icon(Icons.clear,
                                        color: Colors.red, size: 35),
                              ),
                              title: Text(
                                '${prodList['compName']}',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

                              subtitle: Row(
                                children: <Widget>[
                                  Icon(Icons.date_range,
                                      color: Colors.yellow[200]),
                                  Text('${prodList['date']}',
                                      style: TextStyle(color: Colors.white))
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.keyboard_arrow_right,
                                    color: Colors.white, size: 30.0),
                                onPressed: () {
                                  CompanyData data = CompanyData(
                                      email: prodList['compEmail'],
                                      name: prodList['compName']);
                                  prodList['isSent']
                                      ? Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SentItemsPage(prodList.id,
                                                      prodList['compName'])))
                                      : Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => ProductPage(
                                                    data: data,
                                                    docID: prodList.id,
                                                    check: true,
                                                  )));
                                },
                              ),
                            ),
                          ),
                        )
                      ]);
                    },
                  );
                }
              },
            ),
          )),
      floatingActionButton: new FloatingActionButton(
          backgroundColor: Colors.black,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
          elevation: 2.0,
          onPressed: () {
            const TextStyle _actionSheetTextStyle = TextStyle(
              color: Color.fromRGBO(34, 34, 34, 1.0),
              fontSize: 16,
            );
            final CupertinoActionSheet actionSheet = CupertinoActionSheet(
              actions: <Widget>[
                CupertinoActionSheetAction(
                  child: Text("Generate Letter", style: _actionSheetTextStyle),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LetterHeadPage()),
                    );
                  },
                ),
                CupertinoActionSheetAction(
                  child: Text("Generate Report", style: _actionSheetTextStyle),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PartyReport()),
                    );
                  },
                ),
                CupertinoActionSheetAction(
                  child: Text("Expiry Console", style: _actionSheetTextStyle),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PartyPage()),
                    );
                  },
                ),
                CupertinoActionSheetAction(
                  child: Text("Order Console", style: _actionSheetTextStyle),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CompanyPage()),
                    );
                  },
                )
              ],
              cancelButton: CupertinoActionSheetAction(
                child: Text(
                  "Cancel",
                  style: _actionSheetTextStyle,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            );
            showCupertinoModalPopup<CupertinoActionSheet>(
              context: context,
              builder: (BuildContext context) => actionSheet,
            );
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
