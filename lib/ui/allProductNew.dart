import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:startup_namer/globals.dart';
import 'package:startup_namer/model.dart';

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

class AllProductPageNew extends StatefulWidget {
  final PartyData data;
  final String docID;
  final bool check;
  final Timestamp invoiceDate;
  final double invoiceAmount;
  AllProductPageNew(
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
  _AllProductPageNewState createState() => new _AllProductPageNewState();
}

class _AllProductPageNewState extends State<AllProductPageNew> {
  // Search optimization variables
  Timer _debounceTimer;
  List<ProductData> _filteredProductList = [];
  List<String> _filteredBatchList = [];
  bool _isSearching = false;
  bool _showOnlyVerified = false; // Filter for verified purchases
  static const int _maxSearchResults = 50; // Limit search results

  _displaySnackBar(String action1) {
    final snackbar = SnackBar(
      content: Text(action1),
      backgroundColor: Color(0xFF2C3E50),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
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
    // Initialize filtered lists with empty data
    _filteredProductList = [];
    _filteredBatchList = [];

    // Load initial data after a short delay to ensure global lists are populated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });

    super.initState();
  }

  @override
  void dispose() {
    if (_debounceTimer != null) {
      _debounceTimer.cancel();
    }
    super.dispose();
  }

  // Debounced search function
  void _performSearch(String query) {
    if (_debounceTimer != null) {
      _debounceTimer.cancel();
    }
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      _filterSearchResults(query);
    });
  }

  // Optimized search filtering
  void _filterSearchResults(String query) {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    // Use compute for heavy operations to avoid blocking UI
    _filterResults(query).then((results) {
      if (!mounted) return;

      setState(() {
        if (isProdSearch) {
          _filteredProductList = results['products'] as List<ProductData>;
        } else {
          _filteredBatchList = results['batches'] as List<String>;
        }
        _isSearching = false;
      });
    });
  }

  // Load initial data when switching search types
  void _loadInitialData() {
    if (!mounted) return;

    print('DEBUG: Loading initial data - isProdSearch: $isProdSearch');
    print('DEBUG: globalProductList length: ${globalProductList?.length ?? 0}');
    print(
        'DEBUG: globalBatchNumberList length: ${globalBatchNumberList?.length ?? 0}');

    setState(() {
      _isSearching = true;
    });

    _filterResults("").then((results) {
      if (!mounted) return;

      setState(() {
        if (isProdSearch) {
          _filteredProductList = results['products'] as List<ProductData>;
          print('DEBUG: Loaded ${_filteredProductList.length} products');
        } else {
          _filteredBatchList = results['batches'] as List<String>;
          print('DEBUG: Loaded ${_filteredBatchList.length} batch numbers');
        }
        _isSearching = false;
      });
    });
  }

