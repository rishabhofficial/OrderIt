import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:startup_namer/model.dart';

import './form.dart';
import 'LocalPartyReport.dart';

bool progress;

class Key1 {
  String name;
  String batch;
}

class Order {
  double amount;
  bool isSettled;
  DateTime timestamp;
  String partyName;
  String invoiceNumber;
  Order(
      {this.timestamp,
      this.amount,
      this.partyName,
      this.invoiceNumber,
      this.isSettled});

  toJson() {
    return {
      "amount": amount,
      "partyName": partyName,
      "invoiceNumber": invoiceNumber,
      "isSettled": isSettled,
      "timestamp": timestamp
    };
  }
}

Map<dynamic, ProductData> selectedProductList = new Map();
List<dynamic> testList = new List();
Map<String, String> batch = new Map();
String action;

class AllProductPage extends StatefulWidget {
  final PartyData data;
  final String docID;
  final bool check;
  final Timestamp invoiceDate;
  final double invoiceAmount;
  AllProductPage(
      {this.data,
      this.docID,
      this.check,
      this.invoiceDate,
      this.invoiceAmount});

  List<ProductData> prodList;

  int x = 1;
  Future sendDataToFirestore(bool check1) async {
    DateTime now = new DateTime.now();
    DateTime timestamp1 = check1
        ? invoiceDate.toDate()
        : new DateTime(now.year, now.month, now.day, now.hour, now.minute,
            now.second, now.millisecond);
    DateTime timestamp2 = new DateTime(now.year, now.month, now.day, now.hour,
        now.minute, now.second, now.millisecond);
    String partyName = data.name;
    bool isSettled = false;
    double amount = 0;
    for (int i = 0; i < selectedProductList.length; i++) {
      amount += selectedProductList[testList[i]].amount;
    }

    if (check1 == true) {
      final db = FirebaseFirestore.instance;
      await db.collection('Expiry').doc(docID).delete();
    }
    final CollectionReference postsRef =
        FirebaseFirestore.instance.collection('/Expiry');

    Order order = new Order();
    order.partyName = partyName;
    order.amount = amount;
    order.isSettled = isSettled;
    order.timestamp = timestamp1;
    Map<String, dynamic> orderData = order.toJson();
    await postsRef.doc(timestamp2.toString()).set(orderData);

    for (int i = 0; i < selectedProductList.length; i++) {
      ProductData product = new ProductData();
      product.name = selectedProductList[testList[i]].name;
      product.pack = selectedProductList[testList[i]].pack;
      product.qty = selectedProductList[testList[i]].qty;
      product.compCode = selectedProductList[testList[i]].compCode;
      product.batchNumber = selectedProductList[testList[i]].batchNumber;
      product.division = selectedProductList[testList[i]].division;
      product.expiryDate = selectedProductList[testList[i]].expiryDate;
      product.mrp = selectedProductList[testList[i]].mrp;
      product.deal1 = selectedProductList[testList[i]].deal1;
      product.deal2 = selectedProductList[testList[i]].deal2;
      product.amount = selectedProductList[testList[i]].amount;

      Map<String, dynamic> prodData = product.toJson();

      FirebaseFirestore.instance
          .collection('Expiry')
          .doc(timestamp2.toString())
          .collection(order.partyName)
          .doc()
          .set(prodData)
          .whenComplete(() {
        if (i == selectedProductList.length - 1) {
          return true;
        }
      });
    }
  }

  @override
  _AllProductPageState createState() => new _AllProductPageState();
}

