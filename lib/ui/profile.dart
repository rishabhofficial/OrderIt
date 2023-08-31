import 'dart:async';

import 'package:flutter/material.dart';
import 'package:startup_namer/model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class Profile {
  String name;
  String email;
  String password;
  Profile({this.name, this.email, this.password});

  toJson() {
    return {"name": name, "email": email, "password": password};
  }
}

class ProfileForm extends StatefulWidget {
  @override
  _ProfileFormState createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  TextEditingController _name = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _pass = TextEditingController();

  Profile prof = new Profile();
  bool test = true;
  bool _isHidden = true;
  String random = "";

  @override
  void initState() {
    super.initState();
    _name.clear();
    _email.clear();
    _pass.clear();
  }

  _displaySnackBar(String action) {
    final snackbar = SnackBar(content: Text(action));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  final _scaffoldKey1 = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey1,
      appBar: new AppBar(
        title: Text("Update Profile"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        width: 500,
        decoration: BoxDecoration(color: Colors.grey[100]),
        child: new Column(
          children: <Widget>[
            // Padding(
            //   padding: EdgeInsets.only(top: 10),
            //   child: Text("Enter Company Details", textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),)
            // ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                  controller: _name,
                  //textAlign: TextAlign.center,
                  decoration: new InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    labelText: "Name",
                    fillColor: Colors.white,
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                      borderSide: new BorderSide(),
                    ),
                  )),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                  controller: _email,
                  decoration: new InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    labelText: "Email",
                    fillColor: Colors.black,
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                      borderSide: new BorderSide(),
                    ),
                  )),
            ),
            Padding(
              padding:
                  EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 25),
              child: TextField(
                  obscureText: _isHidden,
                  controller: _pass,
                  decoration: new InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    labelText: "Password",
                    fillColor: Colors.black,
                    suffixIcon: IconButton(
                        icon: Icon(Icons.remove_red_eye),
                        onPressed: () {
                          setState(() {
                            _isHidden = _isHidden ? false : true;
                          });
                        }),
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                      borderSide: new BorderSide(),
                    ),
                  )),
            ),

            ElevatedButton(
                // child: Center(
                child: Text("SUBMIT",
                    style:
                        TextStyle(fontSize: 20, fontStyle: FontStyle.normal)),

                // padding: EdgeInsets.all(30),
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    prof.name = _name.text;
                    prof.email = _email.text;
                    prof.password = _pass.text;
                  });

                  Map<String, dynamic> addComp = prof.toJson();
                  FirebaseFirestore.instance
                      .collection('Profile')
                      .doc("Profile")
                      .update(addComp)
                      .whenComplete(() {
                    _displaySnackBar("Successfully added to database");
                    test = true;
                  }).catchError((e) {
                    test = false;
                  });
                  if (test == false) {
                    _displaySnackBar("Check your internet connection");
                  }
                  if (test == true) {
                    test = false;
                  }
                })
          ],
        ),
      ),
    );
  }
}
