import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:startup_namer/globals.dart';

import './contactSelectionDialog.dart';

class SalesReportResults extends StatefulWidget {
  final String company;
  final String division;
  final DateTime startDate;
  final DateTime endDate;

  SalesReportResults({
    this.company,
    this.division,
    this.startDate,
    this.endDate,
  });

  @override
  _SalesReportResultsState createState() => _SalesReportResultsState();
}

class _SalesReportResultsState extends State<SalesReportResults> {
  List<ReportData> salesData = [];
  bool isLoading = true;
  double totalAmount = 0.0;
  int totalQuantity = 0;
  String selectedContactName;
  String selectedContactPhone;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() {
      isLoading = true;
    });

    // Query sales data from Firestore
    await loadSBALCSVForDateRange(widget.startDate, widget.endDate);
    final reportData = getReportData(widget.company);

    print("widget.company: ${widget.company}");
    print("reportData: ${reportData}");

    setState(() {
      salesData = reportData;
      isLoading = false;
    });
  }

  Future<void> _exportToPDF() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Sales Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Report Details
              pw.Text('Company: ${widget.company}'),
              // pw.Text(
              //     'Division: ${widget.division.isEmpty ? 'All' : widget.division}'),
              pw.Text(
                  'Period: ${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}'),
              // pw.Text('Total Amount: ₹${totalAmount.toStringAsFixed(2)}'),
              // pw.Text('Total Quantity: $totalQuantity'),
              pw.SizedBox(height: 20),

              // Table Header
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Date'),
                      pw.Text('Product'),
                      pw.Text('Party'),
                      pw.Text('Quantity'),
                      pw.Text('Amount'),
                    ],
                  ),
                  // Data rows
                  ...salesData.map((sale) => pw.TableRow(
                        children: [
                          pw.Text(
                              DateFormat('dd/MM/yyyy').format(sale.startDate)),
                          pw.Text(sale.name),
                          pw.Text(sale.compCode),
                          pw.Text(sale.remainingStock.toString()),
                          pw.Text('₹${sale.remainingStock.toStringAsFixed(2)}'),
                        ],
                      )),
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await doc.save());
    OpenFile.open(file.path);
  }

  Future<void> _exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Sales Report'];

    // Add headers
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        'Date';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =
        'Product';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value =
        'Party';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value =
        'Quantity';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value =
        'Amount';

    // Add data
    // for (int i = 0; i < salesData.length; i++) {
    //   final sale = salesData[i];
    //   sheet
    //       .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
    //       .value = DateFormat('dd/MM/yyyy').format(sale['date']);
    //   sheet
    //       .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
    //       .value = sale['productName'];
    //   sheet
    //       .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1))
    //       .value = sale['partyName'];
    //   sheet
    //       .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1))
    //       .value = sale['quantity'];
    //   sheet
    //       .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1))
    //       .value = sale['amount'];
    // }

    // final output = await getTemporaryDirectory();
    // final file = File(
    //     '${output.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    // await file.writeAsBytes(excel.encode());
    // OpenFile.open(file.path);
  }

  Future<void> _selectContact() async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ContactSelectionDialog();
      },
    );

    if (result != null) {
      setState(() {
        selectedContactName = result['name'];
        selectedContactPhone = result['phone'];
      });
    }
  }

