import 'package:flutter/material.dart';
import 'package:startup_namer/model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyForm extends StatefulWidget {
  @override
  _CompanyFormState createState() => _CompanyFormState();
}

class _CompanyFormState extends State<CompanyForm> {

TextEditingController _name = TextEditingController();
TextEditingController _email = TextEditingController();
TextEditingController _cc = TextEditingController();
TextEditingController _mn = TextEditingController();
TextEditingController _l = TextEditingController();
CompanyData newComp = CompanyData();
bool test = true;


@override
void initState(){
  super.initState();
  _name.clear();
  _email.clear();
  _cc.clear();
  _mn.clear();
  _l.clear();
}

_displaySnackBar(String action){
           final snackbar = SnackBar(content: Text(action));
 _scaffoldKey1.currentState.showSnackBar(snackbar); 

}
  final _scaffoldKey1 = GlobalKey<ScaffoldState>(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey1,
      appBar: new AppBar(
        title: Text("Add New Company"),
        leading: IconButton(icon: Icon(Icons.arrow_back),
        onPressed: (){
          Navigator.pop(context);
      },),),
      body: Container(
          width: 500,
        decoration: BoxDecoration(
         color: Colors.grey[100]
        ),
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
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Name",
                              fillColor: Colors.white,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0),
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),  
             Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                controller: _email,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Email",
                                 fillColor: Colors.black,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0), 
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                controller: _mn,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Mailing Name",
                                 fillColor: Colors.black,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0), 
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                controller: _l,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Location",
                                 fillColor: Colors.black,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0), 
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20,bottom: 30),
              child: TextField(
                controller: _cc,
                //textAlign: TextAlign.center,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "CC",
                              fillColor: Colors.white,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0),
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),  
            RaisedButton(
             // child: Center(
                child: Text("SUBMIT", style: TextStyle(
                  fontSize: 20, fontStyle: FontStyle.normal
                )),
              
             // padding: EdgeInsets.all(30),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                setState(() {
                 newComp.name = _name.text;
                 newComp.email = _email.text;
                 newComp.cc = _cc.text;
                 newComp.mailingName = _mn.text;
                 newComp.mailingLocation = _l.text;
                });
              //   CollectionReference dbReplies = Firestore.instance.collection('Company');

              // Firestore.instance.runTransaction((Transaction tx) async {
              //   print(await dbReplies.add(newComp.toJson()));
              //               },
                            
              
           // ); 
      Map<String, dynamic> addComp = newComp.toJson();
      Firestore.instance.collection('Company').add(addComp).whenComplete((){
          _displaySnackBar("Successfully added to database");
          test = true;
          _name.clear();
          _email.clear();
          _cc.clear();
          _mn.clear();
          _l.clear();
      }).catchError((e) {
             test = false;
      });
      if(test == false){
          _displaySnackBar("Check your internet connection");
      }
      if(test == true){
        test =false;
      }
        

          
            
              })
            
          ],
        ),
      ),
    );
  }
}

class CompanyUpdateForm extends StatefulWidget {

  final CompanyData initialData;
  final String docId;
  CompanyUpdateForm(this.initialData, this.docId);
  @override
  _CompanyUpdateFormState createState() => _CompanyUpdateFormState();
}

