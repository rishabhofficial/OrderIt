import 'package:flutter/material.dart';
import 'dart:io';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class Test extends StatelessWidget {

  sptest(){
     var file = "lib/ui/test.xlsx";
  var bytes = new File(file).readAsBytesSync();
  var decoder = new SpreadsheetDecoder.decodeBytes(bytes, update: true);
  for (var table in decoder.tables.keys) {
    print(table);
    print(decoder.tables[table].maxCols);
    print(decoder.tables[table].maxRows);
    for (var row in decoder.tables[table].rows) {
      print("$row");
    }
  }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new Center(
        child: RaisedButton(onPressed: () { sptest();},),
      )
    );
  }
}