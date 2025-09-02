import 'dart:io';

import 'package:card_settings/card_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:startup_namer/globals.dart';
import 'package:startup_namer/model.dart';

// Constants
const String DEFAULT_EMAIL = "mpgonda1986@gmail.com";
const String DEFAULT_PASSWORD = "wxmtzbjptnkulski";
const String DEFAULT_SUBJECT = " - MAHESH PHARMA GONDA";
const String DEFAULT_EMAIL_BODY = "ORDER IN STRIPS";

// Models
class Order {
  final String date;
  final String compEmail;
  final int count;
  final String compName;
  final bool isSent;
  final DateTime timestamp;

  Order({
    this.date,
    this.compEmail,
    this.count,
    this.compName,
    this.isSent,
    this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      "date": date,
      "compEmail": compEmail,
      "count": count,
      "compName": compName,
      "isSent": isSent,
      "timestamp": timestamp
    };
  }
}

class Product {
  final String prodName;
  final int prodMinQty;
  final int prodMaxQty;
  final int prodQty;
  final int week1Qty;
  final int week2Qty;
  final int week3Qty;
  final int week4Qty;

  Product({
    this.prodName,
    this.prodMinQty,
    this.prodMaxQty,
    this.prodQty,
    this.week1Qty,
    this.week2Qty,
    this.week3Qty,
    this.week4Qty,
  });
}

class ProductFilter {
  final String search;
  final int salesDays;
  final bool nonZeroSales;
  final bool showSalesData;
  final bool showStockData;

  ProductFilter({
    this.search = "",
    this.salesDays = 7,
    this.nonZeroSales = false,
    this.showSalesData = true,
    this.showStockData = true,
  });

  ProductFilter copyWith({
    String search,
    int salesDays,
    bool nonZeroSales,
    bool showSalesData,
    bool showStockData,
  }) {
    return ProductFilter(
      search: search ?? this.search,
      salesDays: salesDays ?? this.salesDays,
      nonZeroSales: nonZeroSales ?? this.nonZeroSales,
      showSalesData: showSalesData ?? this.showSalesData,
      showStockData: showStockData ?? this.showStockData,
    );
  }
}

// Services
class ProductService {
  static Future<void> saveOrderToFirestore(
      Order order,
      Map<String, ProductData> selectedProducts,
      List<String> productNames) async {
    final CollectionReference postsRef =
        FirebaseFirestore.instance.collection('/Orders');

    // Save order
    await postsRef.doc(order.timestamp.toString()).set(order.toJson());

    // Save products
    for (int i = 0; i < selectedProducts.length; i++) {
      ProductData product = selectedProducts[productNames[i]];
      Map<String, dynamic> prodData = product.toJson();

      await FirebaseFirestore.instance
          .collection('Orders')
          .doc(order.timestamp.toString())
          .collection(order.compName)
          .doc()
          .set(prodData);
    }
  }

  static Future<void> openFile(List<int> bytes, String name) async {
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$name.pdf");
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  static double getSalesCount(String itemCode, int salesDays) {
    if (globalFixedSalesData.containsKey(itemCode)) {
      return globalFixedSalesData[itemCode][salesDays] ?? 0;
    }
    return 0;
  }

  static double getStockCount(String itemCode) {
    return globalItemQuantityData[itemCode] ?? 0;
  }
}

class EmailService {
  static Future<void> sendEmail({
    String receiver,
    String subject,
    String body,
    String htmlContent,
    List<String> ccRecipients = const [],
    File attachment,
  }) async {
    final smtpServer = gmail(DEFAULT_EMAIL, DEFAULT_PASSWORD);

    final message = Message()
      ..from = Address(DEFAULT_EMAIL, 'Mahesh Pharma')
      ..ccRecipients.addAll(ccRecipients)
      ..recipients.add(receiver)
      ..subject = subject
      ..html = htmlContent;

    // Add attachment if provided
    if (attachment != null) {
      message.attachments = [
        FileAttachment(attachment)
          ..fileName = attachment.path.split('/').last
          ..contentType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      ];
    }

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: $sendReport');
      return;
    } on MailerException catch (e) {
      print('Message not sent: $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      throw e;
    }
  }

  static List<String> extractEmailsFromText(String text) {
    RegExp re = RegExp(r'([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)');
    Iterable<RegExpMatch> matches = re.allMatches(text);
    return matches
        .map((match) => text.substring(match.start, match.end))
        .toList();
  }
}

class ExcelService {
  static Future<List<Product>> processExcelFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null) {
      throw Exception("No file selected");
    }

    String filePath = result.files.single.path;
    String fileName = result.files.single.name;

    if (filePath == null || fileName == null) {
      throw Exception("Invalid file");
    }

