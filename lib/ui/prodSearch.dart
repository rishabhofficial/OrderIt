import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    testList.clear();
    fillData(widget.prodName);
    super.initState();
  }

  Map<String, double> m = Map();

  discountList() {
    FirebaseFirestore.instance
        .collection("Party")
        .snapshots()
        .listen((event) => event.docs.forEach((element) {
              m[element['partyName']] = element['partyDefaultDiscount'];
            }));
  }

  fillData(String prodName) {
    print("1");
    //Map<DocumentID,ProductData> prodList = Map();
    FirebaseFirestore.instance
        .collection('Expiry')
        .snapshots()
        .listen((event) => event.docs.forEach((element) {
              FirebaseFirestore.instance
                  .collection('Expiry')
                  .doc(element.id)
                  .collection(element['partyName'])
                  .where('prodName', isEqualTo: prodName)
                  .snapshots()
                  .listen((cour) => cour.docs.forEach((doc) {
                        print("2");
                        DocumentID docu = DocumentID();
                        docu.docId1 = element.id;
                        docu.docId2 = doc.id;
                        docu.date = element['timestamp'];
                        docu.partyName = element['partyName'];
                        //docu.discount   = FirebaseFirestore.instance.collection("Party").where('partyName', isEqualTo: docu.partyName).getDocuments()

                        print("3");
                        ProductData prod = ProductData();
                        print("6");
                        prod.qty = int.parse(doc.data()['prodQty']).toString();
                        print("7");
                        prod.name = doc.data()['prodName'];
                        prod.pack = doc.data()['prodPack'];
                        print("8");
                        prod.mrp = doc.data()['prodMrp'];
                        prod.deal1 = doc.data()['prodDeal1'];
                        prod.deal2 = doc.data()['prodDeal2'];
                        prod.expiryDate = doc.data()['prodExpiryDate'];
                        prod.batchNumber = doc.data()['prodBatchNumber'];
                        print("9");
                        docu.amt = element['amount'];
                        print("5");
                        if (!testList.containsKey(docu)) {
                          print("4");
                          testList[docu] = prod;
                        }
                      }));
            }));
    // print(prodList);
    //return testList;
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
        body: ListView.builder(
          itemCount: testList.length,
          itemBuilder: (context, index) {
            print(testList);
            DocumentID docu = testList.keys.elementAt(index);
            ProductData prod = testList.values.elementAt(index);
            return Column(
              children: <Widget>[
                Card(
                  elevation: 10.0,
                  margin:
                      new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                  child: Container(
                    decoration:
                        BoxDecoration(color: Color.fromRGBO(200, 200, 200, .4)),
                    child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 10.0),
                        leading: Container(
                            padding: EdgeInsets.only(right: 2.0, top: 5),
                            decoration: new BoxDecoration(
                                border: new Border(
                                    right: new BorderSide(
                                        width: 0.5, color: Colors.white24))),
                            child: IconButton(
                                icon: Icon(Icons.edit),
                                iconSize: 25,
                                onPressed: () {
                                  PartyData data = PartyData(
                                      name: docu.partyName,
                                      defaultDiscount: m[docu.partyName]);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AllProductPage(
                                              data: data,
                                              docID: docu.docId1,
                                              check: true,
                                              invoiceDate: docu.date,
                                              invoiceAmount: docu.amt)));
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
                        subtitle: Column(children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text("Pack: ",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                              Text('${prod.pack}',
                                  style: TextStyle(color: Colors.black)),
                              SizedBox(width: 5),
                              Text("Expiry Date: ",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                              Text('${prod.expiryDate}',
                                  style: TextStyle(color: Colors.black)),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Text("Batch No.: ",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                              Text('${prod.batchNumber}',
                                  style: TextStyle(color: Colors.black)),
                              SizedBox(width: 5),
                              Text("MRP: ",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                              Text('\u20B9 ${prod.mrp}',
                                  style: TextStyle(color: Colors.black)),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Text("Qty: ",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                              Text('${prod.qty}',
                                  style: TextStyle(color: Colors.black)),
                              SizedBox(width: 5),
                              Text("Deal: ",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                              Text('${prod.deal1}+${prod.deal2}',
                                  style: TextStyle(color: Colors.black))
                            ],
                          ),
                        ]),
                        trailing: Container(
                            child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Column(children: <Widget>[
                                  Text("Date",
                                      style: TextStyle(color: Colors.black)),
                                  Text(
                                      '${docu.date.toDate().day}/${docu.date.toDate().month}/${docu.date.toDate().year}',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 20)),
                                ])))),
                  ),
                )

                // Divider(height: 1.0,)
              ],
            );
          },
        ));
  }
}
