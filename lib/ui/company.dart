import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:startup_namer/model.dart';

import './form.dart';
import './product.dart';

List<String> compName = [];
var check = new Map();
var email = new Map();

class Mails {
  String mailId;
  String cc;
}

class CompanyPage extends StatefulWidget {
  @override
  _CompanyPageState createState() => new _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
        title: new Text(
          "Companies",
          style: TextStyle(
              color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w600),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: DataSearch());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: PopupMenuButton(
                // initialValue: 1,
                onSelected: (int) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => CompanyForm()));
                },
                itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 1,
                        child: Text(
                          "Add New Company",
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                    ]),
          ),
        ],
        //backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Company')
            .orderBy('compName')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return LinearProgressIndicator(
              backgroundColor: Colors.blue[50],
            );
          } else {
            return Container(
                color: Colors.grey[100],
                child: ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot companyList = snapshot.data.docs[index];
                    if (!check.containsKey(companyList['compName'])) {
                      check[companyList['compName']] = true;
                      compName.add(companyList['compName']);
                      Mails mail = Mails();
                      mail.mailId = companyList['compEmail'];
                      mail.cc = companyList['compCC'];
                      email[companyList['compName']] = mail;
                    }
                    return Column(
                      children: <Widget>[
                        ListTile(
                          title: Text(
                            '${companyList['compName']}',
                            style: TextStyle(
                              fontSize: 22,
                            ),
                          ),
                          onLongPress: () {
                            return showDialog(
                              context: context,
                              builder: (BuildContext context) => SimpleDialog(
                                title: Text(
                                  '${companyList['compName']}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 25),
                                ),
                                children: <Widget>[
                                  SimpleDialogOption(
                                    child: Text(
                                      "Delete Company",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 23),
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      FirebaseFirestore.instance
                                          .collection('Company')
                                          .doc(companyList.id)
                                          .delete()
                                          .whenComplete(() {});
                                    },
                                  ),
                                  Divider(
                                    height: 1,
                                  ),
                                  SimpleDialogOption(
                                    child: Text(
                                      "Modify Details",
                                      style: TextStyle(fontSize: 23),
                                      textAlign: TextAlign.center,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      CompanyData dataa = CompanyData(
                                          name: companyList['compName'],
                                          email: companyList['compEmail'],
                                          cc: companyList['compCC']);
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  CompanyUpdateForm(
                                                      dataa, companyList.id)));
                                    },
                                  )
                                ],
                              ),
                            );
                          },
                          onTap: () {
                            final data = CompanyData(
                                email: companyList['compEmail'],
                                name: companyList['compName'],
                                cc: companyList['compCC']);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ProductPage(data: data, check: false)));
                          },
                          leading: new CircleAvatar(
                            child: Text('${companyList['compName'][0]}'),
                            backgroundColor: Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        Divider(
                          height: 0.25,
                        )
                      ],
                    );
                  },
                ));
          }
        },
      ),
    );
  }
}

class DataSearch extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return null;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? compName
        : compName.where((p) => p.startsWith(query)).toList();
    return ListView.builder(
      itemBuilder: (context, index) => ListTile(
        leading: Icon(Icons.details),
        title: Text(suggestionList[index]),
        //  onTap: () {
        //        final data = CompanyData(email: email[suggestionList[index]].mailId, name: suggestionList[index], cc: email[suggestionList[index]].cc);
        //        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductPage(data: data, check: false)));
        //      },
      ),
      itemCount: suggestionList.length,
    );
  }
}