//  Future<void> _shareViaWhatsApp() async {
  // if (selectedContactPhone.isEmpty) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Please select a contact first'),
  //       backgroundColor: Colors.red,
  //     ),
  //   );
  //   return;
  // }

  // First generate the PDF
  // final doc = pw.Document();
  // doc.addPage(
  //   pw.Page(
  //     pageFormat: PdfPageFormat.a4,
  //     build: (pw.Context context) {
  //       return pw.Column(
  //         crossAxisAlignment: pw.CrossAxisAlignment.start,
  //         children: [
  //           // Header
  //           pw.Header(
  //             level: 0,
  //             child: pw.Text(
  //               'Sales Report',
  //               style: pw.TextStyle(
  //                 fontSize: 24,
  //                 fontWeight: pw.FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //           pw.SizedBox(height: 20),

  //           // Report Details
  //           pw.Text('Company: ${widget.company}'),
  //           pw.Text(
  //               'Division: ${widget.division.isEmpty ? 'All' : widget.division}'),
  //           pw.Text(
  //               'Period: ${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}'),
  //           pw.Text('Total Amount: ₹${totalAmount.toStringAsFixed(2)}'),
  //           pw.Text('Total Quantity: $totalQuantity'),
  //           pw.SizedBox(height: 20),

  // Table Header
  // pw.Table(
  //   border: pw.TableBorder.all(),
  //   children: [
  //     pw.TableRow(
  //       children: [
  //         pw.Text('Date'),
  //         pw.Text('Product'),
  //         pw.Text('Party'),
  //         pw.Text('Quantity'),
  //         pw.Text('Amount'),
  //       ],
  //     ),
  // Data rows
  //     ...salesData.map((sale) => pw.TableRow(
  //           children: [
  //             pw.Text(
  //                 DateFormat('dd/MM/yyyy').format(sale['date'])),
  //             pw.Text(sale['productName']),
  //             pw.Text(sale['partyName']),
  //             pw.Text(sale['quantity'].toString()),
  //             pw.Text('₹${sale['amount'].toStringAsFixed(2)}'),
  //           ],
  //         )),
  //   ],
  // ),
  //   ],
  // );
  // },
  // ),
  //  );

  //   final output = await getTemporaryDirectory();
  //   final file = File(
  //       '${output.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
  //   await file.writeAsBytes(await doc.save());

  //   // Create WhatsApp URL
  //   String phoneNumber = selectedContactPhone.replaceAll(RegExp(r'[^\d]'), '');
  //   if (phoneNumber.startsWith('91')) {
  //     phoneNumber = phoneNumber.substring(2);
  //   }

  //   String whatsappUrl =
  //       'https://wa.me/91$phoneNumber?text=Hi ${selectedContactName}, here is your sales report for ${widget.company}.';

  //   if (await canLaunch(whatsappUrl)) {
  //     await launch(whatsappUrl);
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Could not open WhatsApp'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//       backgroundColor: Color(0xFF2C3E50),
//       appBar: AppBar(
//         backgroundColor: Color(0xFF2C3E50),
//         elevation: 0,
//         title: Text(
//           'Sales Report Results',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontFamily: 'Roboto',
//           ),
//         ),
//         iconTheme: IconThemeData(color: Colors.white),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.contact_phone),
//             onPressed: _selectContact,
//             tooltip: 'Select Contact',
//           ),
//           IconButton(
//             icon: Icon(Icons.whatsapp),
//             onPressed: _shareViaWhatsApp,
//             tooltip: 'Share via WhatsApp',
//           ),
//           IconButton(
//             icon: Icon(Icons.picture_as_pdf),
//             onPressed: _exportToPDF,
//             tooltip: 'Export to PDF',
//           ),
//           IconButton(
//             icon: Icon(Icons.table_chart),
//             onPressed: _exportToExcel,
//             tooltip: 'Export to Excel',
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF2C3E50),
//               Color(0xFF34495E),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Summary Cards
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Card(
//                         elevation: 4.0,
//                         child: Container(
//                           padding: EdgeInsets.all(16.0),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12.0),
//                             gradient: LinearGradient(
//                               colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
//                             ),
//                           ),
//                           child: Column(
//                             children: [
//                               Icon(Icons.attach_money,
//                                   color: Colors.white, size: 32),
//                               SizedBox(height: 8),
//                               Text(
//                                 'Total Amount',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontFamily: 'Roboto',
//                                 ),
//                               ),
//                               Text(
//                                 '₹${totalAmount.toStringAsFixed(2)}',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   fontFamily: 'Roboto',
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 16),
//                     Expanded(
//                       child: Card(
//                         elevation: 4.0,
//                         child: Container(
//                           padding: EdgeInsets.all(16.0),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12.0),
//                             gradient: LinearGradient(
//                               colors: [Color(0xFF3498DB), Color(0xFF5DADE2)],
//                             ),
//                           ),
//                           child: Column(
//                             children: [
//                               Icon(Icons.shopping_cart,
//                                   color: Colors.white, size: 32),
//                               SizedBox(height: 8),
//                               Text(
//                                 'Total Quantity',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontFamily: 'Roboto',
//                                 ),
//                               ),
//                               Text(
//                                 totalQuantity.toString(),
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   fontFamily: 'Roboto',
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 16),

//                 // Report Details
//                 Card(
//                   elevation: 4.0,
//                   child: Container(
//                     padding: EdgeInsets.all(16.0),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12.0),
//                       color: Colors.white,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Report Details',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             fontFamily: 'Roboto',
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text('Company: ${widget.company}'),
//                         Text(
//                             'Division: ${widget.division.isEmpty ? 'All' : widget.division}'),
//                         Text(
//                             'Period: ${DateFormat('dd/MM/yyyy').format(widget.startDate)} - ${DateFormat('dd/MM/yyyy').format(widget.endDate)}'),
//                         Text('Records: ${salesData.length}'),
//                         if (selectedContactName.isNotEmpty) ...[
//                           Divider(),
//                           Text(
//                             'Selected Contact: $selectedContactName',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w600,
//                               color: Color(0xFF27AE60),
//                             ),
//                           ),
//                           Text('Phone: $selectedContactPhone'),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 16),

//                 // Results List
//                 Expanded(
//                   child: isLoading
//                       ? Center(
//                           child: CircularProgressIndicator(
//                             valueColor:
//                                 AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         )
//                       : salesData.isEmpty
//                           ? Center(
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.inbox,
//                                     size: 64,
//                                     color: Colors.grey[400],
//                                   ),
//                                   SizedBox(height: 16),
//                                   Text(
//                                     'No sales data found',
//                                     style: TextStyle(
//                                       color: Colors.grey[400],
//                                       fontSize: 18,
//                                       fontFamily: 'Roboto',
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             )
//                           : ListView.builder(
//                               itemCount: salesData.length,
//                               itemBuilder: (context, index) {
//                                 final sale = salesData[index];
//                                 return Card(
//                                   margin: EdgeInsets.only(bottom: 8.0),
//                                   elevation: 2.0,
//                                   child: ListTile(
//                                     title: Text(
//                                       sale['productName'],
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.w600,
//                                         fontFamily: 'Roboto',
//                                       ),
//                                     ),
//                                     subtitle: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text('Party: ${sale['partyName']}'),
//                                         Text(
//                                             'Date: ${DateFormat('dd/MM/yyyy').format(sale['date'])}'),
//                                       ],
//                                     ),
//                                     trailing: Column(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.end,
//                                       children: [
//                                         Text(
//                                           '₹${sale['amount'].toStringAsFixed(2)}',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             color: Color(0xFF27AE60),
//                                           ),
//                                         ),
//                                         Text(
//                                           'Qty: ${sale['quantity']}',
//                                           style: TextStyle(
//                                             fontSize: 12,
//                                             color: Colors.grey[600],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 );
//                               },
//                             ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
        );
  }
}