class _CompanyUpdateFormState extends State<CompanyUpdateForm> {

TextEditingController _name = TextEditingController();
TextEditingController _email = TextEditingController();
TextEditingController _cc = TextEditingController();
TextEditingController _mn = TextEditingController();
TextEditingController _l = TextEditingController();
CompanyData newComp = CompanyData();
bool test = true;

@override
void initState(){
  super.initState();
  _name.text = widget.initialData.name;
  _email.text = widget.initialData.email;
  _cc.text = widget.initialData.cc;
}

_displaySnackBar(String action){
           final snackbar = SnackBar(content: Text(action));
 _scaffoldKey2.currentState.showSnackBar(snackbar); 

}
  final _scaffoldKey2 = GlobalKey<ScaffoldState>(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey2,
      appBar: new AppBar(
        title: Text("Update Company Details"),
        leading: IconButton(icon: Icon(Icons.arrow_back),
        onPressed: (){
          Navigator.pop(context);     },),),
      body: Container(
          width: 500,
        decoration: BoxDecoration(
         color: Colors.grey[100]
        ),
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
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Name",
                              fillColor: Colors.white,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0),
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),  
             Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                controller: _email,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Email",
                                 fillColor: Colors.black,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0), 
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20,bottom: 30),
              child: TextField(
                controller: _cc,
                //textAlign: TextAlign.center,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "CC",
                              fillColor: Colors.white,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0),
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
             Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                controller: _mn,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Mailing Name",
                                 fillColor: Colors.black,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0), 
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                controller: _l,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Location",
                                 fillColor: Colors.black,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0), 
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            RaisedButton(
             // child: Center(
                child: Text("SUBMIT", style: TextStyle(
                  fontSize: 20, fontStyle: FontStyle.normal
                )),
              
             // padding: EdgeInsets.all(30),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                setState(() {
                 newComp.name = _name.text;
                 newComp.email = _email.text;
                 newComp.cc= _cc.text; 
                 newComp.mailingName = _mn.text;
                 newComp.mailingLocation = _l.text;
                });
      Map<String, dynamic> addComp = newComp.toJson();
      Firestore.instance.collection('Company').document(widget.docId).updateData(addComp).whenComplete((){
          _displaySnackBar("Successfully updated to database");
          test = true;
          _name.clear();
          _email.clear();
          _cc.clear();
          _mn.clear();
          _l.clear();
      }).catchError((e) {
             test = false;
      });
      if(test == false){
          _displaySnackBar("Check your internet connection");
      }
      if(test == true){
        test =false;
      }
        

          
            
              })
            
          ],
        ),
      ),
    );
  }
}

class ProductForm extends StatefulWidget {

  final String compName;
  ProductForm(this.compName);
  @override
  _ProductFormState createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {

TextEditingController _name = TextEditingController();
TextEditingController _pack = TextEditingController();
TextEditingController _div = TextEditingController();
ProductData newProd = ProductData();
bool test = true;


@override
void initState(){
  super.initState();
  _name.clear();
  _pack.clear();
  _div.clear();
}

_displaySnackBar(String action){
           final snackbar = SnackBar(content: Text(action));
 _scaffoldKey3.currentState.showSnackBar(snackbar); 

}
  final _scaffoldKey3 = GlobalKey<ScaffoldState>(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey3,
      appBar: new AppBar(
        title: Text("Add New Product"),
        leading: IconButton(icon: Icon(Icons.arrow_back),
        onPressed: (){
          Navigator.pop(context);
      },),),
      body: Container(
          width: 500,
        decoration: BoxDecoration(
         color: Colors.grey[100]
        ),
        child: new Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                controller: _name,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Name",
                              fillColor: Colors.white,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0),
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),  
             Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                controller: _pack,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Pack",
                                 fillColor: Colors.black,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0), 
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
             Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20,bottom: 30),
              child: TextField(
                controller: _div,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Division",
                               fillColor: Colors.white,
                               enabled: (widget.compName == "ALKEM" || widget.compName == "ABT INDIA")?true:false,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0),
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            RaisedButton(
                child: Text("SUBMIT", style: TextStyle(
                  fontSize: 20, fontStyle: FontStyle.normal
                )),
              
              onPressed: () async {
                FocusScope.of(context).unfocus();
                setState(() {
                 newProd.name = _name.text;
                 newProd.pack = _pack.text;
                 newProd.division = _div.text;
                });
      Map<String, dynamic> addProd = newProd.toJson();
      print(widget.compName);
      Firestore.instance.collection(widget.compName).add(addProd).whenComplete((){
          _displaySnackBar("Successfully added to database");
          test = true;
          _name.clear();
          _pack.clear();
          _div.clear();
      }).catchError((e) {
             test = false;
      });
      if(test == false){
          _displaySnackBar("Check your internet connection");
      }
      if(test == true){
        test =false;
      }
        

          
            
              })
            
          ],
        ),
      ),
    );
  }
}

