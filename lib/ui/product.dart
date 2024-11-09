import 'dart:io';

import 'package:card_settings/card_settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:startup_namer/model.dart';

import './form.dart';

bool progress;

class Order {
  String date;
  String compEmail;
  int count;
  String compName;
  bool isSent;
  DateTime timestamp;
  Order({this.date, this.compEmail, this.count, this.compName, this.isSent});

  toJson() {
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
  String prodName;
  int prodMinQty;
  int prodMaxQty;
  int prodQty;
  int week1Qty;
  int week2Qty;
  int week3Qty;
  int week4Qty;

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

Map<String, ProductData> selectedProductList = new Map();
List<String> testList = new List();
String action;

class ProductPage extends StatefulWidget {
  final CompanyData data;
  final String docID;
  final bool check;
  ProductPage({this.data, this.docID, this.check});
  String myEmail = "mpgonda1986@gmail.com";
  String myPass = "wxmtzbjptnkulski";
  String subjectBody = " - MAHESH PHARMA GONDA";
  String emailBody = "ORDER IN STRIPS";
  String receiver = "";
  List<String> ccRecepients = List();
  String test = "";

  String buildStringDivisionWise() {
    if (data.name == "ABT INDIA") {
      String test1 = "";
      Map<String, bool> division = Map();
      selectedProductList.forEach((k, v) => {division[v.division] = true});
      int i;
      String test = "";
      String test0;
      division.forEach((k, v) => {
            test0 = '<h3>' + k + '</h3>',
            i = 1,
            test1 = "",
            selectedProductList.forEach((t, s) => {
                  if (s.division == k)
                    {
                      test1 = test1 +
                          '<tr><td>' +
                          i.toString() +
                          '</td><td>' +
                          t +
                          '</td><td>' +
                          s.pack +
                          '</td>' +
                          '<td>' +
                          s.qty +
                          '</td></tr>',
                      i++
                    }
                }),
            print("--------->>" + i.toString()),
            test = test +
                test0 +
                '<table border="1" width="400" cellpadding="5px" style="border-collapse:collapse"><tr><th>S.No.</th><th>Product</th><th>Pack</th><th>Quantity</th></tr>' +
                test1 +
                '</table>',
          });
      return test;
    } else {
      String test1 = "";
      int i = 1;
      selectedProductList.forEach((k, v) => {
            test1 = test1 +
                '<tr><td>' +
                i.toString() +
                '</td><td>' +
                k +
                '</td><td>' +
                v.pack +
                '</td>' +
                '<td>' +
                v.qty +
                '</td></tr>',
            i++
          });

      String test =
          '<table border="1" width="400" cellpadding="5px" style="border-collapse:collapse"><tr><th>S.No.</th><th>Product</th><th>Pack</th><th>Quantity</th></tr>' +
              test1 +
              '</table>';
      return test;
    }
  }

  int x = 1;
  sendDataToFirestore(bool check) async {
    DateTime now = new DateTime.now();
    DateTime timestamp1 = new DateTime(now.year, now.month, now.day, now.hour,
        now.minute, now.second, now.millisecond);
    String date1 = now.day.toString() +
        "/" +
        now.month.toString() +
        "/" +
        now.year.toString();
    String compEmail1 = data.email;
    int count1 = testList.length;
    String compName1 = data.name;
    bool isSent1 = check;
    final CollectionReference postsRef =
        FirebaseFirestore.instance.collection('/Orders');

    Order order = new Order();
    order.date = date1;
    order.compEmail = compEmail1;
    order.count = count1;
    order.compName = compName1;
    order.isSent = isSent1;
    order.timestamp = timestamp1;
    Map<String, dynamic> orderData = order.toJson();
    await postsRef.doc(timestamp1.toString()).set(orderData);

    for (int i = 0; i < selectedProductList.length; i++) {
      ProductData product = new ProductData();
      product.name = selectedProductList[testList[i]].name;
      product.pack = selectedProductList[testList[i]].pack;
      product.qty = selectedProductList[testList[i]].qty;
      product.division = selectedProductList[testList[i]].division;
      Map<String, dynamic> prodData = product.toJson();
      FirebaseFirestore.instance
          .collection('Orders')
          .doc(timestamp1.toString())
          .collection(order.compName)
          .doc()
          .set(prodData);
    }
  }

  static void openFile(List<int> bytes, String name) async {
    print("here2");
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/" + name + ".pdf");
    print("here3");
    await file.writeAsBytes(bytes);
    print("here4");
    OpenFile.open(file.path);
    print("here5");
  }

  @override
  _ProductPageState createState() => new _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  _displaySnackBar(String action1) {
    if (action1 == "") {
      action1 = "StatusUnknown";
    }
    final snackbar = new SnackBar(content: Text(action1));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  void fillData(BuildContext context) {
    FirebaseFirestore.instance
        .collection('Orders')
        .doc(widget.docID)
        .collection(widget.data.name)
        .snapshots()
        .listen((cour) => cour.docs.forEach((doc) {
              ProductData dataa = ProductData();
              dataa.name = doc['prodName'];
              dataa.pack = doc['prodPack'];
              dataa.qty = doc['prodQty'];
              dataa.division = doc['prodDivision'];
              testList.add(doc['prodName']);
              selectedProductList[doc['prodName']] = dataa;
              setState(() {});
            }));
  }

  String search = "";

  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    selectedProductList.clear();
    testList.clear();
    if (widget.check == true) {
      fillData(context);
    }
    super.initState();
  }

  void buildCC() {
    if (widget.test == "") {
      return;
    }
    RegExp re = new RegExp('([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)');
    Iterable matches = re.allMatches(widget.test);
    matches.forEach((match) {
      widget.ccRecepients.add(widget.test.substring(match.start, match.end));
    });
  }

  pdfGenerator() async {
    print("Insde pdf");
    final doc = pw.Document();
    List<List<String>> trial = List();
    var element = (["S.No.", "Product", "Pack", "QTY"]);
    int a = 0;

    selectedProductList.forEach((k, v) {
      trial.add([v.name, v.pack.toString(), v.qty.toString()]);
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
    const tableHeaders = ["S.No.", "Product", "Pack", "QTY"];

    doc.addPage(pw.MultiPage(
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
            ]));
    print("----> here1");
    final pdfBytes = List.from(await doc.save());
    final pdfIntBytes = pdfBytes.cast<int>();
    if (pdfBytes.length > 0) {
      ProductPage.openFile(pdfIntBytes, widget.data.name + widget.subjectBody);
    }
  }

  Future<void> mailing() async {
    print("inside mailing");
    buildCC();
    final smtpServer = gmail(widget.myEmail, widget.myPass);
    print(widget.receiver);
    final message = new Message()
      ..from = new Address(widget.myEmail, 'Mahesh Pharma')
      ..ccRecipients.addAll(widget.ccRecepients)
      ..recipients.add(widget.receiver)
      ..subject = widget.data.name + widget.subjectBody
      ..html = "<p>" +
          widget.emailBody +
          "<p>\n\n\n\n\n" +
          widget.buildStringDivisionWise() +
          "\n\n<p>Mahesh Pharma</p><p>Gonda</p>";

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      setState(() {
        action = "Mail Sent Successfully";
      });
      widget.sendDataToFirestore(true);
    } on MailerException catch (e) {
      print('Message not sent. $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      setState(() {
        action = "Opps!! Mail Sending Failed";
      });
      widget.sendDataToFirestore(false);

      for (var p in e.problems) {
        print("hii");
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }

  static const androidMethodChannel =
      const MethodChannel('team.native.io/openGmail');

  void excelBuild() async {
    ByteData data = await rootBundle.load("asset/MANKIND-MAIN.xlsx");
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    var decoder = new Excel.decodeBytes(bytes);

    decoder.updateCell(
        'MANKIND',
        CellIndex.indexByString("A4"),
        "Date:- " +
            DateTime.now().day.toString() +
            "-" +
            DateTime.now().month.toString() +
            "-" +
            DateTime.now().year.toString());
    for (var table in decoder.tables.keys) {
      int i = 0;
      for (var row in decoder.tables[table].rows) {
        i++;
        if (i >= 8) {
          decoder.updateCell(
              'MANKIND', CellIndex.indexByString("C" + i.toString()), "");
        }
      }
    }

    selectedProductList.forEach((key, value) {
      for (var table in decoder.tables.keys) {
        int i = 0;
        for (var row in decoder.tables[table].rows) {
          i++;
          if (row[0] == key) {
            decoder.updateCell('MANKIND',
                CellIndex.indexByString("C" + i.toString()), value.qty,
                cellStyle: CellStyle(horizontalAlign: HorizontalAlign.Center));
            break;
          }
        }
      }
    });

    String directoryExt;
    new Directory('/storage/emulated/0/MyFile').create()
        // The created directory is returned as a Future.
        .then((Directory directory) {
      print(directory.path);
      directoryExt = directory.path;
    });

    Map<Permission, PermissionStatus> permissions =
        await [Permission.storage].request();
    // if (await Permission.storage.isGranted) {
    //   decoder.encode().then((onValue) {
    //     File(directoryExt + "/" + "mankind.xlsx")
    //       ..createSync(recursive: true)
    //       ..writeAsBytesSync(onValue);
    //   });
    //   bool check = await File(directoryExt + "/" + "mankind.xlsx").exists();
    //   print("Check iss ===============>>>>>" + check.toString());
    // }

    await androidMethodChannel.invokeMethod('openGmail', {
      'filePath': directoryExt + "/" + "mankind.xlsx",
      'subject': "Hii My name is Rishabh",
      'mailId': "rishabhag.official@gmail.com"
    });
  }

  void addToMap(ProductData prod) {
    setState(() {
      if (!selectedProductList.containsKey(prod.name)) {
        selectedProductList[prod.name] = prod;
        testList.add(prod.name);
        print(testList);
      } else {
        selectedProductList[prod.name].qty = prod.qty;
      }
    });
  }

  Widget pressedButton(String prodName) {
    TextEditingController _selectedController =
        TextEditingController(text: selectedProductList[prodName].qty);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              primary: Colors.grey[50],
            ),
            child: Text(
              selectedProductList[prodName].qty,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
            onPressed: () {
              //addToMap(prod);
              showDialog(
                context: context,
                builder: (context) {
                  // FocusNode inputOne = FocusNode();
                  return AlertDialog(
                    // contentPadding: EdgeInsets.all(0.0),
                    title: new Text("Enter Quantity"),
                    content: TextField(
                      autofocus: true,
                      keyboardType: TextInputType.text,
                      controller: _selectedController,
                      decoration: InputDecoration(hintText: "Enter Quantity"),
                      onSubmitted: (text) {
                        selectedProductList[prodName].qty =
                            _selectedController.text;
                        Navigator.of(context).pop();
                        _selectedController.clear();
                      },
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: new Text("Close"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _selectedController.clear();
                        },
                      ),
                    ],
                  );
                },
              );
            })
      ],
    );
  }

  TextEditingController _textFieldController = TextEditingController();
  TextEditingController _search = TextEditingController();
  ScrollController _scroll = new ScrollController();

  final _sKey = GlobalKey<ScaffoldMessengerState>();
  Widget _showBackButtonWarningDialog() {
    return AlertDialog(
      // contentPadding: EdgeInsets.all(0.0),
      title: new Text("Alert!!"),
      content: new Text(
          "You have some items in your cart. Do you want to stay on the page or discard the changes?"),
      actions: [
        TextButton(
          // FlatButton widget is used to make a text to work like a button
          //textColor: Colors.black,
          onPressed:
              () {}, // function used to perform after pressing the button
          child: Text('Discard'),
        ),
        TextButton(
          //textColor: Colors.black,
          onPressed: () {},
          child: Text('Send Later'),
        ),
      ],
    );
  }

  int _parseMaxQty(Data input) {
    if (input.value == "unlimited") {
      return -1;
    } else {
      return _parseInteger(input);
    }
  }

  int _parseInteger(dynamic value) {
    if (value == null || value is! String) {
      return 0; // Return a default value if the value is null or not a string
    }

    String input = value.toString();

    try {
      return int.parse(input);
    } catch (e) {
      // Handle parsing errors gracefully
      print("Error parsing integer: $input");
      return 0; // Default value or handle error as needed
    }
  }

  List<Product> _sunProducts = [];
  Future<void> pickAndProcessFile() async {
    // Pick a file
    FilePickerResult result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      String filePath = result.files.single.path;
      String fileName = result.files.single.name;

      // Check file extension
      if (filePath != null && fileName != null) {
        if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
          // It's an Excel file
          // Process the Excel file
          print("Processing Excel file: $filePath");
          // Get the current month name
          // String currentMonth = DateFormat('MMMM').format(DateTime.now());

          // // Rename the file
          // String newFileName = "SUN-$currentMonth.xlsx";
          // Directory appDocumentsDirectory =
          //     await getApplicationDocumentsDirectory();
          // String newFilePath = '${appDocumentsDirectory.path}/$newFileName';
          // await File(filePath).rename(newFilePath);

          // print("File renamed to: $newFilePath");

          var bytes = File(filePath).readAsBytesSync();
          var excel = Excel.decodeBytes(bytes);

          // Get the first sheet
          var sheet = excel.tables.keys.first;
          var table = excel.tables[sheet];

          // Iterate through rows starting from the 5th row
          for (var row in table.rows.skip(4)) {
            String prodName = row[0].toString();
            int prodMinQty = _parseInteger(row[17].toString());
            int prodMaxQty = _parseMaxQty(row[19]);
            int prodQty = _parseInteger(row[18].toString());
            int week1Qty = _parseInteger(row[22].toString());
            int week2Qty = _parseInteger(row[23].toString());
            int week3Qty = _parseInteger(row[24].toString());
            int week4Qty = _parseInteger(row[25].toString());
            var item = Product(
              prodName: prodName,
              prodMinQty: prodMinQty,
              prodMaxQty: prodMaxQty,
              prodQty: prodQty,
              week1Qty: week1Qty,
              week2Qty: week2Qty,
              week3Qty: week3Qty,
              week4Qty: week4Qty,
            );

            print(item.prodQty);

            _sunProducts.add(item);
          }
        } else {
          // Unsupported file type
          print("Unsupported file type: $fileName");
          // Show error message to user
          showErrorDialog("Unsupported file type: $fileName");
        }
      }
    } else {
      // User canceled the picker
      print("User canceled file picker");
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: DefaultTabController(
            length: 2,
            child: new Scaffold(
              key: _sKey,
              appBar: new AppBar(
                backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
                leading: new IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      return selectedProductList.length > 0
                          ? showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  // contentPadding: EdgeInsets.all(0.0),
                                  title: new Text("Alert!!"),
                                  content: new Text(
                                      "You have some items in your cart. Do you want to stay on the page or discard the changes?"),
                                  actions: [
                                    TextButton(
                                      // FlatButton widget is used to make a text to work like a button
                                      //textColor: Colors.black,
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      }, // function used to perform after pressing the button
                                      child: Text('Go Back'),
                                    ),
                                    TextButton(
                                      //textColor: Colors.black,
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text('Stay'),
                                    ),
                                  ],
                                );
                              })
                          : Navigator.pop(context);
                      //
                    }),
                title: new Text(
                  "Products",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.0,
                      fontWeight: FontWeight.w600),
                ),
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 2.0),
                    child: IconButton(
                      icon: Icon(Icons.download_rounded),
                      onPressed: () {
                        pdfGenerator();
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: PopupMenuButton(
                      // initialValue: 1,
                      onSelected: (int value) async {
                        if (widget.data.name == "SUN-NEW") {
                          await pickAndProcessFile();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductForm(widget.data.name, false),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) {
                        String itemText = "Add New Product";

                        // Conditionally change the text based on widget.data.name
                        if (widget.data.name == "SUN-NEW") {
                          itemText = "Upload Excel File"; // Change text here
                        }

                        return [
                          PopupMenuItem(
                            value: 1,
                            child: Text(itemText),
                          ),
                        ];
                      },
                    ),
                  ),
                ],
                //backgroundColor: Colors.blueAccent,
                bottom: TabBar(
                  tabs: [
                    Tab(
                        child: Text(
                      "All",
                    )),
                    Tab(
                        child: Text(
                      "Selected",
                    )),
                  ],
                  indicatorColor: Colors.white,
                ),
              ),
              body: TabBarView(
                children: [
                  Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: TextField(
                          keyboardType: TextInputType.text,
                          controller: _search,
                          decoration: new InputDecoration(
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: (search != "")
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        FocusScope.of(context).unfocus();
                                        WidgetsBinding.instance
                                            .addPostFrameCallback(
                                                (_) => _search.clear());
                                        search = "";
                                      });
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                            labelText: "",
                            // fillColor: Colors.black,
                            border: new OutlineInputBorder(
                              borderRadius: new BorderRadius.circular(15.0),
                              borderSide:
                                  new BorderSide(color: Colors.red, width: 5.0),
                            ),
                          ),
                          onChanged: (text) {
                            setState(() {
                              search = _search.text.toUpperCase();
                              _scroll.jumpTo(0);
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection("AllProducts")
                              .where("compCode", isEqualTo: widget.data.name)
                              .orderBy("prodName")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            } else {
                              return ListView.builder(
                                controller: _scroll,
                                itemCount: snapshot.data.docs.length,
                                itemBuilder: (context, index) {
                                  List rev = snapshot.data.docs.toList();
                                  ProductData prod = ProductData();
                                  prod.name = rev[index]['prodName'];
                                  prod.pack = rev[index]['prodPack'];
                                  // if(prod.name.substring(0, search.length) == search){
                                  if (widget.data.name == "ABT INDIA") {
                                    prod.division = rev[index]['prodDivision'];
                                  } else {
                                    prod.division = null;
                                  }
                                  var sample =
                                      selectedProductList.containsKey(prod.name)
                                          ? "Modify"
                                          : "Add";
                                  var color =
                                      selectedProductList.containsKey(prod.name)
                                          ? Colors.white
                                          : Colors.blueGrey;
                                  var elevation =
                                      selectedProductList.containsKey(prod.name)
                                          ? 0.0
                                          : 8.0;
                                  return Column(
                                    children: <Widget>[
                                      (prod.name.length >= search.length &&
                                              prod.name.substring(
                                                      0, search.length) ==
                                                  search)
                                          ? ListTile(
                                              title: Text(
                                                '${rev[index]['prodName']}',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '${rev[index]['prodPack']}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                ),
                                              ),
                                              onLongPress: () {
                                                return showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) =>
                                                          SimpleDialog(
                                                    title: Text(
                                                      '${rev[index]['prodName']}',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          fontSize: 25),
                                                    ),
                                                    children: <Widget>[
                                                      SimpleDialogOption(
                                                        child: Text(
                                                          "Delete Product",
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              fontSize: 23),
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(context,
                                                                  rootNavigator:
                                                                      true)
                                                              .pop();
                                                          FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  "AllProducts")
                                                              .doc(
                                                                  rev[index].id)
                                                              .delete()
                                                              .whenComplete(
                                                                  () {});
                                                        },
                                                      ),
                                                      Divider(
                                                        height: 1,
                                                      ),
                                                      SimpleDialogOption(
                                                        child: Text(
                                                          "Modify Details",
                                                          style: TextStyle(
                                                              fontSize: 23),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(context,
                                                                  rootNavigator:
                                                                      true)
                                                              .pop();
                                                          ProductData dataa =
                                                              ProductData(
                                                                  name: rev[
                                                                          index]
                                                                      [
                                                                      'prodName'],
                                                                  pack: rev[
                                                                          index]
                                                                      [
                                                                      'prodPack'],
                                                                  division: rev[
                                                                          index]
                                                                      [
                                                                      'prodDivision']);
                                                          //Navigator.of(context).pop();
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder: (context) => ProductUpdateForm(
                                                                      dataa,
                                                                      rev[index]
                                                                          .id,
                                                                      widget
                                                                          .data
                                                                          .name)));
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              trailing: new Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        elevation: elevation,
                                                        primary: color,
                                                      ),
                                                      child: Text(
                                                        sample,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.black),
                                                      ),
                                                      onPressed: () {
                                                        TextEditingController
                                                            _name =
                                                            TextEditingController(
                                                                text: rev[index]
                                                                    [
                                                                    'prodName']);
                                                        TextEditingController
                                                            _pack =
                                                            TextEditingController(
                                                                text: rev[index]
                                                                    [
                                                                    'prodPack']);
                                                        FocusNode qtyFocusNode =
                                                            new FocusNode();
                                                        bool _validate = false;
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            // FocusNode inputOne = FocusNode();
                                                            return AlertDialog(
                                                              // contentPadding: EdgeInsets.all(0.0),
                                                              title: new Text(
                                                                  '${rev[index]['prodName']}'),

                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: <
                                                                    Widget>[
                                                                  TextField(
                                                                    //autofocus: true,
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .text,
                                                                    controller:
                                                                        _name,
                                                                    decoration:
                                                                        new InputDecoration(
                                                                      contentPadding: const EdgeInsets
                                                                              .symmetric(
                                                                          vertical:
                                                                              15,
                                                                          horizontal:
                                                                              20),
                                                                      labelText:
                                                                          "Name",
                                                                      fillColor:
                                                                          Colors
                                                                              .black,
                                                                      border:
                                                                          new OutlineInputBorder(
                                                                        borderRadius:
                                                                            new BorderRadius.circular(15.0),
                                                                        borderSide:
                                                                            new BorderSide(),
                                                                      ),
                                                                    ),
                                                                    onChanged:
                                                                        (text) {
                                                                      prod.name =
                                                                          _name
                                                                              .text;
                                                                    },
                                                                    onSubmitted:
                                                                        (text) {
                                                                      FocusScope.of(
                                                                              context)
                                                                          .requestFocus(
                                                                              qtyFocusNode);
                                                                    },

                                                                    //prod.qty = _textFieldController.text
                                                                  ),
                                                                  Padding(
                                                                    padding: EdgeInsets
                                                                        .only(
                                                                            top:
                                                                                8),
                                                                    child:
                                                                        TextField(
                                                                      // autofocus: true,
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .text,
                                                                      controller:
                                                                          _pack,
                                                                      decoration:
                                                                          new InputDecoration(
                                                                        contentPadding: const EdgeInsets.symmetric(
                                                                            vertical:
                                                                                15,
                                                                            horizontal:
                                                                                20),
                                                                        labelText:
                                                                            "Pack",
                                                                        fillColor:
                                                                            Colors.black,
                                                                        border:
                                                                            new OutlineInputBorder(
                                                                          borderRadius:
                                                                              new BorderRadius.circular(15.0),
                                                                          borderSide:
                                                                              new BorderSide(),
                                                                        ),
                                                                      ),
                                                                      onChanged:
                                                                          (text) {
                                                                        prod.pack =
                                                                            _pack.text;
                                                                      },
                                                                      onSubmitted:
                                                                          (text) {
                                                                        FocusScope.of(context)
                                                                            .requestFocus(qtyFocusNode);
                                                                      },

                                                                      //prod.qty = _textFieldController.text
                                                                    ),
                                                                  ),
                                                                  Padding(
                                                                      padding: EdgeInsets.only(
                                                                          top:
                                                                              20),
                                                                      child:
                                                                          TextField(
                                                                        focusNode:
                                                                            qtyFocusNode,
                                                                        autofocus:
                                                                            true,
                                                                        keyboardType:
                                                                            TextInputType.text,
                                                                        controller:
                                                                            _textFieldController,
                                                                        decoration:
                                                                            new InputDecoration(
                                                                          contentPadding: const EdgeInsets.symmetric(
                                                                              vertical: 15,
                                                                              horizontal: 20),
                                                                          labelText:
                                                                              "Quantity",
                                                                          errorText: _validate
                                                                              ? "*Required"
                                                                              : null,
                                                                          fillColor:
                                                                              Colors.black,
                                                                          border:
                                                                              new OutlineInputBorder(
                                                                            borderRadius:
                                                                                new BorderRadius.circular(15.0),
                                                                            borderSide:
                                                                                new BorderSide(),
                                                                          ),
                                                                        ),
                                                                        onSubmitted:
                                                                            (text) {
                                                                          if (_textFieldController.text ==
                                                                              "") {
                                                                            setState(() {
                                                                              _validate = true;
                                                                            });
                                                                          } else {
                                                                            setState(() {
                                                                              _validate = false;
                                                                            });
                                                                            FirebaseFirestore.instance.collection("AllProducts").doc(rev[index].id).update({
                                                                              "prodName": _name.text,
                                                                              "prodPack": _pack.text
                                                                            });
                                                                            prod.qty =
                                                                                _textFieldController.text;
                                                                            addToMap(prod);
                                                                            Navigator.of(context).pop();
                                                                            _textFieldController.clear();
                                                                          }
                                                                        },

                                                                        //prod.qty = _textFieldController.text
                                                                      )),
                                                                ],
                                                              ),

                                                              actions: <Widget>[
                                                                new TextButton(
                                                                  child: new Text(
                                                                      "Close"),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    _textFieldController
                                                                        .clear();
                                                                  },
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      })
                                                ],
                                              ),
                                            )
                                          : Container(
                                              width: 0,
                                              height: 0,
                                              color: Colors.white,
                                            ),
                                      (prod.name.length >= search.length &&
                                              prod.name.substring(
                                                      0, search.length) ==
                                                  search)
                                          ? Divider(
                                              height: 1.0,
                                            )
                                          : Container(
                                              width: 0,
                                              height: 0,
                                              color: Colors.white,
                                            )
                                    ],
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Column(children: <Widget>[
                    Expanded(
                        child: SizedBox(
                            height: 600,
                            child: ListView.builder(
                              itemCount: testList.length,
                              itemBuilder: (context, index) {
                                // return Dismissible(
                                //   key: Key(testList[index]),
                                //   dragStartBehavior: DragStartBehavior.down,
                                //   direction: DismissDirection.endToStart,
                                //   secondaryBackground: Icon(Icons.delete_forever),
                                //   background: Container(color: Colors.grey[200],),
                                //   onDismissed: (left) {
                                //     setState(() {
                                //       selectedProductList.remove(testList[index]);
                                //       testList.remove(testList[index]);
                                //     });},
                                return Column(
                                  children: <Widget>[
                                    ListTile(
                                        title: Text(
                                          '${testList[index]}',
                                          style: TextStyle(
                                            fontSize: 22,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            pressedButton(testList[index]),
                                            IconButton(
                                              icon: Icon(Icons.delete),
                                              onPressed: () {
                                                setState(() {
                                                  selectedProductList
                                                      .remove(testList[index]);
                                                  testList
                                                      .remove(testList[index]);
                                                });
                                              },
                                            )
                                          ],
                                        )),
                                    Divider(
                                      height: 1.0,
                                    )
                                  ],
                                );
                              },
                            )))
                  ])
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  if (widget.data.name == "MANKIND-MAIN") {
                    excelBuild();
                  } else {
                    TextEditingController _email =
                        TextEditingController(text: widget.data.email);
                    TextEditingController _cc =
                        TextEditingController(text: widget.data.cc);
                    TextEditingController _subject =
                        TextEditingController(text: widget.subjectBody);
                    TextEditingController _message =
                        TextEditingController(text: widget.emailBody);
                    widget.receiver = widget.data.email;
                    showDialog(
                        context: context,
                        builder: (_) => Container(
                            height: 10.0,
                            child: Padding(
                              padding: EdgeInsets.only(top: 70),
                              child: Column(
                                  // Aligns the container to center
                                  children: <Widget>[
                                    Container(
                                        //width: 400.0,
                                        height: 515.0,
                                        child: Form(
                                            key: _formKey,
                                            child: CardSettings(
                                              children: <CardSettingsSection>[
                                                CardSettingsSection(
                                                    header: CardSettingsHeader(
                                                      label: 'Email Details',
                                                      color: Color.fromRGBO(
                                                          58, 66, 86, 1.0),
                                                    ),
                                                    children: <
                                                        CardSettingsWidget>[
                                                      CardSettingsEmail(
                                                        controller: _email,
                                                        requiredIndicator:
                                                            Text("*"),
                                                        //autovalidate: true,
                                                        maxLength: 50,
                                                        icon: Icon(
                                                          Icons.mail,
                                                          color: Colors.grey,
                                                        ),
                                                        label: "Receiver",
                                                        //initialValue: widget.data.email,
                                                        onChanged: (value) => {
                                                          widget.receiver =
                                                              _email.text
                                                        },
                                                      ),
                                                      CardSettingsText(
                                                        maxLength: 100,
                                                        controller: _cc,
                                                        icon: Icon(Icons.mail,
                                                            color: Colors.grey),
                                                        label: 'CC/BCC',
                                                      ),
                                                      CardSettingsText(
                                                        contentAlign:
                                                            TextAlign.left,
                                                        maxLength: 100,
                                                        icon: Icon(
                                                            Icons.textsms,
                                                            color: Colors.grey),
                                                        label: 'Subject',
                                                        controller: _subject,
                                                      ),
                                                      CardSettingsParagraph(
                                                        icon: Icon(
                                                            Icons.message,
                                                            color: Colors.grey),
                                                        label: 'Message',
                                                        controller: _message,
                                                        numberOfLines: 6,
                                                        initialValue:
                                                            widget.emailBody,
                                                      ),
                                                      CardSettingsButton(
                                                        label: "Send Now",
                                                        onPressed: () async {
                                                          Navigator.pop(
                                                              context);
                                                          try {
                                                            final result =
                                                                await InternetAddress
                                                                    .lookup(
                                                                        'google.com');
                                                            if (result
                                                                    .isNotEmpty &&
                                                                result[0]
                                                                    .rawAddress
                                                                    .isNotEmpty) {
                                                              if (widget
                                                                      .check ==
                                                                  true) {
                                                                final db =
                                                                    FirebaseFirestore
                                                                        .instance;
                                                                await db
                                                                    .collection(
                                                                        'Orders')
                                                                    .doc(widget
                                                                        .docID)
                                                                    .delete();
                                                              }
                                                              setState(() {
                                                                widget.receiver =
                                                                    _email.text;
                                                                widget.test =
                                                                    _cc.text;
                                                                widget.subjectBody =
                                                                    _subject
                                                                        .text;
                                                                widget.emailBody =
                                                                    _message
                                                                        .text;
                                                              });
                                                              progress = false;
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                barrierDismissible:
                                                                    false,
                                                                builder:
                                                                    (BuildContext
                                                                        context) {
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
                                                                                "Loading",
                                                                                style: TextStyle(fontSize: 16),
                                                                              ),
                                                                            )
                                                                          ],
                                                                        )),
                                                                  );
                                                                },
                                                              );

                                                              mailing()
                                                                  .whenComplete(
                                                                      () {
                                                                Navigator.pop(
                                                                    context);
                                                                _displaySnackBar(
                                                                    action);
                                                              });
                                                            }
                                                          } on SocketException catch (_) {
                                                            _displaySnackBar(
                                                                "Please check your internet connection");
                                                          }
                                                        },
                                                      ),
                                                      CardSettingsButton(
                                                        label: "Send Later",
                                                        onPressed: () async {
                                                          Navigator.pop(
                                                              context);
                                                          if (widget.check ==
                                                              true) {
                                                            final db =
                                                                FirebaseFirestore
                                                                    .instance;
                                                            await db
                                                                .collection(
                                                                    'Orders')
                                                                .doc(widget
                                                                    .docID)
                                                                .delete();
                                                          }
                                                          widget
                                                              .sendDataToFirestore(
                                                                  false);
                                                        },
                                                      )
                                                    ])
                                              ],
                                            ))),
                                  ]),
                            )));
                  }
                },
                child: Icon(Icons.mail),
                backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
              ),
            )));
  }
}
