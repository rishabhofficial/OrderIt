import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:startup_namer/globals.dart';
import 'package:startup_namer/utils/firebase_storage_service.dart';

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

  Profile prof = new Profile(name: '', email: '', password: '');
  bool test = true;
  bool _isHidden = true;
  String random = "";
  bool _isDownloading = false;

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
                }),

            // Data Management Section
            Padding(
              padding: EdgeInsets.only(top: 40, left: 20, right: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Data Management",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Download the latest CSV data files from Firebase Storage to update your local data.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: _isDownloading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Icon(Icons.cloud_download),
                          label: Text(
                            _isDownloading ? "Downloading..." : "Upgrade Data",
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.green,
                            onPrimary: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isDownloading
                              ? null
                              : () async {
                                  setState(() {
                                    _isDownloading = true;
                                  });

                                  try {
                                    bool success = await FirebaseStorageService
                                        .downloadAllCSVFiles();

                                    // Load all CSV data in parallel after downloading
                                    bool dataLoaded = await loadAllCSVData();

                                    if (success && dataLoaded) {
                                      _displaySnackBar(
                                          "Data files downloaded successfully!");
                                    } else if (!success) {
                                      _displaySnackBar(
                                          "Some files failed to download. Please try again.");
                                    } else if (!dataLoaded) {
                                      _displaySnackBar(
                                          "Files downloaded but failed to load data. Please try again.");
                                    }
                                  } catch (e) {
                                    _displaySnackBar(
                                        "Error downloading files: $e");
                                  } finally {
                                    setState(() {
                                      _isDownloading = false;
                                    });
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
