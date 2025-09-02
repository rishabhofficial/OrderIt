import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:startup_namer/model.dart';

import './form.dart';
import './product.dart';

List<String> compName = [];
var check = new Map();
var email = new Map();

class Mails {
  String mailId;
  String cc;
}

class CompanyPage extends StatefulWidget {
  @override
  _CompanyPageState createState() => new _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  void _populateSearchLists(List<DocumentSnapshot> docs) {
    // Clear existing data
    compName.clear();
    check.clear();
    email.clear();

    // Populate search lists with all data
    for (DocumentSnapshot doc in docs) {
      String compNameValue = doc['compName'];
      if (!check.containsKey(compNameValue)) {
        check[compNameValue] = true;
        compName.add(compNameValue);
        Mails mail = Mails();
        mail.mailId = doc['compEmail'];
        mail.cc = doc['compCC'];
        email[compNameValue] = mail;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        elevation: 0,
        title: Text(
          "Companies",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                showSearch(context: context, delegate: DataSearch());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: PopupMenuButton(
              icon: Icon(Icons.add, color: Colors.white),
              onSelected: (int) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CompanyForm()));
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.add_business, color: Color(0xFF3498DB)),
                      SizedBox(width: 8),
                      Text(
                        "Add New Company",
                        style: TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF34495E),
            ],
          ),
        ),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Company')
              .orderBy('compName')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading companies...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Populate search lists immediately when data is available
              _populateSearchLists(snapshot.data.docs);

              return ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot companyList = snapshot.data.docs[index];
                  return _buildCompanyCard(context, companyList);
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCompanyCard(BuildContext context, DocumentSnapshot companyList) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 6.0,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34495E),
                Color(0xFF2C3E50),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: () {
                final data = CompanyData(
                  email: companyList['compEmail'],
                  name: companyList['compName'],
                  cc: companyList['compCC'],
                  codes: companyList['codes'],
                );
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ProductPage(data: data, check: false)));
              },
              onLongPress: () {
                _showCompanyOptions(context, companyList);
              },
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Color(0xFF9B59B6),
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF9B59B6).withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${companyList['compName'][0]}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${companyList['compName']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            companyList['compEmail'] ?? 'No email',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[300],
                      size: 18,
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

  void _showCompanyOptions(BuildContext context, DocumentSnapshot companyList) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Color(0xFF2C3E50),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '${companyList['compName']}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Color(0xFF3498DB)),
              title: Text(
                'Modify Details',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                CompanyData dataa = CompanyData(
                    name: companyList['compName'],
                    email: companyList['compEmail'],
                    cc: companyList['compCC'],
                    mailingName: companyList['compMailingName'],
                    mailingLocation: companyList['compMailingLocation'],
                    codes: companyList['codes'],
                    compCode: companyList['compCode']);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            CompanyUpdateForm(dataa, companyList.id)));
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Color(0xFFE74C3C)),
              title: Text(
                'Delete Company',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, companyList);
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, DocumentSnapshot companyList) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Color(0xFF2C3E50),
        title: Text(
          'Delete Company',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${companyList['compName']}? This action cannot be undone.',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            fontFamily: 'Roboto',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[300],
                fontFamily: 'Roboto',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseFirestore.instance
                  .collection('Company')
                  .doc(companyList.id)
                  .delete()
                  .whenComplete(() {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Company deleted successfully'),
                    backgroundColor: Color(0xFF27AE60),
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              primary: Color(0xFFE74C3C),
            ),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DataSearch extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return null;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? compName
        : compName
            .where((p) =>
                p.toLowerCase().contains(query.toLowerCase()) ||
                p.toLowerCase().startsWith(query.toLowerCase()) ||
                p.toLowerCase().endsWith(query.toLowerCase()))
            .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF34495E),
          ],
        ),
      ),
      child: suggestionList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    color: Colors.grey[400],
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No companies found',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 18,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try searching with different keywords',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: suggestionList.length,
              itemBuilder: (context, index) {
                final companyName = suggestionList[index];

                // Highlight matching text is handled in _buildHighlightedText method

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    elevation: 4,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF34495E),
                            Color(0xFF2C3E50),
                          ],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            // Find the company data and navigate
                            _findAndNavigateToCompany(context, companyName);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF9B59B6),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Color(0xFF9B59B6).withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    companyName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Roboto',
                                          ),
                                          children: _buildHighlightedText(
                                              companyName, query),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        email[companyName]?.mailId ??
                                            'No email',
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 13,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[300],
                                  size: 16,
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
    );
  }

  List<TextSpan> _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final List<TextSpan> spans = [];

    if (textLower.contains(queryLower)) {
      final startIndex = textLower.indexOf(queryLower);
      final endIndex = startIndex + query.length;

      // Text before match
      if (startIndex > 0) {
        spans.add(TextSpan(text: text.substring(0, startIndex)));
      }

      // Highlighted match
      spans.add(TextSpan(
        text: text.substring(startIndex, endIndex),
        style: TextStyle(
          color: Color(0xFF3498DB),
          fontWeight: FontWeight.w700,
        ),
      ));

      // Text after match
      if (endIndex < text.length) {
        spans.add(TextSpan(text: text.substring(endIndex)));
      }
    } else {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }

  void _findAndNavigateToCompany(
      BuildContext buildContext, String companyName) async {
    try {
      // Query Firestore to get the complete company data
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Company')
          .where('compName', isEqualTo: companyName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot companyDoc = querySnapshot.docs.first;
        final companyData = CompanyData(
          email: companyDoc['compEmail'],
          name: companyDoc['compName'],
          cc: companyDoc['compCC'],
          codes: companyDoc['codes'],
          compCode: companyDoc['compCode'],
          mailingName: companyDoc['compMailingName'],
          mailingLocation: companyDoc['compMailingLocation'],
        );

        Navigator.push(
          buildContext,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              data: companyData,
              check: false,
            ),
          ),
        );
      } else {
        // Fallback to basic data if company not found
        final companyData = CompanyData(
          name: companyName,
          email: email[companyName]?.mailId ?? '',
          cc: email[companyName]?.cc ?? '',
          codes: [],
        );

        Navigator.push(
          buildContext,
          MaterialPageRoute(
            builder: (context) => ProductPage(
              data: companyData,
              check: false,
            ),
          ),
        );
      }
    } catch (e) {
      // Handle error and fallback to basic data
      final companyData = CompanyData(
        name: companyName,
        email: email[companyName]?.mailId ?? '',
        cc: email[companyName]?.cc ?? '',
        codes: [],
      );

      Navigator.push(
        buildContext,
        MaterialPageRoute(
          builder: (context) => ProductPage(
            data: companyData,
            check: false,
          ),
        ),
      );
    }
  }
}