    if (!fileName.endsWith('.xlsx') && !fileName.endsWith('.xls')) {
      throw Exception("Unsupported file type: $fileName");
    }

    var bytes = File(filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    var sheet = excel.tables.keys.first;
    var table = excel.tables[sheet];

    List<Product> products = [];

    for (var row in table.rows.skip(4)) {
      String prodName = row[0].toString();
      int prodMinQty = _parseInteger(row[17].toString());
      int prodMaxQty = _parseMaxQty(row[19]);
      int prodQty = _parseInteger(row[18].toString());
      int week1Qty = _parseInteger(row[22].toString());
      int week2Qty = _parseInteger(row[23].toString());
      int week3Qty = _parseInteger(row[24].toString());
      int week4Qty = _parseInteger(row[25].toString());

      products.add(Product(
        prodName: prodName,
        prodMinQty: prodMinQty,
        prodMaxQty: prodMaxQty,
        prodQty: prodQty,
        week1Qty: week1Qty,
        week2Qty: week2Qty,
        week3Qty: week3Qty,
        week4Qty: week4Qty,
      ));
    }

    return products;
  }

  static int _parseMaxQty(dynamic input) {
    if (input.toString() == "unlimited") {
      return -1;
    } else {
      return _parseInteger(input);
    }
  }

  static int _parseInteger(dynamic value) {
    if (value == null || value is! String) {
      return 0;
    }

    try {
      return int.parse(value.toString());
    } catch (e) {
      print("Error parsing integer: $value");
      return 0;
    }
  }

  static Future<File> generateExcelFile(
      Map<String, ProductData> selectedProducts, String companyName) async {
    // Create a new Excel file
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    // Add headers
    sheet.cell(CellIndex.indexByString('A1')).value = 'S.No.';
    sheet.cell(CellIndex.indexByString('B1')).value = 'Product Name';
    sheet.cell(CellIndex.indexByString('C1')).value = 'Pack Size';
    sheet.cell(CellIndex.indexByString('D1')).value = 'Quantity';

    // Add data rows
    int rowIndex = 2;
    int serialNumber = 1;

    selectedProducts.forEach((productName, product) {
      sheet.cell(CellIndex.indexByString('A$rowIndex')).value = serialNumber;
      sheet.cell(CellIndex.indexByString('B$rowIndex')).value = product.name;
      sheet.cell(CellIndex.indexByString('C$rowIndex')).value = product.pack;
      sheet.cell(CellIndex.indexByString('D$rowIndex')).value = product.qty;

      rowIndex++;
      serialNumber++;
    });

    // Save to temporary file
    final directory = await getTemporaryDirectory();
    final fileName =
        '${companyName}_Order_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      return file;
    } else {
      throw Exception('Failed to generate Excel file');
    }
  }
}

class PdfService {
  static Future<List<int>> generatePdf(
      Map<String, ProductData> selectedProducts) async {
    final doc = pw.Document();
    List<List<String>> tableData = [];

    // Prepare data
    selectedProducts.forEach((k, v) {
      tableData.add([v.name, v.pack.toString(), v.qty.toString()]);
    });

    // Sort by name
    tableData.sort((a, b) => a[0].compareTo(b[0]));

    // Add serial numbers
    for (int i = 0; i < tableData.length; i++) {
      tableData[i].insert(0, (i + 1).toString());
    }

    const tableHeaders = ["S.No.", "Product", "Pack", "QTY"];

    doc.addPage(pw.MultiPage(
      build: (pw.Context context) => [
        pw.Table.fromTextArray(
          context: context,
          data: tableData,
          cellAlignment: pw.Alignment.topLeft,
          headers: tableHeaders,
        ),
        pw.SizedBox(height: 20),
      ],
    ));

    return await doc.save();
  }
}

// Widgets
class ProductFilterDialog extends StatefulWidget {
  final ProductFilter currentFilter;
  final Function(ProductFilter) onFilterChanged;

  const ProductFilterDialog({
    Key key,
    this.currentFilter,
    this.onFilterChanged,
  }) : super(key: key);

  @override
  _ProductFilterDialogState createState() => _ProductFilterDialogState();
}

class _ProductFilterDialogState extends State<ProductFilterDialog> {
  ProductFilter filter;

