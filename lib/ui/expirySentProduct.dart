import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './localPartyReport.dart';

class ExpirySentProductList extends StatelessWidget {
  final String docID, partyName;
  final double defaultDisc;
  final Timestamp invoiceDate;
  final double invoiceAmount;
  ExpirySentProductList(this.docID, this.partyName, this.defaultDisc, this.invoiceAmount, this.invoiceDate);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Products",
          style: TextStyle(
            fontSize: 22,
          ),
        ),
        actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 5.0),
                child: IconButton(icon: Icon(Icons.picture_as_pdf),
                  onPressed: ()
                  {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LocalPartyReport(partyName: partyName, docID: docID, defaultDisc: defaultDisc, invoiceDate: invoiceDate, invoiceAmount: invoiceAmount )));},
                    
                ),
              ),]
      ),
      body: StreamBuilder(
        stream: Firestore.instance.collection('Expiry').document(docID).collection(partyName).snapshots(),
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
              DocumentSnapshot prodList=snapshot.data.documents[index];
                return Column(
                  children: <Widget>[
                    ListTile(title: Text('${prodList['prodName']}', style: TextStyle(
                    fontSize: 22,
                  ),),
                  subtitle: Text('Pack: ' + '${prodList['prodPack']}',
                      style: TextStyle(
                        fontSize: 18
                      ),),
                  trailing: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text('${prodList['prodQty']}',
                      style: TextStyle(
                        fontSize: 25
                      ),
                  ),),
             
                //subtitle: Text('${companyList['compEmail']}', style: TextStyle(
                //  fontSize: 18,), ),
               // leading: new CircleAvatar(child: Text('${prodList['name'][0]}'), backgroundColor: Colors.grey, foregroundColor: Colors.white,),
                ),
                Divider(height: 0.25,)
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