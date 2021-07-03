import 'package:flutter/material.dart';
import 'package:startup_namer/model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';





class Test extends StatelessWidget {
  String comp = "ZORYL-M-3";
  
  List<List<String>> fillData() {
   // batch.clear();
    
    List<List<String>> m = List();
   
  //print(comp);
  //print(divi);

Firestore.instance.collection('Expiry').snapshots().listen((event) => event.documents.forEach((element) {
    Firestore.instance.collection('Expiry').document(element.documentID).collection(element['partyName']).where('prodName', isEqualTo: comp).snapshots().listen(
  
      (cour)=> cour.documents.forEach((doc) {
                
          ProductData prod = ProductData();
          String partyName = element.data['partyName'];
          Timestamp date = element.data['timestamp'];
          prod.qty = int.parse(doc.data['prodQty']).toString();
          prod.name = doc.data['prodName'];
          prod.pack = doc.data['prodPack'];
          prod.mrp  = doc.data['prodMrp'];
          prod.expiryDate = doc.data['prodExpiryDate'];
          prod.batchNumber = doc.data['prodBatchNumber'];
          m.add([prod.name, prod.batchNumber, partyName, date.toString(), prod.qty, prod.mrp.toString()]);

        
      }
    )
  );
}) );
   return m;
} 



  @override
  Widget build(BuildContext context) {
    return Scaffold( 
    body:
    Center(
        child: RaisedButton(
          onPressed: (){
            var x = fillData();
            new Future.delayed(new Duration(seconds: 5), () {
                          Navigator.of(context).pop(); 
                          print(x);
                          
          });
          }
        ),
    ));
  }
}