class _AllProductPageState extends State<AllProductPage> {
  _displaySnackBar(String action1) {
    final snackbar = SnackBar(content: Text(action1));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  void fillData(BuildContext context) {
    FirebaseFirestore.instance
        .collection('Expiry')
        .doc(widget.docID)
        .collection(widget.data.name)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        ProductData dataa = ProductData();
        dataa.name = doc['prodName'];
        dataa.pack = doc['prodPack'];
        dataa.qty = doc['prodQty'];
        dataa.division = doc['prodDivision'];
        dataa.expiryDate = doc['prodExpiryDate'];
        dataa.deal1 = doc['prodDeal1'];
        dataa.deal2 = doc['prodDeal2'];
        dataa.batchNumber = doc['prodBatchNumber'];
        dataa.compCode = doc['compCode'];
        dataa.mrp = doc['prodMrp'];
        dataa.amount = doc['amount'];
        Key1 k = new Key1();
        k.name = doc['prodName'];
        k.batch = doc['prodBatchNumber'];
        testList.add(k);
        batch[dataa.batchNumber] = dataa.name;
        selectedProductList[k] = dataa;
        setState(() {});
      });
    });
  }

  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    selectedProductList.clear();
    testList.clear();
    batch.clear();
    if (widget.check == true) {
      fillData(context);
    }
    super.initState();
  }

  bool addToMap(ProductData prod) {
    bool test = true;
    setState(() {
      Key1 k = new Key1();
      print(selectedProductList);
      k.name = prod.name;
      k.batch = prod.batchNumber;

      if (batch.containsKey(k.batch) && batch[k.batch] == k.name) {
        print("The product with this batch number already exists in the list");
        test = false;
      } else {
        selectedProductList[k] = prod;
        batch[k.batch] = k.name;
        testList.add(k);
      }
    });
    return test;
  }

  TextEditingController _textFieldController = TextEditingController();
  TextEditingController _search = TextEditingController();
  ScrollController _scroll = new ScrollController();

  final _sKey = GlobalKey<ScaffoldMessengerState>();

  String search = "";

  bool isProdSearch = false;

  @override
  Widget build(BuildContext context) {
    Stream _prodStream = FirebaseFirestore.instance
        .collection("AllProducts")
        .where("prodName", isGreaterThanOrEqualTo: search)
        .limit(15)
        .snapshots();
    Stream _batchStream = FirebaseFirestore.instance
        .collection("BATCH NUMBER")
        .where("prodBatchNumber", isGreaterThanOrEqualTo: search)
        .limit(10)
        .snapshots();

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
                    padding: const EdgeInsets.only(right: 5.0),
                    child: IconButton(
                      icon: Icon(Icons.picture_as_pdf),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LocalPartyReport(
                                    partyName: widget.data.name,
                                    docID: widget.docID,
                                    defaultDisc: widget.data.defaultDiscount,
                                    invoiceDate: widget.invoiceDate,
                                    invoiceAmount: widget.invoiceAmount)));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: PopupMenuButton(
                        // initialValue: 1,
                        onSelected: (int) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ProductForm(widget.data.name, true)));
                        },
                        itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 1,
                                child: Text("Add New Product"),
                              )
                            ]),
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
                  Scaffold(
                    body: Column(
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
                                  : IconButton(
                                      icon: Icon(Icons.arrow_drop_down),
                                      onPressed: () {
                                        // open a dropDown list with two options
                                        // Seach Product and Search Batch Number
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text("Search By"),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  ListTile(
                                                    title: Text("Product Name"),
                                                    onTap: () {
                                                      setState(() {
                                                        isProdSearch = true;
                                                        Navigator.of(context)
                                                            .pop();
                                                      });
                                                    },
                                                  ),
                                                  ListTile(
                                                    title: Text("Batch Number"),
                                                    onTap: () {
                                                      setState(() {
                                                        isProdSearch = false;
                                                        Navigator.of(context)
                                                            .pop();
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      }),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 20),
                              labelText: "",
                              // fillColor: Colors.black,
                              border: new OutlineInputBorder(
                                borderRadius: new BorderRadius.circular(15.0),
                                borderSide: new BorderSide(
                                    color: Colors.red, width: 5.0),
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
                            stream: (isProdSearch) ? _prodStream : _batchStream,
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
                                    // check if prodBatchNumber is in the document
                                    String _searchIdentifier = isProdSearch
                                        ? prod.name
                                        : (rev[index]
                                                .data()
                                                .toString()
                                                .contains("prodBatchNumber")
                                            ? rev[index]['prodBatchNumber']
                                            : null);

                                    if (_searchIdentifier == null) {
                                      return Container(
                                        width: 0,
                                        height: 0,
                                      );
                                    }

                                    var sample = "Add";
                                    var color = Colors.blueGrey;
                                    var elevation = 8.0;
                                    return Column(
                                      children: <Widget>[
                                        (_searchIdentifier.length >=
                                                    search.length &&
                                                _searchIdentifier.substring(
                                                        0, search.length) ==
                                                    search)
                                            ? ListTile(
                                                title: isProdSearch
                                                    ? Text(
                                                        '${rev[index]['prodName']}',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                        ),
                                                      )
                                                    : Text(
                                                        '${rev[index]['prodBatchNumber']}',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                subtitle: (!isProdSearch)
                                                    ? Row(children: <Widget>[
                                                        Text(
                                                          '${rev[index]['prodName']} | ',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${rev[index]['prodPack']}',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ])
                                                    : Text(
                                                        'Pack: ${rev[index]['prodPack']}',
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                onLongPress: () {
                                                  if (!isProdSearch) {
                                                    return null;
                                                  }
                                                  return showDialog(
                                                    context: context,
                                                    builder: (BuildContext
                                                            context) =>
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
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                                fontSize: 23),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context,
                                                                    rootNavigator:
                                                                        true)
                                                                .pop();
                                                            FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    "AllProducts")
                                                                .doc(rev[index]
                                                                    .id)
                                                                .delete()
                                                                .whenComplete(
                                                                    () {
                                                              setState(() {});
                                                            });
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
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context,
                                                                    rootNavigator:
                                                                        true)
                                                                .pop();
                                                            ProductData dataa = ProductData(
                                                                name: rev[index]
                                                                    [
                                                                    'prodName'],
                                                                pack: rev[index]
                                                                    [
                                                                    'prodPack'],
                                                                division: rev[
                                                                        index][
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
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                },
                                                trailing: new Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
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
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                        onPressed: () {
                                                          TextEditingController
                                                              _name =
                                                              TextEditingController(
                                                                  text: rev[
                                                                          index]
                                                                      [
                                                                      'prodName']);
                                                          TextEditingController
                                                              _pack =
                                                              TextEditingController(
                                                                  text: rev[
                                                                          index]
                                                                      [
                                                                      'prodPack']);
                                                          TextEditingController
                                                              _mrp =
                                                              TextEditingController(
                                                                  text: isProdSearch
                                                                      ? null
                                                                      : rev[index]
                                                                          [
                                                                          'prodMrp']);
                                                          TextEditingController
                                                              _expiry =
                                                              TextEditingController(
                                                                  text: isProdSearch
                                                                      ? null
                                                                      : rev[index]
                                                                          [
                                                                          'prodExpiryDate']);
                                                          TextEditingController
                                                              _batch =
                                                              TextEditingController(
                                                                  text: isProdSearch
                                                                      ? null
                                                                      : rev[index]
                                                                          [
                                                                          'prodBatchNumber']);
                                                          TextEditingController
                                                              _qty =
                                                              TextEditingController();
                                                          TextEditingController
                                                              _deal1 =
                                                              TextEditingController(
                                                                  text: isProdSearch
                                                                      ? null
                                                                      : rev[index]
                                                                              [
                                                                              'prodDeal1']
                                                                          .toString());
                                                          TextEditingController
                                                              _deal2 =
                                                              TextEditingController(
                                                                  text: isProdSearch
                                                                      ? null
                                                                      : rev[index]
                                                                              [
                                                                              'prodDeal2']
                                                                          .toString());
                                                          FocusNode
                                                              qtyFocusNode =
                                                              new FocusNode();
                                                          FocusNode pack =
                                                              new FocusNode();
                                                          FocusNode mrp =
                                                              new FocusNode();
                                                          FocusNode expiry =
                                                              new FocusNode();
                                                          FocusNode batch =
                                                              new FocusNode();
                                                          FocusNode deal1 =
                                                              new FocusNode();
                                                          FocusNode deal2 =
                                                              new FocusNode();
                                                          bool _validate =
                                                              false;

                                                          if (!isProdSearch) {
                                                            prod.name = rev[
                                                                    index]
                                                                ['prodName'];
                                                            prod.pack = rev[
                                                                    index]
                                                                ['prodPack'];

                                                            // convert the string to double
                                                            prod.mrp = double
                                                                .parse(rev[index]
                                                                        [
                                                                        'prodMrp']
                                                                    .toString());

                                                            prod.expiryDate = rev[
                                                                    index][
                                                                'prodExpiryDate'];
                                                            prod.batchNumber = rev[
                                                                    index][
                                                                'prodBatchNumber'];
                                                            // convert the string to int
                                                            prod.deal1 = rev[
                                                                    index]
                                                                ['prodDeal1'];
                                                            prod.deal2 = rev[
                                                                    index]
                                                                ['prodDeal2'];
                                                          }
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              prod.compCode = rev[
                                                                      index]
                                                                  ['compCode'];
                                                              return AlertDialog(
                                                                // contentPadding: EdgeInsets.all(0.0),
                                                                title: new Text(
                                                                    '${rev[index]['prodName']}'),
                                                                content:
                                                                    SingleChildScrollView(
                                                                        child:
                                                                            Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: <
                                                                      Widget>[
                                                                    TextField(
                                                                      keyboardType:
                                                                          TextInputType
                                                                              .text,
                                                                      controller:
                                                                          _name,
                                                                      decoration:
                                                                          new InputDecoration(
                                                                        contentPadding: const EdgeInsets.symmetric(
                                                                            vertical:
                                                                                15,
                                                                            horizontal:
                                                                                20),
                                                                        labelText:
                                                                            "Name",
                                                                        //errorText: _validate ? "*Required" : null,
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
                                                                        prod.name =
                                                                            _name.text;
                                                                      },
                                                                      onSubmitted:
                                                                          (text) {
                                                                        FocusScope.of(context)
                                                                            .requestFocus(pack);
                                                                      },
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets
                                                                          .only(
                                                                              top: 8),
                                                                      child:
                                                                          TextField(
                                                                        focusNode:
                                                                            pack,
                                                                        keyboardType:
                                                                            TextInputType.text,
                                                                        controller:
                                                                            _pack,
                                                                        decoration:
                                                                            new InputDecoration(
                                                                          contentPadding: const EdgeInsets.symmetric(
                                                                              vertical: 15,
                                                                              horizontal: 20),
                                                                          labelText:
                                                                              "Pack",
                                                                          //errorText: _validate ? "*Required" : null,
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
                                                                              .requestFocus(mrp);
                                                                        },

                                                                        //prod.qty = _textFieldController.text
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets
                                                                          .only(
                                                                              top: 8),
                                                                      child:
                                                                          TextField(
                                                                        autofocus:
                                                                            isProdSearch,
                                                                        focusNode:
                                                                            mrp,
                                                                        // autofocus: true,
                                                                        keyboardType:
                                                                            TextInputType.number,
                                                                        controller:
                                                                            _mrp,
                                                                        decoration:
                                                                            new InputDecoration(
                                                                          contentPadding: const EdgeInsets.symmetric(
                                                                              vertical: 15,
                                                                              horizontal: 20),
                                                                          labelText:
                                                                              "MRP",

                                                                          //errorText: _validate ? "*Required" : null,
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
                                                                          prod.mrp =
                                                                              double.parse(_mrp.text);
                                                                        },
                                                                        onSubmitted:
                                                                            (text) {
                                                                          FocusScope.of(context)
                                                                              .requestFocus(expiry);
                                                                        },
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets
                                                                          .only(
                                                                              top: 8),
                                                                      child:
                                                                          TextField(
                                                                        focusNode:
                                                                            expiry,
                                                                        keyboardType:
                                                                            TextInputType.number,
                                                                        controller:
                                                                            _expiry,
                                                                        decoration:
                                                                            new InputDecoration(
                                                                          contentPadding: const EdgeInsets.symmetric(
                                                                              vertical: 15,
                                                                              horizontal: 20),
                                                                          labelText:
                                                                              "Expiry Date",
                                                                          //errorText: _validate ? "*Required" : null,
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
                                                                          prod.expiryDate =
                                                                              _expiry.text;
                                                                        },
                                                                        onSubmitted:
                                                                            (text) {
                                                                          FocusScope.of(context)
                                                                              .requestFocus(batch);
                                                                        },

                                                                        //prod.qty = _textFieldController.text
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets
                                                                          .only(
                                                                              top: 8),
                                                                      child:
                                                                          TextField(
                                                                        focusNode:
                                                                            batch,
                                                                        // autofocus: true,
                                                                        keyboardType:
                                                                            TextInputType.text,
                                                                        controller:
                                                                            _batch,
                                                                        decoration:
                                                                            new InputDecoration(
                                                                          contentPadding: const EdgeInsets.symmetric(
                                                                              vertical: 15,
                                                                              horizontal: 20),
                                                                          labelText:
                                                                              "Batch Number",
                                                                          // errorText: _validate ? "*Required" : null,
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
                                                                          prod.batchNumber = _batch
                                                                              .text
                                                                              .toUpperCase();
                                                                        },
                                                                        onSubmitted:
                                                                            (text) {
                                                                          FocusScope.of(context)
                                                                              .requestFocus(deal1);
                                                                        },

                                                                        //prod.qty = _textFieldController.text
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsets
                                                                          .only(
                                                                              top: 8),
                                                                      child:
                                                                          Row(
                                                                        children: <
                                                                            Widget>[
                                                                          Flexible(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.only(right: 4),
                                                                              child: TextField(
                                                                                // autofocus: true,
                                                                                focusNode: deal1,
                                                                                keyboardType: TextInputType.number,
                                                                                controller: _deal1,
                                                                                decoration: new InputDecoration(
                                                                                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                                                                  labelText: "Deal",
                                                                                  fillColor: Colors.black,
                                                                                  border: new OutlineInputBorder(
                                                                                    borderRadius: new BorderRadius.circular(15.0),
                                                                                    borderSide: new BorderSide(),
                                                                                  ),
                                                                                ),
                                                                                onChanged: (text) {
                                                                                  if (_deal1.text == null) {
                                                                                    prod.deal1 = 0;
                                                                                  } else
                                                                                    prod.deal1 = int.parse(_deal1.text);
                                                                                },
                                                                                onSubmitted: (text) {
                                                                                  FocusScope.of(context).requestFocus(deal2);
                                                                                },

                                                                                //prod.qty = _textFieldController.text
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Icon(Icons
                                                                              .add),
                                                                          Flexible(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.only(left: 4),
                                                                              child: TextField(
                                                                                focusNode: deal2,
                                                                                // autofocus: true,
                                                                                keyboardType: TextInputType.number,
                                                                                controller: _deal2,
                                                                                decoration: new InputDecoration(
                                                                                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                                                                  labelText: "Deal",
                                                                                  fillColor: Colors.black,
                                                                                  border: new OutlineInputBorder(
                                                                                    borderRadius: new BorderRadius.circular(15.0),
                                                                                    borderSide: new BorderSide(),
                                                                                  ),
                                                                                ),
                                                                                onChanged: (text) {
                                                                                  if (_deal2.text == null) {
                                                                                    prod.deal2 = 0;
                                                                                  } else
                                                                                    prod.deal2 = int.parse(_deal2.text);
                                                                                },
                                                                                onSubmitted: (text) {
                                                                                  FocusScope.of(context).requestFocus(qtyFocusNode);
                                                                                },

                                                                                //prod.qty = _textFieldController.text
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                        padding: EdgeInsets.only(
                                                                            top:
                                                                                8),
                                                                        child:
                                                                            TextField(
                                                                          autofocus:
                                                                              !isProdSearch,
                                                                          focusNode:
                                                                              qtyFocusNode,
                                                                          keyboardType:
                                                                              TextInputType.number,
                                                                          controller:
                                                                              _qty,
                                                                          decoration:
                                                                              new InputDecoration(
                                                                            contentPadding:
                                                                                const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                                                            labelText:
                                                                                "Quantity",
                                                                            errorText: _validate
                                                                                ? "*Required"
                                                                                : null,
                                                                            fillColor:
                                                                                Colors.black,
                                                                            border:
                                                                                new OutlineInputBorder(
                                                                              borderRadius: new BorderRadius.circular(15.0),
                                                                              borderSide: new BorderSide(),
                                                                            ),
                                                                          ),
                                                                          onSubmitted:
                                                                              (text) {
                                                                            if (_qty.text ==
                                                                                "") {
                                                                              setState(() {
                                                                                _validate = true;
                                                                              });
                                                                            } else {
                                                                              setState(() {
                                                                                _validate = false;
                                                                              });
                                                                              prod.qty = _qty.text;
                                                                              Navigator.of(context).pop();
                                                                              if (prod.deal1 != 0 && prod.deal2 != 0) {
                                                                                prod.amount = double.parse(prod.qty) * prod.mrp * (1 - (prod.deal2) / (prod.deal1 + prod.deal2));
                                                                                print(widget.data.defaultDiscount);
                                                                              } else {
                                                                                prod.amount = double.parse(prod.qty) * prod.mrp;
                                                                              }
                                                                              prod.amount = double.parse((prod.amount - (widget.data.defaultDiscount / 100) * prod.amount).toStringAsFixed(3));

                                                                              bool test = addToMap(prod);
                                                                              if (!test) {
                                                                                print("inside show");
                                                                                return showDialog(
                                                                                    context: context,
                                                                                    builder: (BuildContext context) {
                                                                                      return AlertDialog(title: Text(prod.name + " with batch number " + prod.batchNumber + " already exists."), actions: [
                                                                                        TextButton(
                                                                                          style: TextButton.styleFrom(
                                                                                            textStyle: const TextStyle(fontSize: 20),
                                                                                          ),
                                                                                          child: Text("OK"),
                                                                                          onPressed: () {
                                                                                            Navigator.of(context).pop();
                                                                                          },
                                                                                        )
                                                                                      ]);
                                                                                    });
                                                                              }
                                                                              _qty.clear();
                                                                              _batch.clear();
                                                                              _mrp.clear();
                                                                              _deal1.clear();
                                                                              _deal2.clear();
                                                                              _expiry.clear();
                                                                            }
                                                                          },
                                                                        )),
                                                                  ],
                                                                )),

                                                                actions: <
                                                                    Widget>[
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
                  ),
                  Scaffold(
                    body: Column(children: <Widget>[
                      Expanded(
                          child: SizedBox(
                              height: 600,
                              child: (testList.length == 0)
                                  ? Container(
                                      child: Center(
                                          child: Icon(
                                      Icons.add_shopping_cart,
                                      size: 150,
                                      color: Colors.grey,
                                    )))
                                  : ListView.builder(
                                      itemCount: testList.length,
                                      itemBuilder: (context, index) {
                                        return Dismissible(
                                          key: Key(index.toString()),
                                          direction:
                                              DismissDirection.endToStart,
                                          onDismissed: (direction) {
                                            setState(() {
                                              selectedProductList
                                                  .remove(testList[index]);
                                              testList.remove(testList[index]);
                                            });
                                          },
                                          background: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12.0),
                                            color: Colors.grey[400],
                                            alignment: Alignment.centerRight,
                                            child: Icon(
                                              Icons.delete_forever_rounded,
                                              size: 30,
                                            ),
                                          ),
                                          confirmDismiss: (DismissDirection
                                              direction) async {
                                            return await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text("Confirm"),
                                                  content: const Text(
                                                      "Are you sure you wish to delete this item?"),
                                                  actions: <Widget>[
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                        child: const Text(
                                                            "DELETE")),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context)
                                                              .pop(false),
                                                      child:
                                                          const Text("CANCEL"),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: Column(
                                            children: <Widget>[
                                              //   ListTile(title: Text('${selectedProductList[testList[index]].name}', style: TextStyle(
                                              //     fontSize: 22,
                                              //     ),),

                                              //      trailing: Row(
                                              //        mainAxisSize: MainAxisSize.min,
                                              //        children: <Widget>[
                                              //         // pressedButton(selectedProductList[testList[index]].name),
                                              //          IconButton(icon: Icon(Icons.delete), iconSize: 20 ,onPressed: () {
                                              //            setState(() {
                                              //               selectedProductList.remove(testList[index]);
                                              //               testList.remove(testList[index]);
                                              // });
                                              //          },)
                                              //        ],
                                              //      )
                                              //   ),
                                              Card(
                                                elevation: 10.0,
                                                margin:
                                                    new EdgeInsets.symmetric(
                                                        horizontal: 10.0,
                                                        vertical: 6.0),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color: Color.fromRGBO(
                                                          200, 200, 200, .4)),
                                                  child: ListTile(
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 8.0,
                                                              vertical: 10.0),
                                                      leading: Container(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  right: 2.0,
                                                                  top: 5),
                                                          decoration: new BoxDecoration(
                                                              border: new Border(
                                                                  right: new BorderSide(
                                                                      width:
                                                                          0.5,
                                                                      color: Colors
                                                                          .white24))),
                                                          child: IconButton(
                                                              icon: Icon(
                                                                  Icons.edit),
                                                              iconSize: 25,
                                                              onPressed: () {
                                                                TextEditingController
                                                                    _name =
                                                                    TextEditingController(
                                                                        text: selectedProductList[testList[index]]
                                                                            .name);
                                                                TextEditingController
                                                                    _pack =
                                                                    TextEditingController(
                                                                        text: selectedProductList[testList[index]]
                                                                            .pack);
                                                                TextEditingController
                                                                    _mrp =
                                                                    TextEditingController(
                                                                        text: selectedProductList[testList[index]]
                                                                            .mrp
                                                                            .toString());
                                                                TextEditingController
                                                                    _expiry =
                                                                    TextEditingController(
                                                                        text: selectedProductList[testList[index]]
                                                                            .expiryDate);
                                                                TextEditingController
                                                                    _batch =
                                                                    TextEditingController(
                                                                        text: selectedProductList[testList[index]]
                                                                            .batchNumber);
                                                                TextEditingController
                                                                    _qty =
                                                                    TextEditingController(
                                                                        text: selectedProductList[testList[index]]
                                                                            .qty);
                                                                TextEditingController
                                                                    _deal1 =
                                                                    TextEditingController(
                                                                        text: selectedProductList[testList[index]]
                                                                            .deal1
                                                                            .toString());
                                                                TextEditingController
                                                                    _deal2 =
                                                                    TextEditingController(
                                                                        text: selectedProductList[testList[index]]
                                                                            .deal2
                                                                            .toString());
                                                                FocusNode
                                                                    qtyFocusNode =
                                                                    new FocusNode();
                                                                FocusNode pack =
                                                                    new FocusNode();
                                                                FocusNode mrp =
                                                                    new FocusNode();
                                                                FocusNode
                                                                    expiry =
                                                                    new FocusNode();
                                                                FocusNode
                                                                    batch1 =
                                                                    new FocusNode();
                                                                FocusNode
                                                                    deal1 =
                                                                    new FocusNode();
                                                                FocusNode
                                                                    deal2 =
                                                                    new FocusNode();
                                                                bool _validate =
                                                                    false;
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) {
                                                                    // FocusNode inputOne = FocusNode();
                                                                    return AlertDialog(
                                                                      // contentPadding: EdgeInsets.all(0.0),
                                                                      title: new Text(
                                                                          '${selectedProductList[testList[index]].name}'),
                                                                      content:
                                                                          SingleChildScrollView(
                                                                              child: Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: <
                                                                            Widget>[
                                                                          Flexible(
                                                                            child: Padding(
                                                                                padding: EdgeInsets.only(top: 8),
                                                                                child: TextField(
                                                                                  autofocus: true,
                                                                                  keyboardType: TextInputType.text,
                                                                                  controller: _name,
                                                                                  decoration: new InputDecoration(
                                                                                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                                                                    labelText: "Name",
                                                                                    //errorText: _validate ? "*Required" : null,
                                                                                    fillColor: Colors.black,
                                                                                    border: new OutlineInputBorder(
                                                                                      borderRadius: new BorderRadius.circular(15.0),
                                                                                      borderSide: new BorderSide(),
                                                                                    ),
                                                                                  ),
                                                                                  onChanged: (text) {
                                                                                    selectedProductList[testList[index]].name = _name.text;
                                                                                  },
                                                                                  onSubmitted: (text) {
                                                                                    FocusScope.of(context).requestFocus(pack);
                                                                                  },
                                                                                )),
                                                                          ),
                                                                          Flexible(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.only(top: 8),
                                                                              child: TextField(
                                                                                focusNode: pack,
                                                                                keyboardType: TextInputType.text,
                                                                                controller: _pack,
                                                                                decoration: new InputDecoration(
                                                                                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                                                                  labelText: "Pack",
                                                                                  //errorText: _validate ? "*Required" : null,
                                                                                  fillColor: Colors.black,
                                                                                  border: new OutlineInputBorder(
                                                                                    borderRadius: new BorderRadius.circular(15.0),
                                                                                    borderSide: new BorderSide(),
                                                                                  ),
                                                                                ),
                                                                                onChanged: (text) {
                                                                                  selectedProductList[testList[index]].pack = _pack.text;
                                                                                },
                                                                                onSubmitted: (text) {
                                                                                  FocusScope.of(context).requestFocus(mrp);
                                                                                },

                                                                                //prod.qty = _textFieldController.text
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Flexible(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.only(top: 8),
                                                                              child: TextField(
                                                                                focusNode: mrp,
                                                                                // autofocus: true,
                                                                                keyboardType: TextInputType.number,
                                                                                controller: _mrp,
                                                                                decoration: new InputDecoration(
                                                                                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                                                                  labelText: "MRP",
                                                                                  //errorText: _validate ? "*Required" : null,
                                                                                  fillColor: Colors.black,
                                                                                  border: new OutlineInputBorder(
                                                                                    borderRadius: new BorderRadius.circular(15.0),
                                                                                    borderSide: new BorderSide(),
                                                                                  ),
                                                                                ),
                                                                                onChanged: (text) {
                                                                                  selectedProductList[testList[index]].mrp = double.parse(_mrp.text);
                                                                                },
                                                                                onSubmitted: (text) {
                                                                                  FocusScope.of(context).requestFocus(expiry);
                                                                                },
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Flexible(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.only(top: 8),
                                                                              child: TextField(
                                                                                focusNode: expiry,
                                                                                keyboardType: TextInputType.number,
                                                                                controller: _expiry,
                                                                                decoration: new InputDecoration(
                                                                                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                                                                  labelText: "Expiry Date",
                                                                                  //errorText: _validate ? "*Required" : null,
                                                                                  fillColor: Colors.black,
                                                                                  border: new OutlineInputBorder(
                                                                                    borderRadius: new BorderRadius.circular(15.0),
                                                                                    borderSide: new BorderSide(),
                                                                                  ),
                                                                                ),
                                                                                onChanged: (text) {
                                                                                  selectedProductList[testList[index]].expiryDate = _expiry.text;
                                                                                },
                                                                                onSubmitted: (text) {
                                                                                  FocusScope.of(context).requestFocus(batch1);
                                                                                },

                                                                                //prod.qty = _textFieldController.text
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Flexible(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.only(top: 8),
                                                                              child: TextField(
                                                                                focusNode: batch1,
                                                                                // autofocus: true,
                                                                                keyboardType: TextInputType.text,
                                                                                controller: _batch,
                                                                                decoration: new InputDecoration(
                                                                                  contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                                                                  labelText: "Batch Number",
                                                                                  //errorText: _validate ? "*Batch Number already used for this product" : null,
                                                                                  fillColor: Colors.black,
                                                                                  border: new OutlineInputBorder(
                                                                                    borderRadius: new BorderRadius.circular(15.0),
                                                                                    borderSide: new BorderSide(),
                                                                                  ),
                                                                                ),
                                                                                onChanged: (text) {
                                                                                  selectedProductList[testList[index]].batchNumber = _batch.text.toUpperCase();
                                                                                },
                                                                                onSubmitted: (text) {
                                                                                  FocusScope.of(context).requestFocus(deal1);
                                                                                },
                                                                                // onSubmitted: (text) {
                                                                                //   if (batch.containsKey(selectedProductList[testList[index]].batchNumber) && selectedProductList[testList[index]].name == batch[selectedProductList[testList[index]].batchNumber]){
                                                                                //     setState(() {
                                                                                //       _validate = true;
                                                                                //     });
                                                                                //   }
                                                                                //   else{
                                                                                //   setState(() {
                                                                                //     _validate = false;
                                                                                //   });}}

                                                                                //prod.qty = _textFieldController.text
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Flexible(
                                                                            child:
                                                                                Padding(
                                                                              padding: EdgeInsets.only(top: 8),
                                                                              child: Row(
                                                                                children: <Widget>[
                                                                                  Flexible(
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.only(right: 4),
                                                                                      child: TextField(
                                                                                        // autofocus: true,
                                                                                        focusNode: deal1,
                                                                                        keyboardType: TextInputType.number,
                                                                                        controller: _deal1,
                                                                                        decoration: new InputDecoration(
                                                                                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                                                                          labelText: "Deal",
                                                                                          fillColor: Colors.black,
                                                                                          border: new OutlineInputBorder(
                                                                                            borderRadius: new BorderRadius.circular(15.0),
                                                                                            borderSide: new BorderSide(),
                                                                                          ),
                                                                                        ),
                                                                                        onChanged: (text) {
                                                                                          if (_deal1.text == "") {
                                                                                            selectedProductList[testList[index]].deal1 = 0;
                                                                                          } else
                                                                                            selectedProductList[testList[index]].deal1 = int.parse(_deal1.text);
                                                                                        },
                                                                                        onSubmitted: (text) {
                                                                                          FocusScope.of(context).requestFocus(deal2);
                                                                                        },

                                                                                        //prod.qty = _textFieldController.text
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  Icon(Icons.add),
                                                                                  Flexible(
                                                                                    child: Padding(
                                                                                      padding: EdgeInsets.only(left: 4),
                                                                                      child: TextField(
                                                                                        focusNode: deal2,
                                                                                        // autofocus: true,
                                                                                        keyboardType: TextInputType.number,
                                                                                        controller: _deal2,
                                                                                        decoration: new InputDecoration(
                                                                                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                                                                          labelText: "Deal",
                                                                                          fillColor: Colors.black,
                                                                                          border: new OutlineInputBorder(
                                                                                            borderRadius: new BorderRadius.circular(15.0),
                                                                                            borderSide: new BorderSide(),
                                                                                          ),
                                                                                        ),
                                                                                        onChanged: (text) {
                                                                                          if (_deal2.text == "") {
                                                                                            selectedProductList[testList[index]].deal2 = 0;
                                                                                          } else
                                                                                            selectedProductList[testList[index]].deal2 = int.parse(_deal2.text);
                                                                                        },
                                                                                        onSubmitted: (text) {
                                                                                          FocusScope.of(context).requestFocus(qtyFocusNode);
                                                                                        },

                                                                                        //prod.qty = _textFieldController.text
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Flexible(
                                                                            child: Padding(
                                                                                padding: EdgeInsets.only(top: 8),
                                                                                child: TextField(
                                                                                  focusNode: qtyFocusNode,
                                                                                  keyboardType: TextInputType.number,
                                                                                  controller: _qty,
                                                                                  decoration: new InputDecoration(
                                                                                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                                                                                    labelText: "Quantity",
                                                                                    errorText: _validate ? "*Required" : null,
                                                                                    fillColor: Colors.black,
                                                                                    border: new OutlineInputBorder(
                                                                                      borderRadius: new BorderRadius.circular(15.0),
                                                                                      borderSide: new BorderSide(),
                                                                                    ),
                                                                                  ),
                                                                                  onSubmitted: (text) {
                                                                                    if (_qty.text == "") {
                                                                                      setState(() {
                                                                                        _validate = true;
                                                                                      });
                                                                                    } else {
                                                                                      setState(() {
                                                                                        _validate = false;
                                                                                      });
                                                                                      selectedProductList[testList[index]].qty = _qty.text;
                                                                                      Navigator.of(context).pop();
                                                                                      if (selectedProductList[testList[index]].deal1 != 0 && selectedProductList[testList[index]].deal2 != 0) {
                                                                                        selectedProductList[testList[index]].amount = double.parse(selectedProductList[testList[index]].qty) * selectedProductList[testList[index]].mrp * (1 - (min(selectedProductList[testList[index]].deal1, selectedProductList[testList[index]].deal2) / (selectedProductList[testList[index]].deal1 + selectedProductList[testList[index]].deal2)));
                                                                                        print(widget.data.defaultDiscount);
                                                                                      } else {
                                                                                        selectedProductList[testList[index]].amount = double.parse(selectedProductList[testList[index]].qty) * selectedProductList[testList[index]].mrp;
                                                                                      }
                                                                                      selectedProductList[testList[index]].amount = double.parse((selectedProductList[testList[index]].amount - (widget.data.defaultDiscount / 100) * selectedProductList[testList[index]].amount).toStringAsFixed(3));

                                                                                      _qty.clear();
                                                                                      _batch.clear();
                                                                                      _mrp.clear();
                                                                                      _deal1.clear();
                                                                                      _deal2.clear();
                                                                                      _expiry.clear();
                                                                                    }
                                                                                  },
                                                                                )),
                                                                          ),
                                                                        ],
                                                                      )),

                                                                      actions: <
                                                                          Widget>[
                                                                        new TextButton(
                                                                          child:
                                                                              new Text("Close"),
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.of(context).pop();
                                                                            _textFieldController.clear();
                                                                          },
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );
                                                              })),
                                                      title: Text(
                                                        '${selectedProductList[testList[index]].name}',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 20,
                                                        ),
                                                      ),
                                                      subtitle: Column(children: <
                                                          Widget>[
                                                        Row(
                                                          children: <Widget>[
                                                            Text("Pack: ",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Text(
                                                                '${selectedProductList[testList[index]].pack}',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black)),
                                                            SizedBox(width: 5),
                                                            Text(
                                                                "Expiry Date: ",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Text(
                                                                '${selectedProductList[testList[index]].expiryDate}',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black)),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: <Widget>[
                                                            Text("Batch No.: ",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Text(
                                                                '${selectedProductList[testList[index]].batchNumber}',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black)),
                                                            SizedBox(width: 5),
                                                            Text("MRP: ",
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Flexible(
                                                                child: Text(
                                                                    '\u20B9 ${selectedProductList[testList[index]].mrp}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black))),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: <Widget>[
                                                            Text("Qty: ",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Text(
                                                                '${selectedProductList[testList[index]].qty}',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black)),
                                                            SizedBox(width: 5),
                                                            Text("Deal: ",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                            Text(
                                                                '${selectedProductList[testList[index]].deal1}+${selectedProductList[testList[index]].deal2}',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black))
                                                          ],
                                                        ),
                                                      ]),
                                                      trailing: Container(
                                                          child: Padding(
                                                              padding:
                                                                  EdgeInsets.all(
                                                                      8),
                                                              child: Column(
                                                                  children: <
                                                                      Widget>[
                                                                    Text(
                                                                        "Amount",
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.black)),
                                                                    Text(
                                                                        '\u20B9 ${selectedProductList[testList[index]].amount.toStringAsFixed(1)}',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.black,
                                                                            fontSize: 20)),
                                                                  ])))),
                                                ),
                                              )

                                              // Divider(height: 1.0,)
                                            ],
                                          ),
                                        );
                                      },
                                    )))
                    ]),
                    floatingActionButton: selectedProductList.length > 0
                        ? _floatingActionButtonSelectedTab()
                        : null,
                  )
                ],
              ),
            )));
  }

  Widget _floatingActionButtonSelectedTab() {
    return FloatingActionButton(
      onPressed: () async {
        try {
          final result = await InternetAddress.lookup("google.com");
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
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
                            // create a
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

            widget.sendDataToFirestore(widget.check).then((value) {
              Navigator.pop(context);
              Navigator.pop(context);
            });
            // new Future.delayed(new Duration(seconds: 10), () {
            //   //Navigator.push(context, MaterialPageRoute(builder: (context) => ExpiryList(widget.data)));
            //   Navigator.pop(context);
            //   Navigator.pop(context);
            // });
          }
        } on SocketException catch (_) {
          _displaySnackBar("Please check your internet connection");
        }
      },
      child: Icon(Icons.mail),
      backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
    );
  }
}
