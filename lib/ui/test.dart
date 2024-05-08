import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Test extends StatelessWidget {
  fillData() {
    // TimeStamp varible for 2023 start
    Timestamp ts = Timestamp.fromDate(DateTime(2023, 1, 1));

    FirebaseFirestore.instance
        .collection('Expiry')
        .where('timestamp', isLessThanOrEqualTo: ts)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((result) {
        // delete the document with nested colle
        result.reference.delete();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: ElevatedButton(
          child: Text('sdvfdbfd'),
          onPressed: () {
            var x = fillData();
            new Future.delayed(new Duration(seconds: 5), () {
              Navigator.of(context).pop();
              print(x);
            });
          }),
    ));
  }
}
