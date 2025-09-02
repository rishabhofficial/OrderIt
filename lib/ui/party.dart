import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:startup_namer/globals.dart';
import 'package:startup_namer/model.dart';
import 'package:startup_namer/ui/transactionList.dart';

import './allProdSearch.dart';
import './form.dart';

List<String> partyName = [];
var check = new Map();
var disc = new Map();

class PartyPage extends StatefulWidget {
  @override
  _PartyPageState createState() => new _PartyPageState();
}

class _PartyPageState extends State<PartyPage> {
  void _populateSearchLists() {
    // Clear existing data
    partyName.clear();
    check.clear();
    disc.clear();

    // Populate search lists with all data
    for (GlobalPartyData partyData in globalPartyList) {
      if (partyData.partyName != null && partyData.partyName.isNotEmpty) {
        String displayName = partyData.partyName;
        if (!check.containsKey(displayName)) {
          check[displayName] = true;
          partyName.add(displayName);
          disc[displayName] = 0.0; // Default discount
        }
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
          "Parties",
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
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                showSearch(context: context, delegate: DataSearch());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: Icon(Icons.storage, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OldPartyPage()),
                );
              },
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.only(right: 8.0),
          //   child: PopupMenuButton(
          //     icon: Icon(Icons.add, color: Colors.white),
          //     onSelected: (int) {
          //       Navigator.push(context,
          //           MaterialPageRoute(builder: (context) => PartyForm()));
          //     },
          //     itemBuilder: (context) => [
          //       PopupMenuItem(
          //         value: 1,
          //         child: Row(
          //           children: [
          //             Icon(Icons.person_add, color: Color(0xFF3498DB)),
          //             SizedBox(width: 8),
          //             Text(
          //               "Add New Party",
          //               style: TextStyle(fontSize: 16, fontFamily: 'Roboto'),
          //             ),
          //           ],
          //         ),
          //       )
          //     ],
          //   ),
          // ),
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
        child: globalPartyList.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading parties...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              )
            : Builder(
                builder: (context) {
                  // Populate search lists immediately when data is available
                  _populateSearchLists();

                  return ListView.builder(
                    padding: EdgeInsets.all(12.0),
                    itemCount: globalPartyList.length,
                    itemBuilder: (context, index) {
                      GlobalPartyData partyData = globalPartyList[index];

                      // Safety check for empty party names
                      if (partyData.partyName == null ||
                          partyData.partyName.isEmpty) {
                        return SizedBox.shrink(); // Skip empty party names
                      }

                      String displayName = partyData.partyName;
                      return _buildPartyCard(context, partyData, displayName);
                    },
                  );
                },
              ),
      ),
      // floatingActionButton: new FloatingActionButton(
      //     backgroundColor: Color(0xFF2C3E50),
      //     child: const Icon(
      //       Icons.search,
      //       color: Colors.white,
      //     ),
      //     elevation: 2.0,
      //     onPressed: () {
      //       Navigator.push(context,
      //           MaterialPageRoute(builder: (context) => SearchProdList()));
      //     })
    );
  }

  Widget _buildPartyCard(
      BuildContext context, GlobalPartyData partyData, String displayName) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.0),
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
                PartyData data = PartyData(
                    name: displayName,
                    defaultDiscount: disc[displayName] ?? 0.0,
                    partyCode: partyData.partyCode);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ExpiryList(data)));
              },
              onLongPress: () {
                _showPartyOptions(context, partyData, displayName);
              },
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.0),
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
                        partyData.partyCode ?? '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            partyData.partyLocation ?? 'No location',
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

  void _showPartyOptions(
      BuildContext context, GlobalPartyData partyData, String displayName) {
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
                displayName,
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
                // Note: Since we're using global data, we might need to handle this differently
                // For now, we'll show a message that this feature needs to be implemented
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Modify feature needs to be implemented for global data'),
                    backgroundColor: Color(0xFF3498DB),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Color(0xFFE74C3C)),
              title: Text(
                'Delete Party',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, partyData, displayName);
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, GlobalPartyData partyData, String displayName) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Color(0xFF2C3E50),
        title: Text(
          'Delete Party',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        content: Text(
          'Are you sure you want to delete $displayName? This action cannot be undone.',
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
              // Note: Since we're using global data, we might need to handle this differently
              // For now, we'll show a message that this feature needs to be implemented
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Delete feature needs to be implemented for global data'),
                  backgroundColor: Color(0xFFE74C3C),
                ),
              );
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.warning_rounded, color: Colors.red, size: 100),
            GestureDetector(
              onTap: () {
                //Define your action when clicking on result item.
                //In this example, it simply closes the page
                this.close(context, this.query);
              },
              child: Text(
                "Work In Progress",
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    .copyWith(fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? partyName
        : partyName
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
                    'No parties found',
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
                final partyName = suggestionList[index];

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
                            this.close(context, this.query);
                            // Find the party data to get the partyCode
                            GlobalPartyData partyData =
                                globalPartyList.firstWhere(
                              (party) => party.partyName == partyName,
                              orElse: () => GlobalPartyData(
                                partyName: partyName,
                                partyCode: '?',
                                partyLocation: 'Unknown',
                              ),
                            );
                            PartyData data = PartyData(
                                name: partyName,
                                defaultDiscount: disc[partyName] ?? 0.0,
                                partyCode: partyData.partyCode);
                            print(
                                "DEBUG: Search result - Party: $partyName, Code: ${partyData.partyCode}");
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ExpiryList(data)));
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
                                    _getPartyCode(partyName),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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
                                              partyName, query),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Location: ${_getPartyLocation(partyName)}',
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

  String _getPartyLocation(String partyName) {
    // Find the party in globalPartyList and return its location
    for (var party in globalPartyList) {
      if (party.partyName == partyName) {
        return party.partyLocation ?? 'No location';
      }
    }
    return 'No location';
  }

  String _getPartyCode(String partyName) {
    // Find the party in globalPartyList and return its code
    for (var party in globalPartyList) {
      if (party.partyName == partyName) {
        return party.partyCode ?? '?';
      }
    }
    return '?';
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
}

