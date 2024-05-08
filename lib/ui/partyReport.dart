import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:startup_namer/model.dart';

int claim;

String address = "";
String location = "";
String code = "";
String loaderText = "Loading...";

List<dynamic> compDivision = [];
List<ExpiryProductData> partyWiseList = [];

class PartyReport extends StatefulWidget {
  @override
  _PartyReportState createState() => _PartyReportState();
}

class _PartyReportState extends State<PartyReport> {
  double mrpValue = 0.0;
  List<String> _companies = [];
  @override
  void initState() {
    if (_companies.length <= 0) {
      populateComp().then((value) {
        setState(() {
          _companies = value;
        });
      });
    }

    setState(() {
      mrpValue = 0.0;
      batch.clear();
    });
    super.initState();
  }

  Future<List<String>> populateComp() async {
    List<String> compList = [];
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection("Company")
        .orderBy('compName')
        .get();

    snapshot.docs.forEach((element) {
      if (!compList.contains(element.data()['compName'])) {
        compList.add(element.data()['compName']);
      }
    });

    return compList;
  }

  List<String> batch = [];
  static void openFile(List<int> bytes) async {
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/" + code + ".pdf");
    await file.writeAsBytes(bytes);
    OpenFile.open(file.path);
  }

  Future<Map<String, List<ProductData>>> fillData(DateTime date) async {
    setState(() {
      loaderText = "Collecting Data...";
    });

    mrpValue = 0.0;
    batch.clear();

    Map<String, List<ProductData>> m = {};

    String comp = currentCompany;
    Timestamp timestamp2 = Timestamp.fromDate(timestamp1);

    QuerySnapshot expirySnapshot = await FirebaseFirestore.instance
        .collection('Expiry')
        .where('timestamp',
            isGreaterThan: timestamp2) // Add timestamp condition here
        .get();

    for (DocumentSnapshot expiryDoc in expirySnapshot.docs) {
      QuerySnapshot courSnapshot;

      if (comp == "MANKIND" || comp == "ARISTO") {
        courSnapshot = await FirebaseFirestore.instance
            .collection('Expiry')
            .doc(expiryDoc.id)
            .collection(expiryDoc['partyName'])
            .where('compCode', isGreaterThan: comp)
            .get();
      } else {
        courSnapshot = await FirebaseFirestore.instance
            .collection('Expiry')
            .doc(expiryDoc.id)
            .collection(expiryDoc['partyName'])
            .where('compCode', isEqualTo: comp)
            .get();
      }

      for (DocumentSnapshot doc in courSnapshot.docs) {
        ProductData prod = ProductData();
        ExpiryProductData product = ExpiryProductData();
        prod.qty = int.parse(doc['prodQty']).toString();
        prod.name = doc['prodName'];
        prod.pack = doc['prodPack'];
        prod.mrp = doc['prodMrp'];
        prod.expiryDate = doc['prodExpiryDate'];
        prod.batchNumber = doc['prodBatchNumber'];
        prod.compCode = doc['compCode'];
        if (doc['compCode'] == "MANKIND-M") {
          prod.compCode = "MANKIND-MAIN";
        }

        product.qty = int.parse(doc['prodQty']).toString();
        product.name = doc['prodName'];
        product.pack = doc['prodPack'];
        product.mrp = doc['prodMrp'];
        product.expiryDate = doc['prodExpiryDate'];
        product.batchNumber = doc['prodBatchNumber'];
        product.compCode = prod.compCode;
        product.partyName = expiryDoc['partyName'];
        product.colDocId = expiryDoc.id;
        product.docId = doc.id;
        partyWiseList.add(product);
        mrpValue += double.parse(prod.qty) * prod.mrp;

        bool test = false;
        if (m.containsKey(doc['prodName'])) {
          for (int i = 0; i < m[prod.name].length; i++) {
            if (m[prod.name][i].batchNumber == prod.batchNumber) {
              m[prod.name][i].qty =
                  (int.parse(m[prod.name][i].qty) + int.parse(prod.qty))
                      .toString();
              test = true;
              break;
            }
          }
          if (!test) {
            m[prod.name].add(prod);
          }
        } else {
          batch.add(prod.name);
          m[prod.name] = [prod];
        }
      }
    }
    return m;
  }

