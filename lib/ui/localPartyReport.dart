import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:startup_namer/model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:loading_animations/loading_animations.dart';

class LocalPartyReport extends StatefulWidget {
  final String partyName;
  final String docID;
  final double defaultDisc;
  final Timestamp invoiceDate;
  final double invoiceAmount;
  LocalPartyReport(
      {this.partyName,
      this.docID,
      this.defaultDisc,
      this.invoiceDate,
      this.invoiceAmount});

  static void openFile(List<int> bytes, String name) async {
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/" + name + ".pdf");
    await file.writeAsBytes(bytes);
    OpenFile.open(file.path);
  }

  @override
  _LocalPartyReportState createState() => _LocalPartyReportState();
}

class _LocalPartyReportState extends State<LocalPartyReport>
    with SingleTickerProviderStateMixin {
  Map<String, ProductData> m = Map();

  double finalAmount = 0;

  firestore() {
    FirebaseFirestore.instance
        .collection('Expiry')
        .doc(widget.docID)
        .collection(widget.partyName)
        .snapshots()
        .listen((cour) => cour.docs.forEach((doc) {
              print("Insde firestore");
              ProductData prod = ProductData();
              prod.qty = int.parse(doc.data()['prodQty']).toString();
              prod.name = doc.data()['prodName'];
              prod.pack = doc.data()['prodPack'];
              prod.mrp = doc.data()['prodMrp'];
              prod.deal1 = doc.data()['prodDeal1'];
              prod.deal2 = doc.data()['prodDeal2'];
              prod.batchNumber = doc.data()['prodBatchNumber'];
              prod.expiryDate = doc.data()['prodExpiryDate'];
              //  prod.batchNumber = doc.data()['prodBatchNumber'];
              // (prod.deal1 != 0 && prod.deal2 != 0)?
              //   mrpValue += int.parse(doc.data()['prodQty']) * doc.data()['prodMrp']* (1 - (prod.deal2)/(prod.deal1 + prod.deal2)):
              //   mrpValue += int.parse(doc.data()['prodQty']) * doc.data()['prodMrp'];
              m[doc.id] = prod;
            }));
  }

  fillData() async {
    print("Insde fill data");

    await firestore();
    new Future.delayed(new Duration(seconds: 6), () {
      //discount = mrpValue*0.01*widget.defaultDisc;
      finalAmount = widget.invoiceAmount;
      print("Final amount -------------->> " + finalAmount.toString());
      pdfGenerator(m);
      Navigator.pop(context);
    });

    print(m);
  }

  pdfGenerator(dynamic m) async {
    print("Insde pdf");
    final doc = pw.Document();
    List<List<String>> trial = List();
    var element =
        (["S.No.", "Product", "Pack", "QTY", "Expiry Dt.", "Deal", "MRP"]);
    int a = 0;

    m.forEach((k, v) {
      trial.add([
        v.name,
        v.pack.toString(),
        v.batchNumber,
        v.expiryDate,
        v.qty.toString(),
        v.deal1.toString() + " + " + v.deal2.toString(),
        v.mrp.toString()
      ]);
      a++;
    });
    trial.sort((a, b) => a[0].compareTo(b[0]));
    a = 1;
    for (int i = 0; i < trial.length; i++) {
      trial[i].insert(0, a.toString());
      a++;
    }
    //trial.insert(0, element);
    print(trial);
    const tableHeaders = [
      "S.No.",
      "Product",
      "Pack",
      "Batch No.",
      "Expiry Dt.",
      "QTY",
      "Deal",
      "MRP"
    ];

    doc.addPage(pw.MultiPage(
        header: _buildHeader,
        footer: _buildFooter,
        build: (pw.Context context) => [
              pw.Table.fromTextArray(
                context: context,
                data: trial,
                cellAlignment: pw.Alignment.topLeft,
                headers: List<String>.generate(
                  tableHeaders.length,
                  (col) => tableHeaders[col],
                ),
              ),
              pw.SizedBox(height: 20),
              _contentFooter(context),
              // pw.Container(
              //   child:pw.Column(
              //     children: <pw.Widget>[
              //       pw.Row(children: <pw.Widget>[
              //         pw.Text("Bill Value: ", textAlign: pw.TextAlign.right),
              //         pw.Text(mrpValue.toString(), textAlign: pw.TextAlign.right)
              //       ]),
              //       pw.Row(children: <pw.Widget>[
              //         pw.Text("Discount:  ", textAlign: pw.TextAlign.right),
              //         pw.Text(discount.toString(), textAlign: pw.TextAlign.right)
              //       ]),
              //       pw.Row(children: <pw.Widget>[
              //         pw.Text("Amount:   ", textAlign: pw.TextAlign.right),
              //         pw.Text(finalAmount.toString(), textAlign: pw.TextAlign.right)
              //       ]),
              //     ]
              //   )
              // )
            ]));

    final pdfBytes = List.from(await doc.save());
    if (pdfBytes.length > 0) {
      LocalPartyReport.openFile(pdfBytes.cast<int>(), widget.partyName);
    }
  }

  init() {
    fillData();
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  static const baseColor = PdfColors.teal;
  static const accentColor = PdfColors.blueGrey900;
  static const _darkColor = PdfColors.blueGrey800;

  pw.Widget _contentFooter(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '',
                style: pw.TextStyle(
                  color: _darkColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 20, bottom: 8),
                child: pw.Text(
                  "",
                  style: pw.TextStyle(
                    color: baseColor,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          flex: 1,
          child: pw.DefaultTextStyle(
            style: const pw.TextStyle(
              fontSize: 10,
              //color: _darkColor,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // pw.Row(
                //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                //   children: [
                //     pw.Text('MRP Value:'),
                //     pw.Text(_formatCurrency(mrpValue).toString()),
                //   ],
                // ),
                // pw.SizedBox(height: 5),
                // pw.Row(
                //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                //   children: [
                //     pw.Text('Discount:'),
                //     pw.Text(_formatCurrency(discount).toString()),
                //   ],
                // ),
                // pw.Divider(color: accentColor),
                pw.DefaultTextStyle(
                  style: pw.TextStyle(
                    color: baseColor,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Amount:'),
                      pw.Text(_formatCurrency(finalAmount).toString()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(children: <pw.Widget>[
      pw.Container(
          decoration: new pw.BoxDecoration(
              border: new pw.Border(
                  left: pw.BorderSide(width: 1.0, style: pw.BorderStyle.solid),
                  right: pw.BorderSide(width: 1.0, style: pw.BorderStyle.solid),
                  top: pw.BorderSide(width: 1.0, style: pw.BorderStyle.solid),
                  bottom:
                      pw.BorderSide(width: 1.0, style: pw.BorderStyle.solid))),
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
                      pw.Text("DL No:- UP4320B000615/UP4321B000615",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.normal,
                              fontSize: 8)),
                      pw.Container(height: 5),

                      //pw.Text("CLAIM NO. - MP/"+ DateTime.now().month.toString() + "/"+ DateTime.now().year.toString() + "/"+ code, textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(
                          "DT - " +
                              widget.invoiceDate.toDate().day.toString() +
                              "/" +
                              widget.invoiceDate.toDate().month.toString() +
                              "/" +
                              widget.invoiceDate.toDate().year.toString(),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              font: pw.Font.times(),
                              fontWeight: pw.FontWeight.normal,
                              fontSize: 10))
                    ])),
            pw.Expanded(
                child: pw.Container(
              padding: pw.EdgeInsets.only(right: 8, top: 8, bottom: 8),
              decoration: pw.BoxDecoration(border: pw.Border()),
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
                        child: pw.Text("  M/S " + widget.partyName,
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                font: pw.Font.times(),
                                fontWeight: pw.FontWeight.normal,
                                fontSize: 13)),
                        padding: pw.EdgeInsets.only(left: 12)),
                    // pw.Padding(padding: pw.EdgeInsets.only(left:12),
                    //   child: pw.Text("  "+location, textAlign: pw.TextAlign.right  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 13))
                    // ),
                    //  pw.Padding(padding: pw.EdgeInsets.only(left:12),
                    //   child: pw.Text("  DT - " + DateTime.now().day.toString() + "/" + DateTime.now().month.toString() + "/" + DateTime.now().year.toString(), textAlign: pw.TextAlign.right  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 10))
                    // )
                  ]),
            ))
          ])),
      pw.Padding(
          padding: pw.EdgeInsets.only(top: 14, bottom: 8),
          child: pw.Text("EXPIRY/BREAKAGE GOODS",
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                  font: pw.Font.times())))
    ]);
  }

  pw.Widget _buildHeader1(pw.Context context) {
    return
        // pw.Container(
        //       height: 70,
        //       padding: const pw.EdgeInsets.only(left: 20),
        //       alignment: pw.Alignment.center,
        //       child:
        pw.Row(children: <pw.Widget>[
      pw.Text(
        'MAHESH PHARMA',
        style: pw.TextStyle(
          color: baseColor,
          fontWeight: pw.FontWeight.bold,
          fontSize: 30,
        ),
      ),
      pw.Text(
        widget.partyName,
        style: pw.TextStyle(
          color: PdfColors.black,
          fontWeight: pw.FontWeight.normal,
          fontSize: 16,
        ),
      ),
    ]);
    //     );
    // pw.SizedBox(height: 20)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: LoadingBouncingGrid.square(
        size: 50,
        backgroundColor: Colors.blue,
      )),
    );
  }
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
          color: PdfColors.grey,
        ),
      ),
    ],
  );
}

String _formatCurrency(double amount) {
  return '${amount.toStringAsFixed(2)}';
}
