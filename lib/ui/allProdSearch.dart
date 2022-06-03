import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:startup_namer/model.dart';
import './prodSearch.dart';

class SearchProdList extends StatefulWidget {
  @override
  _SearchProdListState createState() => _SearchProdListState();
}

class _SearchProdListState extends State<SearchProdList> {
  TextEditingController _search = TextEditingController();
  String search = "";
  ScrollController _scroll = new ScrollController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
          leading: new IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              }),
          title: new Text(
            "Products",
            style: TextStyle(
                color: Colors.white,
                fontSize: 22.0,
                fontWeight: FontWeight.w600),
          ),
        ),
        body: Column(children: <Widget>[
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
                                .addPostFrameCallback((_) => _search.clear());
                            search = "";
                          });
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                labelText: "",
                // fillColor: Colors.black,
                border: new OutlineInputBorder(
                  borderRadius: new BorderRadius.circular(15.0),
                  borderSide: new BorderSide(color: Colors.red, width: 5.0),
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
                      .where("prodName", isGreaterThanOrEqualTo: search)
                      .limit(15)
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
                            var color = Colors.blueGrey;
                            var elevation = 8.0;
                            return Column(children: <Widget>[
                              (prod.name.length >= search.length &&
                                      prod.name.substring(0, search.length) ==
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
                                      trailing: new Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  elevation: elevation,
                                                  primary: color),
                                              child: Text(
                                                "Search",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            ProdSearch(rev[
                                                                    index]
                                                                ['prodName'])));
                                              },
                                            )
                                          ]))
                                  : Container(
                                      width: 0,
                                      height: 0,
                                      color: Colors.white,
                                    ),
                              (prod.name.length >= search.length &&
                                      prod.name.substring(0, search.length) ==
                                          search)
                                  ? Divider(
                                      height: 1.0,
                                    )
                                  : Container(
                                      width: 0,
                                      height: 0,
                                      color: Colors.white,
                                    )
                            ]);
                          });
                    }
                  }))
        ]));
  }
}
