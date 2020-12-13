import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:startup_namer/ui/partyReport.dart';
import 'package:startup_namer/ui/transactionList.dart';
import './allProduct.dart';
import 'package:startup_namer/model.dart';
import './form.dart';


List<String> partyName = [];
var check = new Map();

class PartyPage extends StatefulWidget {
  @override
  _PartyPageState createState() => new _PartyPageState();
}

class _PartyPageState extends State<PartyPage>  {

 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
        title: new Text("Parties", style: TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w600),),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.search),
              onPressed: (){
                showSearch(context: context, delegate: DataSearch());
              },
              ),
          ),
          Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: PopupMenuButton(
                 // initialValue: 1,
                  onSelected: (int) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PartyForm()));
                   
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 1,
                      child: Text("Add New Party", style: TextStyle(
                        fontSize: 16
                      ), textAlign: TextAlign.center,),
                      
                    ),
                  ]
                ),
              ),
        ],
        //backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder(
        stream: Firestore.instance.collection('Party').orderBy('partyName').snapshots(),
      builder: (context, snapshot){
        if (!snapshot.hasData){
                return LinearProgressIndicator(
                  backgroundColor: Colors.blue[50],
                );
              
        }
        else {
          return Container(
          color: Colors.grey[100],   
          child: ListView.builder(
            itemCount: snapshot.data.documents.length,
            itemBuilder: (context, index) {
              DocumentSnapshot partyList=snapshot.data.documents[index];
              if (!check.containsKey(partyList['partyName'])) {
                check[partyList['partyName']] = true;
                partyName.add(partyList['partyName']);
              }
                return Column(
                  children: <Widget>[
                    ListTile(title: Text('${partyList['partyName']}', style: TextStyle(
                    fontSize: 22,
                  ),),
                  onLongPress: (){
                    return showDialog(
                      context: context,
                      child: SimpleDialog(
                        title: Text('${partyList['partyName']}', textAlign: TextAlign.center ,
                                style: TextStyle(
                                  fontSize: 25
                                ),),
                            children: <Widget>[
                              SimpleDialogOption(
                                child: Text("Delete Party", textAlign: TextAlign.center ,
                                style: TextStyle(
                                  fontSize: 23
                                ),),
                                onPressed: (){
                                  Navigator.pop(context);
                                  Firestore.instance.collection('Party').document(partyList.documentID).delete().whenComplete((){

                                  });
                                },
                              ),
                              Divider(height: 1,),
                              SimpleDialogOption(
                                child: Text("Modify Details", style: TextStyle(
                                  fontSize: 23
                                ),textAlign: TextAlign.center,
                                ),
                                onPressed: (){
                                  Navigator.pop(context);
                                  PartyData dataa = PartyData(name: partyList['partyName'], email: partyList['partyEmail'], defaultDiscount: partyList['partyDefaultDiscount']);
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => PartyUpdateForm(dataa,partyList.documentID)));
                                },
                              )
                            ],
                        ),
                    );
                  },
             onTap: () {
               PartyData data = PartyData(name: partyList['partyName'], defaultDiscount: partyList['partyDefaultDiscount']);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ExpiryList(data)));

              //  Navigator.push(context, MaterialPageRoute(builder: (context) => ExpiryList(partyList.documentID, partName)));
             },
                leading: new CircleAvatar(child: Text('${partyList['partyName'][0]}'), backgroundColor: Colors.grey, foregroundColor: Colors.white,),
                ),
                Divider(height: 0.25,)
                ],  
              );
          },
        ));
      }
    },
  ),
  floatingActionButton: new FloatingActionButton(
          backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
              child: const Icon(
                Icons.archive,
                color: Colors.white,
              ),
              elevation: 2.0,
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => PartyReport()));
              })
);
}
}

class DataSearch extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: Icon(Icons.clear), onPressed: (){
        query = '';
      }, )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: AnimatedIcon(
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
    final suggestionList = query.isEmpty?partyName:partyName.where((p) => p.startsWith(query)).toList();
    return ListView.builder(
      itemBuilder: (context, index) => ListTile(
        leading: Icon(Icons.details),
        title: Text(suggestionList[index]),
        ),
        itemCount: suggestionList.length,
    );
  }
}