class ProductUpdateForm extends StatefulWidget {

  final ProductData initialData;
  final String docId;
  final String compName;
  ProductUpdateForm(this.initialData, this.docId, this.compName);
  @override
  _ProductUpdateFormState createState() => _ProductUpdateFormState();
}

class _ProductUpdateFormState extends State<ProductUpdateForm> {

TextEditingController _name = TextEditingController();
TextEditingController _pack = TextEditingController();
TextEditingController _div = TextEditingController();
ProductData newProd = ProductData();
bool test = true;

@override
void initState(){
  super.initState();
  _name.text = widget.initialData.name;
  _pack.text = widget.initialData.pack;
  _div.text = widget.initialData.division;
}

_displaySnackBar(String action){
           final snackbar = SnackBar(content: Text(action));
 _scaffoldKey4.currentState.showSnackBar(snackbar); 

}
  final _scaffoldKey4 = GlobalKey<ScaffoldState>(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey4,
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
        title: Text("Update Product Details"),
        leading: IconButton(icon: Icon(Icons.arrow_back),
        onPressed: (){
          Navigator.pop(context);     },),),
      body: Container(
          width: 500,
        decoration: BoxDecoration(
         color: Colors.grey[100]
        ),
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
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Name",
                              fillColor: Colors.white,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0),
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),  
             Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                controller: _pack,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Pack",
                                 fillColor: Colors.black,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0), 
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20,bottom: 30),
              child: TextField(
                controller: _div,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Division",
                               enabled: (widget.compName == "ALKEM" || widget.compName == "ABT INDIA")?true:false,
                                 fillColor: Colors.black,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0), 
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            RaisedButton(
             // child: Center(
                child: Text("SUBMIT", style: TextStyle(
                  fontSize: 20, fontStyle: FontStyle.normal
                )),
              
             // padding: EdgeInsets.all(30),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                setState(() {
                 newProd.name = _name.text;
                 newProd.pack = _pack.text; 
                 newProd.division = _div.text; 
                });
      Map<String, dynamic> addProd = newProd.toJson();
      Firestore.instance.collection(widget.compName).document(widget.docId).updateData(addProd).whenComplete((){
          _displaySnackBar("Successfully updated to database");
          test = true;
          _name.clear();
          _pack.clear();
          _div.clear();
      }).catchError((e) {
             test = false;
      });
      if(test == false){
          _displaySnackBar("Check your internet connection");
      }
      if(test == true){
        test =false;
      }
         
              })
            
          ],
        ),
      ),
    );
  }
}

// class ProfileUpdateForm extends StatefulWidget {

//   final ProductData initialData;
//   final String docId;
//   final String compName;
//   ProfileUpdateForm(this.initialData, this.docId, this.compName);
//   @override
//   _ProfileUpdateFormState createState() => _ProfileUpdateFormState();
// }

// class _ProfileUpdateFormState extends State<ProfileUpdateForm> {

// TextEditingController _name = TextEditingController();
// TextEditingController _email = TextEditingController();
// TextEditingController _pass = TextEditingController();
// ProductData newProd = ProductData();
// bool test = true;

// @override
// void initState(){
//   super.initState();
//   _name.text = widget.initialData.name;
//   _email.text = widget.initialData.pack;
// }

// _displaySnackBar(String action){
//            final snackbar = SnackBar(content: Text(action));
//  _scaffoldKey4.currentState.showSnackBar(snackbar); 

