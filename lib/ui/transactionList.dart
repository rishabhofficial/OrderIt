import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:startup_namer/model.dart';
import 'package:startup_namer/ui/allProductNew.dart';

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
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        elevation: 0,
        title: Text(
          "Transaction History",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AllProductPageNew(
                        data: widget.data, docID: "", check: false)),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'Reports') {
                // TODO: Implement reports functionality
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Reports',
                  child: Row(
                    children: [
                      Icon(Icons.assessment, color: Color(0xFF3498DB)),
                      SizedBox(width: 8),
                      Text('Reports'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C3E50),
              Color(0xFFF5F7FA),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("Expiry")
              .where('partyName', isEqualTo: widget.data.name)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error loading transactions',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2C3E50)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading transactions...',
                      style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.data.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the + button to create your first transaction',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot prodList = snapshot.data.docs[index];
                  DateTime test = prodList['timestamp'].toDate();
                  String day = test.day.toString();
                  print(day);
                  String month = test.month.toString();
                  String year = test.year.toString();
                  return _buildTransactionCard(
                      context, prodList, day, month, year);
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, DocumentSnapshot prodList,
      String day, String month, String year) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 6,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34495E),
                Color(0xFF2C3E50),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                PartyData data = PartyData(
                    name: prodList['partyName'],
                    defaultDiscount: widget.data.defaultDiscount,
                    partyCode: widget.data.partyCode);
                (prodList['isSettled'])
                    ? Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ExpirySentProductList(
                                prodList.id,
                                prodList['partyName'],
                                widget.data.defaultDiscount,
                                prodList['amount'],
                                prodList['timestamp'])))
                    : Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AllProductPageNew(
                                data: data,
                                docID: prodList.id,
                                check: true,
                                invoiceDate: prodList['timestamp'],
                                invoiceAmount: prodList['amount'])));
              },
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: prodList['isSettled']
                                ? Color(0xFF27AE60)
                                : Color(0xFFE74C3C),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: (prodList['isSettled']
                                        ? Color(0xFF27AE60)
                                        : Color(0xFFE74C3C))
                                    .withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            prodList['isSettled'] ? Icons.check : Icons.pending,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prodList['partyName'] ?? 'Unknown Party',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: Colors.grey[300], size: 12),
                                  SizedBox(width: 3),
                                  Text(
                                    day + "/" + month + "/" + year,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.more_vert,
                              color: Colors.white, size: 20),
                          onPressed: () {
                            _showSettleDialog(context, prodList);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Amount: ',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '\u20B9 ' + prodList['amount'].toStringAsFixed(2),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (prodList['isSettled']) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Invoice: ',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                prodList['invoiceNumber'] ?? 'No invoice',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSettleDialog(BuildContext context, DocumentSnapshot prodList) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _invoice =
            TextEditingController(text: prodList['invoiceNumber']);
        bool _validate = false;
        String invoice;
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.payment, color: Color(0xFF2C3E50)),
              SizedBox(width: 8),
              Text(
                "Settle Amount",
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.text,
            controller: _invoice,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              labelText: "Invoice Number",
              errorText: _validate ? "*Required" : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF2C3E50)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFF3498DB), width: 2),
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
              } else {
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
              }
            },
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF3498DB),
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Settle"),
              onPressed: () {
                if (_invoice.text == "") {
                  setState(() {
                    _validate = true;
                  });
                } else {
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
                }
              },
            ),
          ],
        );
      },
    );
  }
}