  @override
  void initState() {
    super.initState();
    filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Filter Products",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Color(0xFF2C3E50),
              fontFamily: 'Roboto',
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[600]),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Options Section
              Text(
                "Display Options",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                  fontFamily: 'Roboto',
                ),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        "Only Non Zero Sales",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      value: filter.nonZeroSales,
                      activeColor: Color(0xFF34495E),
                      onChanged: (value) {
                        setState(() {
                          filter = filter.copyWith(nonZeroSales: value);
                        });
                      },
                    ),
                    Divider(height: 1, color: Colors.grey[300]),
                    CheckboxListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        "Show Sales Data",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      value: filter.showSalesData,
                      activeColor: Color(0xFF5D6D7E),
                      onChanged: (value) {
                        setState(() {
                          filter = filter.copyWith(showSalesData: value);
                        });
                      },
                    ),
                    Divider(height: 1, color: Colors.grey[300]),
                    CheckboxListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        "Show Stock Data",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      value: filter.showStockData,
                      activeColor: Color(0xFF9B59B6),
                      onChanged: (value) {
                        setState(() {
                          filter = filter.copyWith(showStockData: value);
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Days Filter Section
              Text(
                "Sales Period",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                  fontFamily: 'Roboto',
                ),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [7, 10, 15, 20, 30].map((days) {
                    return Column(
                      children: [
                        ListTile(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: Text(
                            "$days Days",
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          trailing: Radio<int>(
                            value: days,
                            groupValue: filter.salesDays,
                            activeColor: Color(0xFF5D6D7E),
                            onChanged: (value) {
                              setState(() {
                                filter = filter.copyWith(salesDays: value);
                              });
                            },
                          ),
                        ),
                        if (days != 30)
                          Divider(height: 1, color: Colors.grey[300]),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            "Cancel",
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onFilterChanged(filter);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            primary: Color(0xFF5D6D7E),
            onPrimary: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            "Apply Filters",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ],
    );
  }
}

class ProductItemWidget extends StatelessWidget {
  final ProductData product;
  final ProductFilter filter;
  final bool isSelected;
  final VoidCallback onAddPressed;
  final VoidCallback onModifyPressed;

  const ProductItemWidget({
    Key key,
    this.product,
    this.filter,
    this.isSelected,
    this.onAddPressed,
    this.onModifyPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? [Color(0xFFE8F5E8), Color(0xFFD4EDDA)]
                  : [Colors.white, Color(0xFFF8F9FA)],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onAddPressed,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Color(0xFF27AE60) : Color(0xFF3498DB),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isSelected
                                    ? Color(0xFF27AE60)
                                    : Color(0xFF3498DB))
                                .withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSelected ? Icons.check : Icons.inventory_2,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                              fontFamily: 'Roboto',
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Pack: ${product.pack}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              SizedBox(width: 10),
                              if (filter.showSalesData)
                                Text(
                                  'Sales: ${ProductService.getSalesCount(product.icode, filter.salesDays)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              SizedBox(width: 10),
                              if (filter.showStockData)
                                Text(
                                  'Stock: ${ProductService.getStockCount(product.icode)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary:
                            isSelected ? Color(0xFF27AE60) : Color(0xFF3498DB),
                        onPrimary: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        isSelected ? "Modify" : "Add",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      onPressed: isSelected ? onModifyPressed : onAddPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectedProductWidget extends StatelessWidget {
  final String productName;
  final String quantity;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  const SelectedProductWidget({
    Key key,
    this.productName,
    this.quantity,
    this.onEditPressed,
    this.onDeletePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8F5E8),
                Color(0xFFD4EDDA),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF27AE60),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF27AE60).withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Quantity: $quantity',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Color(0xFF3498DB),
                        size: 20,
                      ),
                      onPressed: onEditPressed,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Color(0xFFE74C3C),
                        size: 20,
                      ),
                      onPressed: onDeletePressed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmailDialog extends StatefulWidget {
  final CompanyData companyData;
  final String subjectBody;
  final String emailBody;
  final Function(String, String, String, String, List<String>) onSend;

  const EmailDialog({
    Key key,
    this.companyData,
    this.subjectBody,
    this.emailBody,
    this.onSend,
  }) : super(key: key);

  @override
  _EmailDialogState createState() => _EmailDialogState();
}

class _EmailDialogState extends State<EmailDialog> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController;
  TextEditingController _ccController;
  TextEditingController _subjectController;
  TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.companyData.email);
    _ccController = TextEditingController(text: widget.companyData.cc);
    _subjectController = TextEditingController(text: widget.subjectBody);
    _messageController = TextEditingController(text: widget.emailBody);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _ccController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Form Content
        Form(
          key: _formKey,
          child: CardSettings(
            children: [
              CardSettingsSection(
                header: CardSettingsHeader(
                  label: 'Email Details',
                  color: Color(0xFF5D6D7E),
                ),
                children: [
                  CardSettingsEmail(
                    controller: _emailController,
                    requiredIndicator:
                        Text("*", style: TextStyle(color: Colors.red)),
                    maxLength: 50,
                    icon: Icon(Icons.mail, color: Color(0xFF5D6D7E)),
                    label: "Receiver Email",
                  ),
                  CardSettingsText(
                    maxLength: 100,
                    controller: _ccController,
                    icon: Icon(Icons.mail, color: Color(0xFF5D6D7E)),
                    label: 'CC/BCC',
                  ),
                  CardSettingsText(
                    contentAlign: TextAlign.left,
                    maxLength: 100,
                    icon: Icon(Icons.textsms, color: Color(0xFF5D6D7E)),
                    label: 'Subject',
                    controller: _subjectController,
                  ),
                  CardSettingsParagraph(
                    icon: Icon(Icons.message, color: Color(0xFF5D6D7E)),
                    label: 'Message',
                    controller: _messageController,
                    numberOfLines: 6,
                    initialValue: widget.emailBody,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Actions
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Handle send later logic
                  },
                  style: OutlinedButton.styleFrom(
                    primary: Color(0xFF6C757D),
                    side: BorderSide(color: Color(0xFF6C757D)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Send Later",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    List<String> ccRecipients =
                        EmailService.extractEmailsFromText(_ccController.text);
                    widget.onSend(
                      _emailController.text,
                      _subjectController.text,
                      _messageController.text,
                      _ccController.text,
                      ccRecipients,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF5D6D7E),
                    onPrimary: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    "Send Now",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Main Product Page
class ProductPage extends StatefulWidget {
  final CompanyData data;
  final String docID;
  final bool check;

  const ProductPage({
    Key key,
    this.data,
    this.docID,
    this.check,
  }) : super(key: key);

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage>
    with AutomaticKeepAliveClientMixin {
  // State variables
  final Map<String, ProductData> selectedProductList = {};
  final List<String> selectedProductNames = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _allProductsScrollController = ScrollController();
  final ScrollController _selectedProductsScrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isFabVisible = true;

  List<ProductData> productList = [];
  List<ProductData> filteredProductList = [];
  ProductFilter filter = ProductFilter();
  String action = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _allProductsScrollController.addListener(_scrollListener);
    _selectedProductsScrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    ScrollController currentController = _allProductsScrollController.hasClients
        ? _allProductsScrollController
        : _selectedProductsScrollController;

    if (currentController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (currentController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
  }

  void _initializeData() {
    selectedProductList.clear();
    selectedProductNames.clear();

    // Load products based on company codes
    List codes = widget.data.codes.isNotEmpty
        ? widget.data.codes
        : [widget.data.compCode];

    for (ProductData product in globalProductList) {
      if (widget.data.name.contains("MANK") ||
          widget.data.name.contains("ARISTO")) {
        String codeKey = '${product.compCode ?? ''}-${product.division ?? ''}';
        if (codes.contains(codeKey)) {
          productList.add(product);
        }
      } else {
        if (codes.contains(product.compCode ?? '')) {
          productList.add(product);
        }
      }
    }

    filteredProductList = List.from(productList);

    if (widget.check) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    FirebaseFirestore.instance
        .collection('Orders')
        .doc(widget.docID)
        .collection(widget.data.name)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        ProductData data = ProductData(
          name: doc['prodName'],
          pack: doc['prodPack'],
          qty: doc['prodQty'],
          division: doc['prodDivision'],
        );
        selectedProductNames.add(doc['prodName']);
        selectedProductList[doc['prodName']] = data;
      }
      setState(() {});
    });
  }

  void _filterProducts() {
    setState(() {
      filteredProductList = productList.where((product) {
        bool matchesSearch = filter.search.isEmpty ||
            product.name.toUpperCase().contains(filter.search.toUpperCase());

        bool matchesSalesFilter = !filter.nonZeroSales ||
            ProductService.getSalesCount(product.icode, filter.salesDays) > 0;

        return matchesSearch && matchesSalesFilter;
      }).toList();
    });
  }

  void _onSearchChanged(String text) {
    filter = filter.copyWith(search: text);
    _filterProducts();
    if (_allProductsScrollController.hasClients) {
      _allProductsScrollController.jumpTo(0);
    }
  }

  void _onFilterChanged(ProductFilter newFilter) {
    setState(() {
      filter = newFilter;
      _filterProducts();
    });
  }

  void _addProduct(ProductData product) {
    if (!selectedProductList.containsKey(product.name)) {
      setState(() {
        selectedProductList[product.name] = product;
        selectedProductNames.add(product.name);
      });
    }
  }

  void _modifyProduct(ProductData product) {
    if (selectedProductList.containsKey(product.name)) {
      setState(() {
        selectedProductList[product.name].qty = product.qty;
      });
    }
  }

  void _removeProduct(String productName) {
    setState(() {
      selectedProductList.remove(productName);
      selectedProductNames.remove(productName);
    });
  }

  void _showQuantityDialog(String productName) {
    TextEditingController quantityController = TextEditingController(
      text: selectedProductList[productName]?.qty ?? "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.edit,
              color: Color(0xFF3498DB),
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              "Edit Quantity",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Color(0xFF2C3E50),
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Update quantity for:",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 8),
            Text(
              productName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: quantityController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter quantity",
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Roboto',
                ),
                prefixIcon: Icon(Icons.shopping_cart, color: Color(0xFF3498DB)),
                filled: true,
                fillColor: Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Roboto',
              ),
              onSubmitted: (text) {
                if (selectedProductList.containsKey(productName)) {
                  setState(() {
                    selectedProductList[productName].qty = text;
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedProductList.containsKey(productName)) {
                setState(() {
                  selectedProductList[productName].qty =
                      quantityController.text;
                });
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              primary: Color(0xFF27AE60),
              onPrimary: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              "Update",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(ProductData product, bool isModify) {
    TextEditingController nameController =
        TextEditingController(text: product.name);
    TextEditingController packController =
        TextEditingController(text: product.pack);
    TextEditingController qtyController = TextEditingController();
    FocusNode qtyFocusNode = FocusNode();
    bool validate = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(
                isModify ? Icons.edit : Icons.add,
                color: isModify ? Color(0xFFF39C12) : Color(0xFF27AE60),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                isModify ? "Modify Product" : "Add Product",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Color(0xFF2C3E50),
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Product Name",
                    labelStyle: TextStyle(
                      color: Color(0xFF3498DB),
                      fontFamily: 'Roboto',
                    ),
                    prefixIcon:
                        Icon(Icons.inventory_2, color: Color(0xFF3498DB)),
                    filled: true,
                    fillColor: Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Roboto',
                  ),
                  onChanged: (text) => product.name = text,
                  onSubmitted: (text) =>
                      FocusScope.of(context).requestFocus(qtyFocusNode),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: packController,
                  decoration: InputDecoration(
                    labelText: "Pack Size",
                    labelStyle: TextStyle(
                      color: Color(0xFF3498DB),
                      fontFamily: 'Roboto',
                    ),
                    prefixIcon: Icon(Icons.inventory, color: Color(0xFF3498DB)),
                    filled: true,
                    fillColor: Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Roboto',
                  ),
                  onChanged: (text) => product.pack = text,
                  onSubmitted: (text) =>
                      FocusScope.of(context).requestFocus(qtyFocusNode),
                ),
                SizedBox(height: 16),
                TextField(
                  focusNode: qtyFocusNode,
                  controller: qtyController,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: "Quantity",
                    labelStyle: TextStyle(
                      color: Color(0xFF3498DB),
                      fontFamily: 'Roboto',
                    ),
                    errorText: validate ? "Quantity is required" : null,
                    prefixIcon:
                        Icon(Icons.shopping_cart, color: Color(0xFF3498DB)),
                    filled: true,
                    fillColor: Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Roboto',
                  ),
                  onSubmitted: (text) {
                    if (text.isEmpty) {
                      setDialogState(() => validate = true);
                    } else {
                      product.qty = text;
                      if (isModify) {
                        _modifyProduct(product);
                      } else {
                        _addProduct(product);
                      }
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              onPressed: () {
                if (qtyController.text.isEmpty) {
                  setDialogState(() => validate = true);
                } else {
                  int qty = int.tryParse(qtyController.text) ?? 0;
                  if (qty > 0) {
                    ProductData productWithQty = ProductData(
                      name: product.name,
                      pack: product.pack,
                      qty: qty.toString(),
                      icode: product.icode,
                      compCode: product.compCode,
                      division: product.division,
                      expiryDate: product.expiryDate,
                      deal1: product.deal1,
                      deal2: product.deal2,
                      mrp: product.mrp,
                      batchNumber: product.batchNumber,
                      amount: product.amount,
                    );
                    _addProduct(productWithQty);
                  }
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF5D6D7E),
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                "Add",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackButtonWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Color(0xFFF39C12),
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              "Unsaved Changes",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Color(0xFF2C3E50),
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You have ${selectedProductList.length} item${selectedProductList.length == 1 ? '' : 's'} in your cart.",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF2C3E50),
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Do you want to stay on the page or discard the changes?",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Stay",
              style: TextStyle(
                color: Color(0xFF3498DB),
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              primary: Color(0xFFE74C3C),
              onPrimary: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              "Discard",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    try {
      final pdfBytes = await PdfService.generatePdf(selectedProductList);
      await ProductService.openFile(
          pdfBytes, "${widget.data.name}$DEFAULT_SUBJECT");
    } catch (e) {
      _showSnackBar("Error generating PDF: $e");
    }
  }

  Future<void> _processExcelFile() async {
    try {
      final products = await ExcelService.processExcelFile();
      // Handle the processed products as needed
      _showSnackBar(
          "Excel file processed successfully. Found ${products.length} products.");
    } catch (e) {
      _showSnackBar("Error processing Excel file: $e");
    }
  }

  Future<void> _sendEmail(String receiver, String subject, String message,
      String cc, List<String> ccRecipients, bool attachExcel) async {
    setState(() => isLoading = true);

    try {
      // Check internet connection
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw Exception("No internet connection");
      }

      // Delete existing order if editing
      if (widget.check) {
        await FirebaseFirestore.instance
            .collection('Orders')
            .doc(widget.docID)
            .delete();
      }

      // Create order
      DateTime now = DateTime.now();
      Order order = Order(
        date: "${now.day}/${now.month}/${now.year}",
        compEmail: widget.data.email,
        count: selectedProductList.length,
        compName: widget.data.name,
        isSent: true,
        timestamp: now,
      );

      // Save to Firestore
      await ProductService.saveOrderToFirestore(
          order, selectedProductList, selectedProductNames);

      // Generate Excel file if requested
      File excelFile;
      if (attachExcel) {
        excelFile = await ExcelService.generateExcelFile(
            selectedProductList, widget.data.name);
      }

      // Send email
      String htmlContent = _buildEmailHtml(message);
      await EmailService.sendEmail(
        receiver: receiver,
        subject: subject,
        body: message,
        htmlContent: htmlContent,
        ccRecipients: ccRecipients,
        attachment: excelFile,
      );

      setState(() => action = "Mail Sent Successfully");
      _showSnackBar(action);
    } catch (e) {
      setState(() => action = "Oops!! Mail Sending Failed");
      _showSnackBar("$action: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _buildEmailHtml(String message) {
    if (widget.data.name == "ABT INDIA") {
      return _buildDivisionWiseHtml(message);
    } else {
      return _buildSimpleHtml(message);
    }
  }

  String _buildDivisionWiseHtml(String message) {
    Map<String, bool> divisions = {};
    selectedProductList.forEach((k, v) => divisions[v.division] = true);

    String html = "";

    // Add custom message at the beginning
    if (message.isNotEmpty) {
      html += '''
        <p>$message</p>
        <br>
      ''';
    }

    divisions.forEach((division, _) {
      String tableRows = "";
      int i = 1;
      selectedProductList.forEach((name, product) {
        if (product.division == division) {
          tableRows += '''
            <tr>
              <td>$i</td>
              <td>$name</td>
              <td>${product.pack}</td>
              <td>${product.qty}</td>
            </tr>
          ''';
          i++;
        }
      });

      html += '''
        <h3>$division</h3>
        <table border="1" width="400" cellpadding="5px" style="border-collapse:collapse">
          <tr><th>S.No.</th><th>Product</th><th>Pack</th><th>Quantity</th></tr>
          $tableRows
        </table>
      ''';
    });

    // Add signature
    html += '''
      <br><br>
      <p>Thanks<br>
      Mahesh Pharma Gonda</p>
    ''';

    return html;
  }

  String _buildSimpleHtml(String message) {
    String tableRows = "";
    int i = 1;
    selectedProductList.forEach((name, product) {
      tableRows += '''
        <tr>
          <td>$i</td>
          <td>$name</td>
          <td>${product.pack}</td>
          <td>${product.qty}</td>
        </tr>
      ''';
      i++;
    });

    String html = "";

    // Add custom message at the beginning
    if (message.isNotEmpty) {
      html += '''
        <p>$message</p>
        <br>
      ''';
    }

    html += '''
      <table border="1" width="400" cellpadding="5px" style="border-collapse:collapse">
        <tr><th>S.No.</th><th>Product</th><th>Pack</th><th>Quantity</th></tr>
        $tableRows
      </table>
      <br><br>
      <p>Thanks<br>
      Mahesh Pharma Gonda</p>
    ''';

    return html;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Color(0xFF2C3E50),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (selectedProductList.isNotEmpty) {
                _showBackButtonWarning();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            "Products",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.0,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto',
            ),
          ),
          actions: [
            PopupMenuButton<int>(
              icon: Icon(Icons.more_vert, color: Colors.white),
              onSelected: (int value) {
                if (value == 1) {
                  _generatePdf();
                } else if (value == 2 && widget.data.name == "SUN-NEW") {
                  _processExcelFile();
                }
              },
              itemBuilder: (context) {
                List<PopupMenuItem<int>> items = [
                  PopupMenuItem<int>(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(Icons.download_rounded, color: Color(0xFF3498DB)),
                        SizedBox(width: 8),
                        Text("Download PDF"),
                      ],
                    ),
                  ),
                ];

                if (widget.data.name == "SUN-NEW") {
                  items.add(
                    PopupMenuItem<int>(
                      value: 2,
                      child: Row(
                        children: [
                          Icon(Icons.upload_file, color: Color(0xFF3498DB)),
                          SizedBox(width: 8),
                          Text("Upload Excel File"),
                        ],
                      ),
                    ),
                  );
                }

                return items;
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                child: Text(
                  "All Products",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
              Tab(
                child: Text(
                  "Cart",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[300],
          ),
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
          child: TabBarView(
            children: [
              AllProductsTab(
                productList: productList,
                filteredProductList: filteredProductList,
                filter: filter,
                selectedProductList: selectedProductList,
                onSearchChanged: _onSearchChanged,
                onFilterChanged: _onFilterChanged,
                onProductTap: _showProductDialog,
                scrollController: _allProductsScrollController,
              ),
              SelectedProductsTab(
                selectedProductNames: selectedProductNames,
                selectedProductList: selectedProductList,
                onEditPressed: _showQuantityDialog,
                onDeletePressed: _removeProduct,
                scrollController: _selectedProductsScrollController,
              ),
            ],
          ),
        ),
        floatingActionButton: AnimatedOpacity(
          opacity: _isFabVisible ? 1.0 : 0.0,
          duration: Duration(milliseconds: 300),
          child: FloatingActionButton.extended(
            onPressed: () {
              if (widget.data.name == "MANKIND-MAIN") {
                _processExcelFile();
              } else {
                _showEmailDialog();
              }
            },
            icon: Icon(Icons.send),
            label: Text(
              "Send",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
            backgroundColor: Color(0xFF87CEEB),
            elevation: 8,
          ),
        ),
      ),
    );
  }

  void _showEmailDialog() {
    // Create controllers for the form fields
    final emailController = TextEditingController(text: widget.data.email);
    final ccController = TextEditingController(text: widget.data.cc);
    final subjectController = TextEditingController(
        text: "${widget.data.name} - MAHESH PHARMA GONDA");
    final messageController = TextEditingController(text: DEFAULT_EMAIL_BODY);
    bool attachExcel = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF2C3E50),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mail, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Send Order Email',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receiver Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: "Enter receiver email",
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          prefixIcon:
                              Icon(Icons.mail, color: Color(0xFF5D6D7E)),
                          filled: true,
                          fillColor: Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'CC/BCC',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: ccController,
                        decoration: InputDecoration(
                          hintText: "Enter CC/BCC emails",
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          prefixIcon:
                              Icon(Icons.mail, color: Color(0xFF5D6D7E)),
                          filled: true,
                          fillColor: Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Subject',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: subjectController,
                        decoration: InputDecoration(
                          hintText: "Enter email subject",
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          prefixIcon:
                              Icon(Icons.textsms, color: Color(0xFF5D6D7E)),
                          filled: true,
                          fillColor: Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: messageController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: "Enter email message",
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontFamily: 'Roboto',
                          ),
                          prefixIcon:
                              Icon(Icons.message, color: Color(0xFF5D6D7E)),
                          filled: true,
                          fillColor: Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 20),
                      // Excel Attachment Checkbox
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFFE9ECEF),
                            width: 1,
                          ),
                        ),
                        child: StatefulBuilder(
                          builder: (context, setState) => Row(
                            children: [
                              Checkbox(
                                value: attachExcel,
                                onChanged: (value) {
                                  setState(() {
                                    attachExcel = value ?? false;
                                  });
                                },
                                activeColor: Color(0xFF27AE60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attach Excel File',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E50),
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Include order data as Excel attachment',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.table_chart,
                                color: Color(0xFF27AE60),
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Handle send later logic
                        },
                        style: OutlinedButton.styleFrom(
                          primary: Color(0xFF6C757D),
                          side: BorderSide(color: Color(0xFF6C757D)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Send Later",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          List<String> ccRecipients =
                              EmailService.extractEmailsFromText(
                                  ccController.text);
                          _sendEmail(
                            emailController.text,
                            subjectController.text,
                            messageController.text,
                            ccController.text,
                            ccRecipients,
                            attachExcel,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFF5D6D7E),
                          onPrimary: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "Send Now",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _allProductsScrollController.removeListener(_scrollListener);
    _allProductsScrollController.dispose();
    _selectedProductsScrollController.removeListener(_scrollListener);
    _selectedProductsScrollController.dispose();
    super.dispose();
  }
}

class AllProductsTab extends StatefulWidget {
  final List<ProductData> productList;
  final List<ProductData> filteredProductList;
  final ProductFilter filter;
  final Map<String, ProductData> selectedProductList;
  final Function(String) onSearchChanged;
  final Function(ProductFilter) onFilterChanged;
  final Function(ProductData, bool) onProductTap;
  final ScrollController scrollController;

  const AllProductsTab({
    Key key,
    this.productList,
    this.filteredProductList,
    this.filter,
    this.selectedProductList,
    this.onSearchChanged,
    this.onFilterChanged,
    this.onProductTap,
    this.scrollController,
  }) : super(key: key);

  @override
  _AllProductsTabState createState() => _AllProductsTabState();
}

class _AllProductsTabState extends State<AllProductsTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.filter.search;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // Search and Filter Section
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Search Bar
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontFamily: 'Roboto',
                    ),
                    suffixIcon: widget.filter.search.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchChanged("");
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Roboto',
                  ),
                  onChanged: widget.onSearchChanged,
                ),
              ),
              // Filter Icon Button
              SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF34495E),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2C3E50).withOpacity(0.3),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ProductFilterDialog(
                        currentFilter: widget.filter,
                        onFilterChanged: widget.onFilterChanged,
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 18,
                  ),
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Products List
        Expanded(
          child: widget.filteredProductList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        widget.filter.search.isNotEmpty
                            ? "No products found"
                            : "No products available",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontFamily: 'Roboto',
                        ),
                      ),
                      if (widget.filter.search.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          "Try adjusting your search or filters",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.filteredProductList.length,
                  itemBuilder: (context, index) {
                    ProductData product = widget.filteredProductList[index];
                    bool isSelected =
                        widget.selectedProductList.containsKey(product.name);

                    return Container(
                      margin: EdgeInsets.only(bottom: 6),
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isSelected
                                  ? [Color(0xFFE8F5E8), Color(0xFFD4EDDA)]
                                  : [Colors.white, Color(0xFFF8F9FA)],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () =>
                                  widget.onProductTap(product, isSelected),
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    SizedBox(width: 12),
                                    // Product Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2C3E50),
                                              fontFamily: 'Roboto',
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 3,
                                            children: [
                                              _buildInfoChip(
                                                "Pack: ${product.pack}",
                                                Color(0xFF3498DB),
                                              ),
                                              if (widget.filter.showSalesData)
                                                _buildInfoChip(
                                                  "Sales: ${ProductService.getSalesCount(product.icode, widget.filter.salesDays)}",
                                                  Color(0xFFF39C12),
                                                ),
                                              if (widget.filter.showStockData)
                                                _buildInfoChip(
                                                  "Stock: ${ProductService.getStockCount(product.icode)}",
                                                  Color(0xFF9B59B6),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Action Button
                                    SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        primary: isSelected
                                            ? Color(0xFF34495E)
                                            : Color(0xFF5D6D7E),
                                        onPrimary: Colors.white,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size(60, 32),
                                      ),
                                      child: Text(
                                        isSelected ? "Modify" : "Add",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      onPressed: () => widget.onProductTap(
                                          product, isSelected),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class SelectedProductsTab extends StatefulWidget {
  final List<String> selectedProductNames;
  final Map<String, ProductData> selectedProductList;
  final Function(String) onEditPressed;
  final Function(String) onDeletePressed;
  final ScrollController scrollController;

  const SelectedProductsTab({
    Key key,
    this.selectedProductNames,
    this.selectedProductList,
    this.onEditPressed,
    this.onDeletePressed,
    this.scrollController,
  }) : super(key: key);

  @override
  _SelectedProductsTabState createState() => _SelectedProductsTabState();
}

class _SelectedProductsTabState extends State<SelectedProductsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.selectedProductNames.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  "No products selected",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Add products from the All Products tab",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            controller: widget.scrollController,
            padding: EdgeInsets.all(16),
            itemCount: widget.selectedProductNames.length,
            itemBuilder: (context, index) {
              String productName = widget.selectedProductNames[index];
              ProductData product = widget.selectedProductList[productName];

              if (product == null) return SizedBox.shrink();

              return Container(
                margin: EdgeInsets.only(bottom: 6),
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF8F9FA),
                          Color(0xFFE9ECEF),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          SizedBox(width: 12),
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E50),
                                    fontFamily: 'Roboto',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Pack: ${product.pack}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quantity and Actions
                          Column(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF34495E),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF34495E).withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "Qty: ${product.qty}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                              SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: Color(0xFF3498DB),
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        widget.onEditPressed(productName),
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: Color(0xFFE74C3C),
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        widget.onDeletePressed(productName),
                                    padding: EdgeInsets.all(4),
                                    constraints: BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }
}