// }
//   final _scaffoldKey4 = GlobalKey<ScaffoldState>(); 

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey4,
//       appBar: new AppBar(
//         backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
//         title: Text("Update Product Details"),
//         leading: IconButton(icon: Icon(Icons.arrow_back),
//         onPressed: (){
//           Navigator.pop(context);     },),),
//       body: Container(
//           width: 500,
//         decoration: BoxDecoration(
//          color: Colors.grey[100]
//         ),
//         child: new Column(
//           children: <Widget>[
//             // Padding(
//             //   padding: EdgeInsets.only(top: 10),
//             //   child: Text("Enter Company Details", textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),)
//             // ),
//             Padding(
//               padding: EdgeInsets.only(top: 30, left: 20, right: 20),
//               child: TextField(
//                 controller: _name,
//                 //textAlign: TextAlign.center,
//                 decoration: new InputDecoration(
//                               contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                labelText: "Name",
//                               fillColor: Colors.white,
//                                border: new OutlineInputBorder(
//                                  borderRadius: new BorderRadius.circular(15.0),
//                                  borderSide: new BorderSide(),
//                                 ),)

//               ),
//             ),  
//              Padding(
//               padding: EdgeInsets.only(top: 30, left: 20, right: 20,bottom: 30),
//               child: TextField(
//                 controller: _pack,
//                 decoration: new InputDecoration(
//                               contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                labelText: "Pack",
//                                  fillColor: Colors.black,
//                                border: new OutlineInputBorder(
//                                  borderRadius: new BorderRadius.circular(15.0), 
//                                  borderSide: new BorderSide(),
//                                 ),)

//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.only(top: 30, left: 20, right: 20,bottom: 30),
//               child: TextField(
//                 controller: _pack,
//                 decoration: new InputDecoration(
//                               contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                labelText: "Password",
//                                  fillColor: Colors.black,
//                                border: new OutlineInputBorder(
//                                  borderRadius: new BorderRadius.circular(15.0), 
//                                  borderSide: new BorderSide(),
//                                 ),)

//               ),),
//             RaisedButton(
//              // child: Center(
//                 child: Text("SUBMIT", style: TextStyle(
//                   fontSize: 20, fontStyle: FontStyle.normal
//                 )),
              
//              // padding: EdgeInsets.all(30),
//               onPressed: () async {
//                 FocusScope.of(context).unfocus();
//                 setState(() {
//                  newProd.name = _name.text;
//                  newProd.pack = _pack.text; 
//                 });
//       Map<String, dynamic> addProd = newProd.toJson();
//       Firestore.instance.collection(widget.compName).document(widget.docId).updateData(addProd).whenComplete((){
//           _displaySnackBar("Successfully updated to database");
//           test = true;
//           _name.clear();
//           _pack.clear();
//       }).catchError((e) {
//              test = false;
//       });
//       if(test == false){
//           _displaySnackBar("Check your internet connection");
//       }
//       if(test == true){
//         test =false;
//       }
         
//               })
            
//           ],
//         ),
//       ),
//     );
//   }
// }

class PartyForm extends StatefulWidget {
  @override
  _PartyFormState createState() => _PartyFormState();
}

