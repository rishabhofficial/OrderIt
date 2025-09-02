import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:startup_namer/globals.dart';
import 'package:startup_namer/model.dart';

import './allProduct.dart';

class DocumentID {
  String docId1;
  String docId2;
  Timestamp date;
  String partyName;
  double amt;
  double discount = 40;
}

class ProdSearch extends StatefulWidget {
  final String prodName;
  ProdSearch(this.prodName);
  @override
  _ProdSearchState createState() => _ProdSearchState();
}

class _ProdSearchState extends State<ProdSearch> {
  Map<DocumentID, ProductData> testList = Map();
  var dataFound = false;
  @override
  void initState() {
    testList.clear();
    fillData(widget.prodName)
        .whenComplete(() => {dataFound = (testList.length > 0) ? true : false});
    super.initState();
  }

  Map<String, double> partyDiscountMap = Map();

  Future<void> fillData(String prodName) async {
    final expiryCollection = FirebaseFirestore.instance.collection('Expiry');
    final QuerySnapshot expirySnapshot = await expiryCollection.get();

    final List<Future<void>> futures = [];

    for (final element in expirySnapshot.docs) {
      final partyName = element['partyName'];

      final partyCollection =
          expiryCollection.doc(element.id).collection(partyName);
      final Future<QuerySnapshot> partySnapshotFuture =
          partyCollection.where('prodName', isEqualTo: prodName).get();

      futures.add(partySnapshotFuture.then((partySnapshot) async {
        for (final doc in partySnapshot.docs) {
          final Map<String, dynamic> elementData =
              element.data() as Map<String, dynamic>;
          final Map<String, dynamic> docData =
              doc.data() as Map<String, dynamic>;

          final docu = DocumentID()
            ..docId1 = element.id
            ..docId2 = doc.id
            ..date = elementData['timestamp']
            ..partyName = elementData['partyName'];

          final prod = ProductData()
            ..qty = int.parse(docData['prodQty']).toString()
            ..name = docData['prodName']
            ..pack = docData['prodPack']
            ..mrp = docData['prodMrp']
            ..deal1 = docData['prodDeal1']
            ..deal2 = docData['prodDeal2']
            ..expiryDate = docData['prodExpiryDate']
            ..batchNumber = docData['prodBatchNumber'];

          docu.amt = elementData['amount'];
          if (!testList.containsKey(docu)) {
            testList[docu] = prod;
            setState(() {});
            dataFound = true;
          }
        }
      }));
    }

    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
          leading: new IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              }),
          actions: [
            IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  setState(() {});
                })
          ],
          title: new Text(
            widget.prodName,
            style: TextStyle(
                color: Colors.white,
                fontSize: 22.0,
                fontWeight: FontWeight.w600),
          ),
        ),
        body: Container(
            child: (testList.length == 0)
                ? (!dataFound
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Center(
                        child: Icon(Icons.hourglass_empty),
                      ))
                : ListView.builder(
                    itemCount: testList.length,
                    itemBuilder: (context, index) {
                      print(testList);
                      DocumentID docu = testList.keys.elementAt(index);
                      ProductData prod = testList.values.elementAt(index);

                      return Column(
                        children: <Widget>[
                          Card(
                            elevation: 10.0,
                            margin: new EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 6.0),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Color.fromRGBO(200, 200, 200, .4)),
                              child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 10.0),
                                  leading: Container(
                                      padding:
                                          EdgeInsets.only(right: 2.0, top: 5),
                                      decoration: new BoxDecoration(
                                          border: new Border(
                                              right: new BorderSide(
                                                  width: 0.5,
                                                  color: Colors.white24))),
                                      child: IconButton(
                                          icon: Icon(Icons.edit),
                                          iconSize: 25,
                                          onPressed: () {
                                            // Find the party code from global party list
                                            GlobalPartyData partyData =
                                                globalPartyList.firstWhere(
                                              (party) =>
                                                  party.partyName ==
                                                  docu.partyName,
                                              orElse: () => GlobalPartyData(
                                                partyName: docu.partyName,
                                                partyCode: '?',
                                                partyLocation: 'Unknown',
                                              ),
                                            );
                                            PartyData data = PartyData(
                                                name: docu.partyName,
                                                defaultDiscount:
                                                    partyDiscountMap[
                                                        docu.partyName],
                                                partyCode: partyData.partyCode);
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        AllProductPage(
                                                            data: data,
                                                            docID: docu.docId1,
                                                            check: true,
                                                            invoiceDate:
                                                                docu.date,
                                                            invoiceAmount:
                                                                docu.amt)));
                                          })),
                                  title: Flexible(
                                    child: Text(
                                      '${docu.partyName}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  subtitle: Wrap(
                                      clipBehavior: Clip.hardEdge,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Text("Pack: ",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text('${prod.pack}',
                                                style: TextStyle(
                                                    color: Colors.black)),
                                            SizedBox(width: 5),
                                            Text("Expiry Date: ",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text('${prod.expiryDate}',
                                                style: TextStyle(
                                                    color: Colors.black)),
                                          ],
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Text("Batch No.: ",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text('${prod.batchNumber}',
                                                style: TextStyle(
                                                    color: Colors.black)),
                                            SizedBox(width: 5),
                                            Text("MRP: ",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text('\u20B9 ${prod.mrp}',
                                                style: TextStyle(
                                                    color: Colors.black)),
                                          ],
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Text("Qty: ",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text('${prod.qty}',
                                                style: TextStyle(
                                                    color: Colors.black)),
                                            SizedBox(width: 5),
                                            Text("Deal: ",
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text('${prod.deal1}+${prod.deal2}',
                                                style: TextStyle(
                                                    color: Colors.black))
                                          ],
                                        ),
                                      ]),
                                  trailing: Container(
                                      child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Column(children: <Widget>[
                                            Text("Date",
                                                style: TextStyle(
                                                    color: Colors.black)),
                                            Text(
                                                '${docu.date.toDate().day}/${docu.date.toDate().month}/${docu.date.toDate().year}',
                                                style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 20)),
                                          ])))),
                            ),
                          )

                          // Divider(height: 1.0,)
                        ],
                      );
                    })));
  }
}
