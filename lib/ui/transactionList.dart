import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:startup_namer/model.dart';
import 'package:startup_namer/ui/allProduct.dart';
import 'package:startup_namer/ui/party.dart';
import './expirySentProduct.dart';

class ExpiryList extends StatefulWidget {
  final PartyData data;
  ExpiryList(this.data);
  @override
  _ExpiryListState createState() => _ExpiryListState();
}

class _ExpiryListState extends State<ExpiryList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
        title: new Text(
          "Transaction History",
          style: TextStyle(
              color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
              padding: EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Icon(
                  Icons.add,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AllProductPage(
                            data: widget.data, docID: "", check: false)),
                  );
                },
              )),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton(
                // initialValue: 1,
                onSelected: (int) {
                  //Navigator.push(context, MaterialPageRoute(builder: (context) => ProductForm(widget.data.name)));
                },
                itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 1,
                        child: Center(child: Text("Reports")),
                      )
                    ]),
          ),
        ],
        //backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("Expiry")
            .where('partyName', isEqualTo: widget.data.name)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot prodList = snapshot.data.docs[index];
                DateTime test = prodList['timestamp'].toDate();
                String day = test.day.toString();
                print(day);
                String month = test.month.toString();
                String year = test.year.toString();
                return Column(children: <Widget>[
                  Card(
                    elevation: 12.0,
                    margin: new EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 6.0),
                    child: Container(
                      decoration:
                          BoxDecoration(color: Color.fromRGBO(64, 75, 96, .9)),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 10.0),
                        leading: Container(
                          padding: EdgeInsets.only(right: 8.0),
                          decoration: new BoxDecoration(
                              border: new Border(
                                  right: new BorderSide(
                                      width: 1.0, color: Colors.white24))),
                          child: IconButton(
                            icon: prodList['isSettled']
                                ? Icon(Icons.check,
                                    color: Colors.green, size: 40)
                                : Icon(Icons.clear,
                                    color: Colors.red, size: 40),
                            onPressed: () {
                              return showDialog(
                                  context: context,
                                  builder: (context) {
                                    TextEditingController _invoice =
                                        TextEditingController();
                                    bool _validate = false;
                                    String invoice;
                                    return AlertDialog(
                                      title: Text("Settle Amount"),
                                      content: TextField(
                                        autofocus: true,
                                        keyboardType: TextInputType.text,
                                        controller: _invoice,
                                        decoration: new InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 15, horizontal: 20),
                                          labelText: "Invoice Number",
                                          errorText:
                                              _validate ? "*Required" : null,
                                          fillColor: Colors.black,
                                          border: new OutlineInputBorder(
                                            borderRadius:
                                                new BorderRadius.circular(15.0),
                                            borderSide: new BorderSide(),
                                          ),
                                        ),
                                        onChanged: (text) {
                                          invoice = _invoice.text;
                                        },
                                        onSubmitted: (text) {
                                          if (_invoice.text == "") {
                                            setState(() {
                                              _validate = true;
                                            });
                                          }
                                          FirebaseFirestore.instance
                                              .collection('Expiry')
                                              .doc(prodList.id)
                                              .set({
                                            "invoiceNumber": invoice,
                                            "isSettled": true,
                                            "partyName": prodList['partyName'],
                                            "timestamp": prodList['timestamp'],
                                            "amount": prodList['amount']
                                          });
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text("Close"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        )
                                      ],
                                    );
                                  });
                            },
                          ),
                        ),
                        title: Text(
                          '${prodList['partyName']}',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                        // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

                        subtitle: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text("Date: ",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                                Text(day + "/" + month + "/" + year,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16))
                              ],
                            ),
                            (prodList['isSettled'])
                                ? Row(
                                    children: <Widget>[
                                      Text("Invoice Number: ",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16)),
                                      Flexible(
                                          child: Container(
                                              child: Text(
                                                  '${prodList['invoiceNumber']}',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16))))
                                    ],
                                  )
                                : Container(
                                    height: 0,
                                    width: 0,
                                  ),
                            Row(
                              children: <Widget>[
                                Text("Amount: ",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                                Text(
                                    '\u20B9 ' +
                                        prodList['amount'].toStringAsFixed(2),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16))
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.keyboard_arrow_right,
                              color: Colors.white, size: 30.0),
                          onPressed: () {
                            PartyData data = PartyData(
                                name: prodList['partyName'],
                                defaultDiscount: widget.data.defaultDiscount);
                            (prodList['isSettled'])
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ExpirySentProductList(
                                                prodList.id,
                                                prodList['partyName'],
                                                widget.data.defaultDiscount,
                                                prodList['amount'],
                                                prodList['timestamp'])))
                                : Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => AllProductPage(
                                            data: data,
                                            docID: prodList.id,
                                            check: true,
                                            invoiceDate: prodList['timestamp'],
                                            invoiceAmount:
                                                prodList['amount'])));
                          },
                        ),
                      ),
                    ),
                  )
                ]);
              },
            );
          }
        },
      ),
    );
  }
}