  pdfGeneratorDivWise(dynamic m) async {
    setState(() {
      loaderText = "Generating Pdf...";
    });

    final pw.Document doc = pw.Document();

    Map<String, double> divisionMRP = Map();
    Map<String, List<List<String>>> divisionProductMap = Map();

    var element =
        (["S.No.", "Product", "Pack", "QTY", "MRP", "E/D", "Batch No."]);

    for (int i = 0; i < m.length; i++) {
      for (int j = 0; j < m[batch[i]].length; j++) {
        if (divisionProductMap.containsKey(m[batch[i]][j].compCode)) {
          divisionProductMap[m[batch[i]][j].compCode].add([
            (divisionProductMap[m[batch[i]][j].compCode].length + 1).toString(),
            m[batch[i]][j].name,
            m[batch[i]][j].pack,
            m[batch[i]][j].qty,
            m[batch[i]][j].mrp.toString(),
            m[batch[i]][j].expiryDate,
            m[batch[i]][j].batchNumber
          ]);
        } else {
          divisionProductMap[m[batch[i]][j].compCode] = [];
          divisionProductMap[m[batch[i]][j].compCode].add([
            (1).toString(),
            m[batch[i]][j].name,
            m[batch[i]][j].pack,
            m[batch[i]][j].qty,
            m[batch[i]][j].mrp.toString(),
            m[batch[i]][j].expiryDate,
            m[batch[i]][j].batchNumber
          ]);
        }
      }
    }

    print(divisionProductMap);

    // calculate mrpValue division wise using compDivision
    compDivision.forEach((element) {
      if (divisionProductMap.containsKey(element)) {
        divisionMRP[element] = 0.0;
        divisionProductMap[element].forEach((value) {
          divisionMRP[element] +=
              double.parse(value[3]) * double.parse(value[4]);
        });
      }
    });

    // for each key sort the list after removing the first element and after sorting insert the first elemet at the first place
    divisionProductMap.forEach((key, value) {
      value.sort((a, b) => a[1].compareTo(b[1]));
      value.insert(0, element);
    });

    doc.addPage(pw.MultiPage(
        header: _buildHeader,
        footer: _buildFooter,
        build: (pw.Context context) => [
              pw.Wrap(
                  children: List.generate(compDivision.length, (index) {
                return (divisionProductMap.containsKey(compDivision[index]))
                    ? pw.Column(children: <pw.Widget>[
                        pw.Padding(
                            child: pw.Text(compDivision[index]),
                            padding: pw.EdgeInsets.only(top: 12, bottom: 12)),
                        pw.Table.fromTextArray(
                            context: context,
                            data: divisionProductMap[compDivision[index]],
                            cellAlignment: pw.Alignment.topLeft),
                        pw.Padding(
                          padding: pw.EdgeInsets.only(top: 10, right: 20),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              pw.Text(
                                "Total MRP Value(Rupees): " +
                                    divisionMRP[compDivision[index]]
                                        .toStringAsFixed(2),
                              ),
                            ],
                          ),
                        ),
                      ])
                    : pw.Container(width: 0, height: 0);
              })),
            ]));

    final pdfBytes = List.from(await doc.save());
    if (pdfBytes.length > 0) {
      openFile(pdfBytes.cast<int>());
    }
  }

  pdfGenerator(dynamic m) async {
    setState(() {
      loaderText = "Generating Pdf...";
    });

    final doc = pw.Document();
    //print(batch);
    List<List<String>> trial = [];

    var element =
        (["S.No.", "Product", "Pack", "QTY", "MRP", "E/D", "Batch No."]);
    int a = 0;

    for (int i = 0; i < m.length; i++) {
      for (int j = 0; j < m[batch[i]].length; j++) {
        trial.add([
          m[batch[i]][j].name,
          m[batch[i]][j].pack,
          m[batch[i]][j].qty,
          m[batch[i]][j].mrp.toString(),
          m[batch[i]][j].expiryDate,
          m[batch[i]][j].batchNumber
        ]);
      }
    }
    trial.sort((a, b) => a[0].compareTo(b[0]));
    a = 1;
    for (int i = 0; i < trial.length; i++) {
      trial[i].insert(0, a.toString());
      a++;
    }
    trial.insert(0, element);

    doc.addPage(pw.MultiPage(
        header: _buildHeader,
        footer: _buildFooter,
        build: (pw.Context context) => [
              pw.Table.fromTextArray(
                  context: context,
                  data: trial,
                  cellAlignment: pw.Alignment.topLeft),
              pw.Padding(
                  padding: pw.EdgeInsets.only(top: 10),
                  child: pw.Text("Total MRP Value(Rupees): " +
                      mrpValue.toStringAsFixed(2)))
            ]));

    final pdfBytes = List.from(await doc.save());
    if (pdfBytes.length > 0) {
      openFile(pdfBytes.cast<int>());
    }
  }

  Future<void> _populateCompDetails(String comp) async {
    compDivision.clear();

    if (comp.contains("MANKIND")) {
      currentCompany = "MANKIND";

      _companies.forEach((value) {
        if (value.contains("MANKIND")) {
          compDivision.add(value);
        }
      });
    }

    if (comp.contains("ARISTO")) {
      currentCompany = "ARISTO";
      _companies.forEach((value) {
        if (value.contains("ARISTO")) {
          compDivision.add(value);
        }
      });
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("Company")
        .where('compName', isEqualTo: comp)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final DocumentSnapshot doc = snapshot.docs.first;
      address = doc['compMailingName'] ?? "";
      location = doc['compMailingLocation'] ?? "";
      code = doc['compCode'] ?? "";
    }
  }

  String currentCompany = "ABT INDIA";
  String visualValue = "ABT INDIA";

  final _sKey = GlobalKey<ScaffoldMessengerState>();
  DateTime timestamp1;
  DateTime timestamp2 = DateTime.now();
  final format = DateFormat("yyyy-MM-dd");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _sKey,
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
        leading: new IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            }),
        title: new Text(
          "Expiry Report",
          style: TextStyle(
              color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        width: 500,
        decoration: BoxDecoration(color: Colors.grey[100]),
        child: new Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 60, left: 60, right: 60, bottom: 5),
              child: DropdownButton(
                isExpanded: true,
                style: TextStyle(fontSize: 16, color: Colors.black),
                icon: Icon(Icons.business),
                hint: Text("Select Company"),
                value: visualValue,
                onChanged: (newValue) {
                  setState(() {
                    currentCompany = newValue;
                    visualValue = newValue;
                  });
                },
                items: _companies.map((comp) {
                  return DropdownMenuItem(
                    child: new Text(comp),
                    value: comp,
                  );
                }).toList(),
              ),
            ),
            Padding(
                padding: EdgeInsets.only(
                  left: 60,
                  right: 50,
                ),
                child: DateTimeField(
                  format: format,
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today),
                    labelText: "Starting Date",
                  ),
                  onShowPicker: (context, currentValue) {
                    return showDatePicker(
                        context: context,
                        firstDate: DateTime(2015),
                        fieldLabelText: "Starting Date",
                        initialDate: currentValue ?? DateTime.now(),
                        lastDate: DateTime(2100));
                  },
                  onChanged: (newValue) {
                    timestamp1 = newValue;
                  },
                )),
            Padding(
                padding: EdgeInsets.only(left: 60, right: 50, bottom: 30),
                child: DateTimeField(
                  format: format,
                  decoration: InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today),
                    labelText: "Invoice Date",
                  ),
                  onShowPicker: (context, currentValue) {
                    return showDatePicker(
                        context: context,
                        firstDate: DateTime(2017),
                        fieldLabelText: "Invoice Date",
                        initialDate: currentValue ?? DateTime.now(),
                        lastDate: DateTime(2100));
                  },
                  onChanged: (newValue) {
                    timestamp2 = newValue;
                  },
                )),
            Padding(
              padding: const EdgeInsets.only(left: 290),
              child: ClipOval(
                child: Material(
                  color: Colors.grey, // button color
                  child: InkWell(
                    splashColor: Colors.black, // inkwell color
                    child: SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        )),
                    onTap: () async {
                      try {
                        final result =
                            await InternetAddress.lookup('google.com');
                        if (result.isNotEmpty &&
                            result[0].rawAddress.isNotEmpty) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return Dialog(
                                child: new Container(
                                    height: 75,
                                    child: Row(
                                      children: [
                                        new Padding(
                                          padding: EdgeInsets.only(left: 18),
                                          child: CircularProgressIndicator(),
                                        ),
                                        new Padding(
                                          padding: EdgeInsets.all(14),
                                          child: Text(
                                            loaderText,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        )
                                      ],
                                    )),
                              );
                            },
                          );
                          print("Before populate Comp details");
                          //divi.clear();
                          _populateCompDetails(currentCompany);
                          print("After populate Comp details");
                          //print(company);
                          fillData(DateTime.now()).then((x) {
                            Navigator.of(context).pop();
                            print("Inside Future" + x.length.toString());
                            if (x.length == 0) {
                              final snackbar =
                                  SnackBar(content: Text("No Data Found"));
                              _sKey.currentState.showSnackBar(snackbar);
                            } else
                              (currentCompany == "MANKIND" ||
                                      currentCompany == "ARISTO")
                                  ? pdfGeneratorDivWise(x)
                                  : pdfGenerator(x);
                          });
                        }
                      } on SocketException catch (_) {
                        final snackbar = SnackBar(
                            content:
                                Text("Please check your internet connection"));
                        _sKey.currentState.showSnackBar(snackbar);
                      }
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(children: <pw.Widget>[
      pw.Container(
          decoration: new pw.BoxDecoration(border: new pw.Border()),
          width: double.infinity,
          child: pw.Row(children: <pw.Widget>[
            pw.Container(
                padding: pw.EdgeInsets.all(12.0),
                decoration: new pw.BoxDecoration(
                    border: new pw.Border(
                        right: pw.BorderSide(
                            width: 1.0, style: pw.BorderStyle.solid))),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Text("MAHESH PHARMA",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14)),
                      //pw.Text("STATION ROAD", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 8)),
                      pw.Text("GONDA (U.P.)",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.normal,
                              fontSize: 10)),
                      pw.Text("GST No:- 09ACTPA5656M1ZX",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.normal,
                              fontSize: 8)),
                      pw.Text("DL No:- UP4320B000762/UP4321B000761",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.normal,
                              fontSize: 8)),
                      pw.Container(height: 5),

                      pw.Text(
                          "CLAIM NO. - MP/" +
                              DateTime.now().month.toString() +
                              "/" +
                              DateTime.now().year.toString() +
                              "/" +
                              code,
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10)),
                      pw.Text(
                          "DT - " +
                              timestamp2.day.toString() +
                              "/" +
                              timestamp2.month.toString() +
                              "/" +
                              timestamp2.year.toString(),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.normal,
                              fontSize: 10))
                    ])),
            pw.Expanded(
                child: pw.Container(
              padding: pw.EdgeInsets.only(right: 8, top: 8, bottom: 8),
              decoration: pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(
                          width: 1.0, style: pw.BorderStyle.solid))),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Padding(
                        padding: pw.EdgeInsets.only(left: 10),
                        child: pw.Text("To,",
                            textAlign: pw.TextAlign.left,
                            style: pw.TextStyle(
                                font: pw.Font.times(),
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14))),
                    pw.Padding(
                        child: pw.Text("  M/S " + address,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                font: pw.Font.times(),
                                fontWeight: pw.FontWeight.normal,
                                fontSize: 13)),
                        padding: pw.EdgeInsets.only(left: 12)),
                    pw.Padding(
                        padding: pw.EdgeInsets.only(left: 12),
                        child: pw.Text("  " + location,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                font: pw.Font.times(),
                                fontWeight: pw.FontWeight.normal,
                                fontSize: 13))),
                  ]),
            ))
          ])),
      pw.Padding(
          padding: pw.EdgeInsets.only(top: 14, bottom: 8),
          child: pw.Text("Expired/Breakage Goods Report",
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 16,
                  font: pw.Font.times())))
    ]);
  }
}