class OldPartyPage extends StatefulWidget {
  @override
  _OldPartyPageState createState() => _OldPartyPageState();
}

class _OldPartyPageState extends State<OldPartyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        elevation: 0,
        title: Text(
          "Parties (Old)",
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
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                showSearch(context: context, delegate: OldDataSearch());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: PopupMenuButton(
              icon: Icon(Icons.add, color: Colors.white),
              onSelected: (int) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => PartyForm()));
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.person_add, color: Color(0xFF3498DB)),
                      SizedBox(width: 8),
                      Text(
                        "Add New Party",
                        style: TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                      ),
                    ],
                  ),
                ),
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
              .collection('Party')
              .orderBy('partyName')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading parties from Firestore...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error loading parties',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        fontFamily: 'Roboto',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No parties found',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 18,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add some parties to get started',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(12.0),
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot partyList = snapshot.data.docs[index];
                if (!check.containsKey(partyList['partyName'])) {
                  check[partyList['partyName']] = true;
                  partyName.add(partyList['partyName']);
                  disc[partyList['partyName']] =
                      partyList['partyDefaultDiscount'];
                }
                return _buildOldPartyCard(context, partyList);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFF3498DB),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => SearchProdList()));
        },
        icon: Icon(Icons.search),
        label: Text('Search Products'),
      ),
    );
  }

  Widget _buildOldPartyCard(BuildContext context, DocumentSnapshot partyList) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.0),
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
                PartyData data = PartyData(
                    name: partyList['partyName'],
                    defaultDiscount: partyList['partyDefaultDiscount']);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ExpiryList(data)));
              },
              onLongPress: () {
                _showOldPartyOptions(context, partyList);
              },
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.0),
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
                        '${partyList['partyName'][0]}',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${partyList['partyName']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            partyList['partyEmail'] ?? 'No email',
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

  void _showOldPartyOptions(BuildContext context, DocumentSnapshot partyList) {
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
                '${partyList['partyName']}',
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
                PartyData dataa = PartyData(
                    name: partyList['partyName'],
                    email: partyList['partyEmail'],
                    defaultDiscount: partyList['partyDefaultDiscount']);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PartyUpdateForm(dataa, partyList.id)));
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Color(0xFFE74C3C)),
              title: Text(
                'Delete Party',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Roboto',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showOldDeleteConfirmation(context, partyList);
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showOldDeleteConfirmation(
      BuildContext context, DocumentSnapshot partyList) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Color(0xFF2C3E50),
        title: Text(
          'Delete Party',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${partyList['partyName']}? This action cannot be undone.',
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
                  .collection('Party')
                  .doc(partyList.id)
                  .delete()
                  .whenComplete(() {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Party deleted successfully'),
                    backgroundColor: Color(0xFFE74C3C),
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

class OldDataSearch extends SearchDelegate<String> {
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Party')
          .where('partyName', isGreaterThanOrEqualTo: query)
          .where('partyName', isLessThan: query + 'z')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, color: Colors.grey[400], size: 64),
                SizedBox(height: 16),
                Text(
                  'No parties found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data.docs[index];
            String partyName = doc['partyName'] ?? 'Unknown Party';
            String partyEmail = doc['partyEmail'] ?? 'No email';

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
                        close(context, partyName);
                        PartyData data = PartyData(
                            name: partyName,
                            defaultDiscount:
                                doc['partyDefaultDiscount'] ?? 0.0);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ExpiryList(data)));
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
                                    color: Color(0xFF9B59B6).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                partyName.isNotEmpty
                                    ? partyName[0].toUpperCase()
                                    : '?',
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    partyName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    partyEmail,
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
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Party').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        final suggestions = snapshot.data.docs.where((doc) {
          String partyName = doc['partyName']?.toString().toLowerCase() ?? '';
          return partyName.contains(query.toLowerCase());
        }).toList();

        if (suggestions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, color: Colors.grey[400], size: 64),
                SizedBox(height: 16),
                Text(
                  'No parties found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = suggestions[index];
            String partyName = doc['partyName'] ?? 'Unknown Party';
            String partyEmail = doc['partyEmail'] ?? 'No email';

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
                        close(context, partyName);
                        PartyData data = PartyData(
                            name: partyName,
                            defaultDiscount:
                                doc['partyDefaultDiscount'] ?? 0.0);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ExpiryList(data)));
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
                                    color: Color(0xFF9B59B6).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                partyName.isNotEmpty
                                    ? partyName[0].toUpperCase()
                                    : '?',
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    partyName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    partyEmail,
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
        );
      },
    );
  }
}
