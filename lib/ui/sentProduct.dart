import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SentItemsPage extends StatelessWidget {
  final String docID, compName;
  SentItemsPage(this.docID, this.compName);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Products",
          style: TextStyle(
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Orders')
            .doc(docID)
            .collection(compName)
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
                    DocumentSnapshot prodList = snapshot.data.docs[index];
                    return Column(
                      children: <Widget>[
                        ListTile(
                          title: Text(
                            '${prodList['prodName']}',
                            style: TextStyle(
                              fontSize: 22,
                            ),
                          ),
                          subtitle: Text(
                            'Pack: ' + '${prodList['prodPack']}',
                            style: TextStyle(fontSize: 18),
                          ),
                          trailing: Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Text(
                              '${prodList['prodQty']}',
                              style: TextStyle(fontSize: 25),
                            ),
                          ),

                          //subtitle: Text('${companyList['compEmail']}', style: TextStyle(
                          //  fontSize: 18,), ),
                          // leading: new CircleAvatar(child: Text('${prodList['name'][0]}'), backgroundColor: Colors.grey, foregroundColor: Colors.white,),
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