// ignore: unused_element
pw.Widget _buildHeader1(pw.Context context) {
  return pw.Column(
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Container(
                    height: 50,
                    padding: const pw.EdgeInsets.only(left: 20),
                    alignment: pw.Alignment.topLeft,
                    child: pw.Column(children: <pw.Widget>[
                      pw.Text("MAHESH PHARMA",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14)),
                      pw.Text("STATION ROAD",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.normal,
                              fontSize: 8)),
                      pw.Text("GONDA (U.P.)-271002 ",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.normal,
                              fontSize: 8)),
                      pw.Text("GST No:- 09ACTPA5656M1ZX",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.normal,
                              fontSize: 8)),
                      pw.Text("DL No:- UP4320B000615/UP4321B000615",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.normal,
                              fontSize: 8)),
                    ])),
                pw.Container(
                  color: PdfColors.black,
                  alignment: pw.Alignment.centerLeft,
                  height: 50,
                  child: pw.DefaultTextStyle(
                    style: pw.TextStyle(
                      fontSize: 12,
                    ),
                    child: pw.GridView(
                      crossAxisCount: 2,
                      children: [
                        pw.Text('Claim No. '),
                        pw.Text(claim.toString()),
                        pw.Text('Date: '),
                        pw.Text(DateTime.now().day.toString() +
                            "/" +
                            DateTime.now().month.toString() +
                            "/" +
                            DateTime.now().year.toString()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.max,
              children: [
                pw.Container(
                  alignment: pw.Alignment.topLeft,
                  padding: const pw.EdgeInsets.only(bottom: 8, left: 10),
                  height: 72,
                  child: pw.Column(children: <pw.Widget>[
                    pw.Padding(
                        padding: pw.EdgeInsets.only(right: 50),
                        child: pw.Text("To,",
                            textAlign: pw.TextAlign.left,
                            style: pw.TextStyle(
                                font: pw.Font.times(),
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14))),
                    pw.Padding(
                        child: pw.Text("M/S " + address,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                font: pw.Font.times(),
                                fontWeight: pw.FontWeight.normal,
                                fontSize: 12)),
                        padding: pw.EdgeInsets.only(right: 12)),
                    pw.Padding(
                        padding: pw.EdgeInsets.only(right: 12),
                        child: pw.Text(location,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                font: pw.Font.times(),
                                fontWeight: pw.FontWeight.normal,
                                fontSize: 12))),
                  ]),
                ),
                // pw.Container(
                //   color: baseColor,
                //   padding: pw.EdgeInsets.only(top: 3),
                // ),
              ],
            ),
          ),
        ],
      ),
      if (context.pageNumber > 1) pw.SizedBox(height: 20)
    ],
  );
}

pw.Widget _buildFooter(pw.Context context) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Container(
        height: 20,
        width: 100,
      ),
      pw.Text(
        'Page ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(
          fontSize: 12,
          color: PdfColors.black,
        ),
      ),
    ],
  );
}