class _PartyFormState extends State<PartyForm> {

TextEditingController _name = TextEditingController();
TextEditingController _email = TextEditingController();
TextEditingController _dd = TextEditingController();
PartyData newParty = PartyData();
bool test = true;


@override
void initState(){
  super.initState();
  _name.clear();
  _email.clear();
  _dd.clear();
}

_displaySnackBar(String action){
           final snackbar = SnackBar(content: Text(action));
 _scaffoldKey1.currentState.showSnackBar(snackbar); 

}
  final _scaffoldKey1 = GlobalKey<ScaffoldState>(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey1,
      appBar: new AppBar(
        title: Text("Add New Party"),
        leading: IconButton(icon: Icon(Icons.arrow_back),
        onPressed: (){
          Navigator.pop(context);
      },),),
      body: Container(
          width: 500,
        decoration: BoxDecoration(
         color: Colors.grey[100]
        ),
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
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Name",
                              fillColor: Colors.white,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0),
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),  
             Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                controller: _email,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Email",
                                 fillColor: Colors.black,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0), 
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20,bottom: 30),
              child: TextField(
                controller: _dd,
                //textAlign: TextAlign.center,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Default Discount",
                              fillColor: Colors.white,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0),
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),  
            RaisedButton(
             // child: Center(
                child: Text("SUBMIT", style: TextStyle(
                  fontSize: 20, fontStyle: FontStyle.normal
                )),
              
             // padding: EdgeInsets.all(30),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                setState(() {
                 newParty.name = _name.text;
                 newParty.email = _email.text;
                 newParty.defaultDiscount = double.parse(_dd.text);
                });
              //   CollectionReference dbReplies = Firestore.instance.collection('Company');

              // Firestore.instance.runTransaction((Transaction tx) async {
              //   print(await dbReplies.add(newComp.toJson()));
              //               },
                            
              
           // ); 
      Map<String, dynamic> addParty = newParty.toJson();
      Firestore.instance.collection('Party').add(addParty).whenComplete((){
          _displaySnackBar("Successfully added to database");
          test = true;
          _name.clear();
          _email.clear();
          _dd.clear();
      }).catchError((e) {
             test = false;
      });
      if(test == false){
          _displaySnackBar("Check your internet connection");
      }
      if(test == true){
        test =false;
      }
        

          
            
              })
            
          ],
        ),
      ),
    );
  }
}

class PartyUpdateForm extends StatefulWidget {

  final PartyData initialData;
  final String docId;
  PartyUpdateForm(this.initialData, this.docId);
  @override
  _PartyUpdateFormState createState() => _PartyUpdateFormState();
}

class _PartyUpdateFormState extends State<PartyUpdateForm> {

TextEditingController _name = TextEditingController();
TextEditingController _email = TextEditingController();
TextEditingController _dd = TextEditingController();
PartyData newComp = PartyData();
bool test = true;

@override
void initState(){
  super.initState();
  _name.text = widget.initialData.name;
  _email.text = widget.initialData.email;
  _dd.text = widget.initialData.defaultDiscount.toString();
}

_displaySnackBar(String action){
           final snackbar = SnackBar(content: Text(action));
 _scaffoldKey2.currentState.showSnackBar(snackbar); 

}
  final _scaffoldKey2 = GlobalKey<ScaffoldState>(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey2,
      appBar: new AppBar(
        title: Text("Update Party Details"),
        leading: IconButton(icon: Icon(Icons.arrow_back),
        onPressed: (){
          Navigator.pop(context);     },),),
      body: Container(
          width: 500,
        decoration: BoxDecoration(
         color: Colors.grey[100]
        ),
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
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Name",
                              fillColor: Colors.white,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0),
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),  
             Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                controller: _email,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Email",
                                 fillColor: Colors.black,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0), 
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20,bottom: 30),
              child: TextField(
                controller: _dd,
                //textAlign: TextAlign.center,
                decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                               labelText: "Default Discount",
                              fillColor: Colors.white,
                               border: new OutlineInputBorder(
                                 borderRadius: new BorderRadius.circular(15.0),
                                 borderSide: new BorderSide(),
                                ),)

              ),
            ),
            RaisedButton(
             // child: Center(
                child: Text("SUBMIT", style: TextStyle(
                  fontSize: 20, fontStyle: FontStyle.normal
                )),
              
             // padding: EdgeInsets.all(30),
              onPressed: () async {
                FocusScope.of(context).unfocus();
                setState(() {
                 newComp.name = _name.text;
                 newComp.email = _email.text;
                 newComp.defaultDiscount = double.parse(_dd.text); 
                });
      Map<String, dynamic> addComp = newComp.toJson();
      Firestore.instance.collection('Party').document(widget.docId).updateData(addComp).whenComplete((){
          _displaySnackBar("Successfully updated to database");
          test = true;
          _name.clear();
          _email.clear();
          _dd.clear();
      }).catchError((e) {
             test = false;
      });
      if(test == false){
          _displaySnackBar("Check your internet connection");
      }
      if(test == true){
        test =false;
      }
        

          
            
              })
            
          ],
        ),
      ),
    );
  }
}