  // Separate function for filtering to potentially use compute
  Future<Map<String, dynamic>> _filterResults(String query) async {
    List<ProductData> filteredProducts = [];
    List<String> filteredBatches = [];

    if (query.isEmpty) {
      // Return first 20 items for empty query
      if (isProdSearch) {
        if (globalProductList != null && globalProductList.isNotEmpty) {
          filteredProducts = globalProductList.take(20).toList();
        }
      } else {
        if (globalBatchNumberList != null && globalBatchNumberList.isNotEmpty) {
          List<String> tempBatches = [];
          for (String batchNumber in globalBatchNumberList) {
            // Apply verified purchase filter if enabled
            if (_showOnlyVerified && !_hasPartyBoughtFromBatch(batchNumber)) {
              continue; // Skip this batch if verified filter is on and batch is not verified
            }
            tempBatches.add(batchNumber);
            if (tempBatches.length >= 20) break;
          }
          filteredBatches = tempBatches;
        }
      }
      return {
        'products': filteredProducts,
        'batches': filteredBatches,
      };
    }

    String upperQuery = query.toUpperCase();

    if (isProdSearch) {
      // Filter products
      for (ProductData product in globalProductList) {
        if (product.name.toUpperCase().contains(upperQuery)) {
          filteredProducts.add(product);
          if (filteredProducts.length >= _maxSearchResults) break;
        }
      }
    } else {
      // Filter batch numbers
      for (String batchNumber in globalBatchNumberList) {
        if (batchNumber.toUpperCase().contains(upperQuery)) {
          // Apply verified purchase filter if enabled
          if (_showOnlyVerified && !_hasPartyBoughtFromBatch(batchNumber)) {
            continue; // Skip this batch if verified filter is on and batch is not verified
          }
          filteredBatches.add(batchNumber);
          if (filteredBatches.length >= _maxSearchResults) break;
        }
      }
    }

    return {
      'products': filteredProducts,
      'batches': filteredBatches,
    };
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
              backgroundColor: Color(0xFFF5F7FA),
              appBar: AppBar(
                backgroundColor: Color(0xFF2C3E50),
                elevation: 0,
                leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      return selectedProductList.length > 0
                          ? showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
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
                                  content: Text(
                                    "You have some items in your cart. Do you want to stay on the page or discard the changes?",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF2C3E50),
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Go Back',
                                        style: TextStyle(
                                          color: Color(0xFFE74C3C),
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        primary: Color(0xFF3498DB),
                                        onPrimary: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Stay',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              })
                          : Navigator.pop(context);
                    }),
                title: Text(
                  "Products",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: PopupMenuButton(
                        onSelected: (int value) {
                          if (value == 1) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LocalPartyReport(
                                        partyName: widget.data.name,
                                        docID: widget.docID,
                                        defaultDisc:
                                            widget.data.defaultDiscount,
                                        invoiceDate: widget.invoiceDate,
                                        invoiceAmount: widget.invoiceAmount)));
                          }
                        },
                        itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 1,
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf,
                                        color: Color(0xFFE74C3C)),
                                    SizedBox(width: 8),
                                    Text("Generate PDF"),
                                  ],
                                ),
                              )
                            ]),
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
                    _buildAllProductsTab(_prodStream, _batchStream),
                    _buildSelectedProductsTab(),
                  ],
                ),
              ),
              floatingActionButton: selectedProductList.length > 0
                  ? _floatingActionButtonSelectedTab()
                  : null,
            )));
  }

  Widget _buildAllProductsTab(Stream _prodStream, Stream _batchStream) {
    return Column(
      children: <Widget>[
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
                  keyboardType: TextInputType.text,
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontFamily: 'Roboto',
                    ),
                    suffixIcon: (search != "")
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              setState(() {
                                FocusScope.of(context).unfocus();
                                WidgetsBinding.instance.addPostFrameCallback(
                                    (_) => _search.clear());
                                search = "";
                                _filteredProductList.clear();
                                _filteredBatchList.clear();
                                _showOnlyVerified =
                                    false; // Reset verified filter
                              });
                              if (_debounceTimer != null) {
                                _debounceTimer.cancel();
                              }
                              // Load initial data after clearing
                              _loadInitialData();
                            },
                          )
                        : IconButton(
                            icon: Icon(Icons.arrow_drop_down,
                                color: Color(0xFF5D6D7E)),
                            onPressed: () {
                              _showSearchTypeDialog();
                            }),
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
                  onChanged: (text) {
                    setState(() {
                      search = _search.text.toUpperCase();
                      // Only jump to top if scroll controller is attached
                      if (_scroll.hasClients) {
                        _scroll.jumpTo(0);
                      }
                    });
                    _performSearch(_search.text);
                  },
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
                    _showSearchTypeDialog();
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
              // Verified Purchase Toggle Button (only for batch search)
              if (!isProdSearch) ...[
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _showOnlyVerified
                        ? Color(0xFF27AE60)
                        : Color(0xFF34495E),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: (_showOnlyVerified
                                ? Color(0xFF27AE60)
                                : Color(0xFF2C3E50))
                            .withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _showOnlyVerified = !_showOnlyVerified;
                      });
                      _performSearch(_search.text);
                    },
                    icon: Icon(
                      Icons.verified_user,
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
            ],
          ),
        ),
        Expanded(
            child: _isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Searching...",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  )
                : (isProdSearch
                        ? (_filteredProductList.isEmpty && search.isNotEmpty)
                        : (_filteredBatchList.isEmpty && search.isNotEmpty))
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No results found",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontFamily: 'Roboto',
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Try a different search term",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      )
                    : (isProdSearch
                            ? (_filteredProductList.isEmpty && search.isEmpty)
                            : (_filteredBatchList.isEmpty && search.isEmpty))
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
                                  (isProdSearch
                                          ? (globalProductList?.isEmpty ?? true)
                                          : (globalBatchNumberList?.isEmpty ??
                                              true))
                                      ? "Data not loaded"
                                      : "Start typing to search",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  (isProdSearch
                                          ? (globalProductList?.isEmpty ?? true)
                                          : (globalBatchNumberList?.isEmpty ??
                                              true))
                                      ? "Please wait for data to load or check your connection"
                                      : "Search by product name or batch number",
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
                            controller: _scroll,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: (isProdSearch)
                                ? _filteredProductList.length
                                : _filteredBatchList.length,
                            itemBuilder: (context, index) {
                              ProductData prod = ProductData();
                              try {
                                if (!isProdSearch) {
                                  // Use filtered batch list
                                  String batchNumber =
                                      _filteredBatchList[index];

                                  // Check if the batch number exists in the map
                                  if (globalBatchNumberItemCodeMap == null ||
                                      !globalBatchNumberItemCodeMap
                                          .containsKey(batchNumber) ||
                                      globalBatchNumberItemCodeMap[
                                              batchNumber] ==
                                          null) {
                                    return Container(
                                      width: 0,
                                      height: 0,
                                    );
                                  }

                                  prod.name =
                                      globalBatchNumberItemCodeMap[batchNumber]
                                          .name;
                                  prod.pack =
                                      globalBatchNumberItemCodeMap[batchNumber]
                                          .pack;
                                  prod.batchNumber = batchNumber;
                                  prod.mrp =
                                      globalBatchNumberItemCodeMap[batchNumber]
                                          .mrp;

                                  // Safe date formatting
                                  String expiryDateStr =
                                      globalBatchNumberItemCodeMap[batchNumber]
                                          .expiryDate;
                                  if (expiryDateStr != null &&
                                      expiryDateStr.isNotEmpty) {
                                    try {
                                      prod.expiryDate = DateFormat("MM-yyyy")
                                          .format(
                                              DateTime.parse(expiryDateStr));
                                    } catch (e) {
                                      prod.expiryDate =
                                          expiryDateStr; // Use original string if parsing fails
                                    }
                                  }

                                  return _buildProductCard(
                                      _filteredBatchList, index, prod);
                                } else {
                                  // Use filtered product list
                                  ProductData product =
                                      _filteredProductList[index];

                                  // Check if the product exists
                                  if (product == null) {
                                    return Container(
                                      width: 0,
                                      height: 0,
                                    );
                                  }

                                  prod.name = product.name;
                                  prod.pack = product.pack;

                                  return _buildProductCard(
                                      _filteredProductList, index, prod);
                                }
                              } catch (e) {
                                print('Error building product card: $e');
                                return Container(
                                  width: 0,
                                  height: 0,
                                );
                              }
                            },
                          )),
      ],
    );
  }

  Widget _buildProductCard(List rev, int index, ProductData prod) {
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
              colors: [Colors.white, Color(0xFFF8F9FA)],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showProductDialog(rev, index, prod),
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
                            isProdSearch ? prod.name : prod.batchNumber,
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
                                (!isProdSearch)
                                    ? '${prod.name} | ${prod.pack}'
                                    : 'Pack: ${prod.pack}',
                                Color(0xFF3498DB),
                              ),
                              // Add party purchase chip for batch number view
                              if (!isProdSearch &&
                                  _hasPartyBoughtFromBatch(prod.batchNumber))
                                _buildInfoChip(
                                  'Verified Purchase',
                                  Color(0xFF27AE60),
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
                        primary: Color(0xFF5D6D7E),
                        onPrimary: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size(60, 32),
                      ),
                      child: Text(
                        "Add",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      onPressed: () => _showProductDialog(rev, index, prod),
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

  Widget _buildDetailChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  bool _hasPartyBoughtFromBatch(String batchNumber) {
    print("DEBUG: Checking batch: $batchNumber");
    print("DEBUG: Party code: ${widget.data.partyCode}");
    print(
        "DEBUG: Global batch map size: ${globalBatchPartyCodeMapList.length}");

    if (batchNumber == null || batchNumber.isEmpty) {
      print("DEBUG: Batch number is null or empty");
      return false;
    }
    if (widget.data.partyCode == null || widget.data.partyCode.isEmpty) {
      print("DEBUG: Party code is null or empty");
      return false;
    }

    // Check if the batch exists in the global batch party code map
    if (globalBatchPartyCodeMapList.containsKey(batchNumber)) {
      print("DEBUG: Batch Number Found: $batchNumber");
      List<String> partyCodes = globalBatchPartyCodeMapList[batchNumber];
      print("DEBUG: Party Codes Found: $partyCodes");
      if (partyCodes.contains(widget.data.partyCode)) {
        print(
            "DEBUG: Party Code Found: ${widget.data.partyCode} for batch $batchNumber");
        return true;
      } else {
        print(
            "DEBUG: Party code ${widget.data.partyCode} not found in batch $batchNumber");
        return false;
      }
    } else {
      print("DEBUG: Batch $batchNumber not found in global map");
      print(
          "DEBUG: Available batches: ${globalBatchPartyCodeMapList.keys.toList()}");
    }

    return false;
  }

  void _showSearchTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            "Search By",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Color(0xFF2C3E50),
              fontFamily: 'Roboto',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.inventory_2, color: Color(0xFF3498DB)),
                title: Text(
                  "Product Name",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                  ),
                ),
                onTap: () {
                  setState(() {
                    isProdSearch = true;
                    _filteredProductList.clear();
                    _filteredBatchList.clear();
                    _search.clear();
                    search = "";
                    _showOnlyVerified = false; // Reset verified filter
                    // Only jump to top if scroll controller is attached
                    if (_scroll.hasClients) {
                      _scroll.jumpTo(0);
                    }
                  });
                  if (_debounceTimer != null) {
                    _debounceTimer.cancel();
                  }
                  Navigator.of(context).pop();
                  // Load initial data for product search
                  _loadInitialData();
                },
              ),
              ListTile(
                leading: Icon(Icons.qr_code, color: Color(0xFF9B59B6)),
                title: Text(
                  "Batch Number",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                  ),
                ),
                onTap: () {
                  setState(() {
                    isProdSearch = false;
                    _filteredProductList.clear();
                    _filteredBatchList.clear();
                    _search.clear();
                    search = "";
                    _showOnlyVerified = false; // Reset verified filter
                    // Only jump to top if scroll controller is attached
                    if (_scroll.hasClients) {
                      _scroll.jumpTo(0);
                    }
                  });
                  if (_debounceTimer != null) {
                    _debounceTimer.cancel();
                  }
                  Navigator.of(context).pop();
                  // Load initial data for batch search
                  _loadInitialData();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedProductsTab() {
    return Column(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 600,
            child: (testList.length == 0)
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
                    padding: EdgeInsets.all(16),
                    itemCount: testList.length,
                    itemBuilder: (context, index) {
                      return _buildSelectedProductCard(index);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedProductCard(int index) {
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
          child: Dismissible(
            key: Key(index.toString()),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              setState(() {
                selectedProductList.remove(testList[index]);
                testList.remove(testList[index]);
              });
            },
            background: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Color(0xFFE74C3C),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.delete_forever_rounded,
                size: 30,
                color: Colors.white,
              ),
            ),
            confirmDismiss: (DismissDirection direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
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
                          "Confirm Delete",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Color(0xFF2C3E50),
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      "Are you sure you wish to delete this item?",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                        fontFamily: 'Roboto',
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          "CANCEL",
                          style: TextStyle(
                            color: Color(0xFF6C757D),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFFE74C3C),
                          onPrimary: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "DELETE",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
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
                          '${selectedProductList[testList[index]].name}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                            fontFamily: 'Roboto',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Pack Chip
                            if (selectedProductList[testList[index]].pack !=
                                    null &&
                                selectedProductList[testList[index]]
                                    .pack
                                    .isNotEmpty)
                              _buildDetailChip(
                                "Pack: ${selectedProductList[testList[index]].pack}",
                                Color(0xFF34495E), // Dark Gray
                              ),
                            // Quantity Chip
                            if (selectedProductList[testList[index]].qty !=
                                    null &&
                                selectedProductList[testList[index]]
                                    .qty
                                    .isNotEmpty)
                              _buildDetailChip(
                                "Qty: ${selectedProductList[testList[index]].qty}",
                                Color(0xFF8E44AD), // Purple
                              ),
                            // Batch Number Chip
                            if (selectedProductList[testList[index]]
                                        .batchNumber !=
                                    null &&
                                selectedProductList[testList[index]]
                                    .batchNumber
                                    .isNotEmpty)
                              _buildDetailChip(
                                "Batch: ${selectedProductList[testList[index]].batchNumber}",
                                Color(0xFF3498DB), // Blue
                              ),
                            // Deal Information Chip
                            if (selectedProductList[
                                            testList[index]]
                                        .deal1 !=
                                    null &&
                                selectedProductList[testList[index]].deal2 !=
                                    null &&
                                (selectedProductList[testList[index]].deal1 >
                                        0 ||
                                    selectedProductList[testList[index]].deal2 >
                                        0))
                              _buildDetailChip(
                                "Deal: ${selectedProductList[testList[index]].deal1}+${selectedProductList[testList[index]].deal2}",
                                Color(0xFFE74C3C), // Red
                              ),
                            // MRP Chip
                            if (selectedProductList[testList[index]].mrp !=
                                    null &&
                                selectedProductList[testList[index]].mrp > 0)
                              _buildDetailChip(
                                "MRP: ₹${selectedProductList[testList[index]].mrp.toStringAsFixed(1)}",
                                Color(0xFF27AE60), // Green
                              ),
                            // Expiry Date Chip
                            if (selectedProductList[testList[index]]
                                        .expiryDate !=
                                    null &&
                                selectedProductList[testList[index]]
                                    .expiryDate
                                    .isNotEmpty)
                              _buildDetailChip(
                                "Exp: ${selectedProductList[testList[index]].expiryDate}",
                                Color(0xFFF39C12), // Orange
                              ),
                          ],
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
                          '\u20B9 ${selectedProductList[testList[index]].amount.toStringAsFixed(1)}',
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
                            onPressed: () => _showEditDialog(index),
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
                            onPressed: () {
                              setState(() {
                                selectedProductList.remove(testList[index]);
                                testList.remove(testList[index]);
                              });
                            },
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
      ),
    );
  }

  Widget _floatingActionButtonSelectedTab() {
    return FloatingActionButton.extended(
      onPressed: () async {
        try {
          final result = await InternetAddress.lookup("google.com");
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: new Container(
                      height: 100,
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3498DB)),
                          ),
                          SizedBox(width: 20),
                          Text(
                            "Processing...",
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Roboto',
                              color: Color(0xFF2C3E50),
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
          }
        } on SocketException catch (_) {
          _displaySnackBar("Please check your internet connection");
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
    );
  }

  void _showProductDialog(List rev, int index, ProductData prod) {
    TextEditingController _name = TextEditingController(text: prod.name);
    TextEditingController _pack = TextEditingController(text: prod.pack);
    TextEditingController _mrp =
        TextEditingController(text: isProdSearch ? null : prod.mrp.toString());
    TextEditingController _expiry =
        TextEditingController(text: isProdSearch ? null : prod.expiryDate);
    TextEditingController _batch =
        TextEditingController(text: isProdSearch ? null : prod.batchNumber);
    TextEditingController _qty = TextEditingController();
    TextEditingController _deal1 =
        TextEditingController(text: isProdSearch ? null : "0");
    TextEditingController _deal2 =
        TextEditingController(text: isProdSearch ? null : "0");

    FocusNode qtyFocusNode = new FocusNode();
    FocusNode pack = new FocusNode();
    FocusNode mrp = new FocusNode();
    FocusNode expiry = new FocusNode();
    FocusNode batch = new FocusNode();
    FocusNode deal1 = new FocusNode();
    FocusNode deal2 = new FocusNode();
    bool _validate = false;

    showDialog(
      context: context,
      builder: (context) {
        prod.compCode = isProdSearch
            ? rev[index].compCode
            : globalBatchNumberItemCodeMap[rev[index]].compCode;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(
                  Icons.add,
                  color: Color(0xFF27AE60),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  '${isProdSearch ? rev[index].name : globalBatchNumberItemCodeMap[rev[index]].name}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildModernTextField(
                    controller: _name,
                    label: "Name",
                    icon: Icons.inventory_2,
                    onChanged: (text) => prod.name = text,
                    onSubmitted: (text) =>
                        FocusScope.of(context).requestFocus(pack),
                  ),
                  SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _pack,
                    label: "Pack",
                    icon: Icons.inventory,
                    focusNode: pack,
                    onChanged: (text) => prod.pack = text,
                    onSubmitted: (text) =>
                        FocusScope.of(context).requestFocus(mrp),
                  ),
                  SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _mrp,
                    label: "MRP",
                    icon: Icons.attach_money,
                    focusNode: mrp,
                    keyboardType: TextInputType.number,
                    autofocus: isProdSearch,
                    onChanged: (text) => prod.mrp = double.parse(_mrp.text),
                    onSubmitted: (text) =>
                        FocusScope.of(context).requestFocus(expiry),
                  ),
                  SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _expiry,
                    label: "Expiry Date",
                    icon: Icons.calendar_today,
                    focusNode: expiry,
                    keyboardType: TextInputType.number,
                    onChanged: (text) => prod.expiryDate = text,
                    onSubmitted: (text) =>
                        FocusScope.of(context).requestFocus(batch),
                  ),
                  SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _batch,
                    label: "Batch Number",
                    icon: Icons.qr_code,
                    focusNode: batch,
                    onChanged: (text) => prod.batchNumber = text.toUpperCase(),
                    onSubmitted: (text) =>
                        FocusScope.of(context).requestFocus(deal1),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildModernTextField(
                          controller: _deal1,
                          label: "Deal 1",
                          icon: Icons.add,
                          focusNode: deal1,
                          keyboardType: TextInputType.number,
                          onChanged: (text) {
                            if (_deal1.text == null) {
                              prod.deal1 = 0;
                            } else
                              prod.deal1 = int.parse(_deal1.text);
                          },
                          onSubmitted: (text) =>
                              FocusScope.of(context).requestFocus(deal2),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildModernTextField(
                          controller: _deal2,
                          label: "Deal 2",
                          icon: Icons.add,
                          focusNode: deal2,
                          keyboardType: TextInputType.number,
                          onChanged: (text) {
                            if (_deal2.text == null) {
                              prod.deal2 = 0;
                            } else
                              prod.deal2 = int.parse(_deal2.text);
                          },
                          onSubmitted: (text) =>
                              FocusScope.of(context).requestFocus(qtyFocusNode),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _qty,
                    label: "Quantity",
                    icon: Icons.shopping_cart,
                    focusNode: qtyFocusNode,
                    keyboardType: TextInputType.number,
                    autofocus: !isProdSearch,
                    errorText: _validate ? "*Required" : null,
                    onSubmitted: (text) {
                      if (_qty.text == "") {
                        setDialogState(() => _validate = true);
                      } else {
                        setDialogState(() => _validate = false);
                        prod.qty = _qty.text;
                        Navigator.of(context).pop();
                        _processProduct(prod);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _textFieldController.clear();
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_qty.text.isEmpty) {
                    setDialogState(() => _validate = true);
                  } else {
                    prod.qty = _qty.text;
                    Navigator.of(context).pop();
                    _processProduct(prod);
                  }
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
                  "Add",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernTextField({
    TextEditingController controller,
    String label,
    IconData icon,
    FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    bool autofocus = false,
    String errorText,
    Function(String) onChanged,
    Function(String) onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Color(0xFF3498DB),
          fontFamily: 'Roboto',
        ),
        errorText: errorText,
        prefixIcon: Icon(icon, color: Color(0xFF3498DB)),
        filled: true,
        fillColor: Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF3498DB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE74C3C), width: 2),
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
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }

  void _processProduct(ProductData prod) {
    // Ensure deal values are not null
    prod.deal1 = prod.deal1 ?? 0;
    prod.deal2 = prod.deal2 ?? 0;

    if (prod.deal1 != 0 && prod.deal2 != 0) {
      prod.amount = double.parse(prod.qty) *
          prod.mrp *
          (1 - (prod.deal2) / (prod.deal1 + prod.deal2));
    } else {
      prod.amount = double.parse(prod.qty) * prod.mrp;
    }
    prod.amount = double.parse(
        (prod.amount - (widget.data.defaultDiscount / 100) * prod.amount)
            .toStringAsFixed(3));

    bool test = addToMap(prod);
    if (!test) {
      _showDuplicateProductDialog(prod);
    }
  }

  void _showDuplicateProductDialog(ProductData prod) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                "Duplicate Product",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Color(0xFF2C3E50),
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
          content: Text(
            prod.name +
                " with batch number " +
                prod.batchNumber +
                " already exists.",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF2C3E50),
              fontFamily: 'Roboto',
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Color(0xFF3498DB),
                onPrimary: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "OK",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto',
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        );
      },
    );
  }

  void _showEditDialog(int index) {
    TextEditingController _name =
        TextEditingController(text: selectedProductList[testList[index]].name);
    TextEditingController _pack =
        TextEditingController(text: selectedProductList[testList[index]].pack);
    TextEditingController _mrp = TextEditingController(
        text: selectedProductList[testList[index]].mrp.toString());
    TextEditingController _expiry = TextEditingController(
        text: selectedProductList[testList[index]].expiryDate);
    TextEditingController _batch = TextEditingController(
        text: selectedProductList[testList[index]].batchNumber);
    TextEditingController _qty =
        TextEditingController(text: selectedProductList[testList[index]].qty);
    TextEditingController _deal1 = TextEditingController(
        text: selectedProductList[testList[index]].deal1.toString());
    TextEditingController _deal2 = TextEditingController(
        text: selectedProductList[testList[index]].deal2.toString());

    FocusNode qtyFocusNode = new FocusNode();
    FocusNode pack = new FocusNode();
    FocusNode mrp = new FocusNode();
    FocusNode expiry = new FocusNode();
    FocusNode batch1 = new FocusNode();
    FocusNode deal1 = new FocusNode();
    FocusNode deal2 = new FocusNode();
    bool _validate = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(
                  Icons.edit,
                  color: Color(0xFFF39C12),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  '${selectedProductList[testList[index]].name}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Color(0xFF2C3E50),
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildModernTextField(
                    controller: _name,
                    label: "Name",
                    icon: Icons.inventory_2,
                    autofocus: true,
                    onChanged: (text) =>
                        selectedProductList[testList[index]].name = text,
                    onSubmitted: (text) =>
                        FocusScope.of(context).requestFocus(pack),
                  ),
                  SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _pack,
                    label: "Pack",
                    icon: Icons.inventory,
                    focusNode: pack,
                    onChanged: (text) =>
                        selectedProductList[testList[index]].pack = text,
                    onSubmitted: (text) =>
                        FocusScope.of(context).requestFocus(mrp),
                  ),
                  SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _mrp,
                    label: "MRP",
                    icon: Icons.attach_money,
                    focusNode: mrp,
                    keyboardType: TextInputType.number,
                    onChanged: (text) => selectedProductList[testList[index]]
                        .mrp = double.parse(_mrp.text),
                    onSubmitted: (text) =>
                        FocusScope.of(context).requestFocus(expiry),
                  ),
                  SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _expiry,
                    label: "Expiry Date",
                    icon: Icons.calendar_today,
                    focusNode: expiry,
                    keyboardType: TextInputType.number,
                    onChanged: (text) =>
                        selectedProductList[testList[index]].expiryDate = text,
                    onSubmitted: (text) =>
                        FocusScope.of(context).requestFocus(batch1),
                  ),
                  SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _batch,
                    label: "Batch Number",
                    icon: Icons.qr_code,
                    focusNode: batch1,
                    onChanged: (text) => selectedProductList[testList[index]]
                        .batchNumber = text.toUpperCase(),
                    onSubmitted: (text) =>
                        FocusScope.of(context).requestFocus(deal1),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildModernTextField(
                          controller: _deal1,
                          label: "Deal 1",
                          icon: Icons.add,
                          focusNode: deal1,
                          keyboardType: TextInputType.number,
                          onChanged: (text) {
                            if (_deal1.text == "") {
                              selectedProductList[testList[index]].deal1 = 0;
                            } else
                              selectedProductList[testList[index]].deal1 =
                                  int.parse(_deal1.text);
                          },
                          onSubmitted: (text) =>
                              FocusScope.of(context).requestFocus(deal2),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildModernTextField(
                          controller: _deal2,
                          label: "Deal 2",
                          icon: Icons.add,
                          focusNode: deal2,
                          keyboardType: TextInputType.number,
                          onChanged: (text) {
                            if (_deal2.text == "") {
                              selectedProductList[testList[index]].deal2 = 0;
                            } else
                              selectedProductList[testList[index]].deal2 =
                                  int.parse(_deal2.text);
                          },
                          onSubmitted: (text) =>
                              FocusScope.of(context).requestFocus(qtyFocusNode),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _qty,
                    label: "Quantity",
                    icon: Icons.shopping_cart,
                    focusNode: qtyFocusNode,
                    keyboardType: TextInputType.number,
                    errorText: _validate ? "*Required" : null,
                    onSubmitted: (text) {
                      if (_qty.text == "") {
                        setDialogState(() => _validate = true);
                      } else {
                        setDialogState(() => _validate = false);
                        selectedProductList[testList[index]].qty = _qty.text;
                        Navigator.of(context).pop();
                        _updateProductAmount(index);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _textFieldController.clear();
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_qty.text.isEmpty) {
                    setDialogState(() => _validate = true);
                  } else {
                    selectedProductList[testList[index]].qty = _qty.text;
                    Navigator.of(context).pop();
                    _updateProductAmount(index);
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFFF39C12),
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
      },
    );
  }

  void _updateProductAmount(int index) {
    // Ensure deal values are not null
    selectedProductList[testList[index]].deal1 =
        selectedProductList[testList[index]].deal1 ?? 0;
    selectedProductList[testList[index]].deal2 =
        selectedProductList[testList[index]].deal2 ?? 0;

    if (selectedProductList[testList[index]].deal1 != 0 &&
        selectedProductList[testList[index]].deal2 != 0) {
      selectedProductList[testList[index]].amount =
          double.parse(selectedProductList[testList[index]].qty) *
              selectedProductList[testList[index]].mrp *
              (1 -
                  (math.min(selectedProductList[testList[index]].deal1,
                          selectedProductList[testList[index]].deal2) /
                      (selectedProductList[testList[index]].deal1 +
                          selectedProductList[testList[index]].deal2)));
    } else {
      selectedProductList[testList[index]].amount =
          double.parse(selectedProductList[testList[index]].qty) *
              selectedProductList[testList[index]].mrp;
    }
    selectedProductList[testList[index]].amount = double.parse(
        (selectedProductList[testList[index]].amount -
                (widget.data.defaultDiscount / 100) *
                    selectedProductList[testList[index]].amount)
            .toStringAsFixed(3));
    setState(() {});
  }
}
