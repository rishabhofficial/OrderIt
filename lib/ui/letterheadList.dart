import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class LetterDetails {
  final String id;
  final String letterTo;
  final String letterDate;
  final String letterSubject;
  final String letterBody;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  LetterDetails({
    this.id,
    this.letterTo,
    this.letterDate,
    this.letterSubject,
    this.letterBody,
    this.createdAt,
    this.updatedAt,
  });
}

class LetterHeadPage extends StatefulWidget {
  String address = "";
  String subject = "";
  Timestamp datetime = Timestamp.now();
  @override
  _LetterHeadPageState createState() => _LetterHeadPageState();
}

class _LetterHeadPageState extends State<LetterHeadPage> {
  String loaderText = "Loading...";
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        elevation: 0,
        title: Text(
          "Letter Templates",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
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
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('Letters').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error loading letters',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.data.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No letters found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to create your first letter',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot letterDoc = snapshot.data.docs[index];
                  return _buildLetterCard(context, letterDoc, index);
                },
              );
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF2C3E50)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading letters...',
                      style: TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFF3498DB),
        foregroundColor: Colors.white,
        onPressed: () {
          _showAddLetterForm(context);
        },
        icon: Icon(Icons.add),
        label: Text('New Letter'),
      ),
    );
  }

  Widget _buildLetterCard(
      BuildContext context, DocumentSnapshot letterDoc, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 6), // Reduced margin from 12 to 6
      child: Card(
        elevation: 6, // Reduced elevation
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Reduced border radius
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _showLetterDetails(context, letterDoc);
              },
              child: Padding(
                padding: EdgeInsets.all(16), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8), // Reduced padding
                          decoration: BoxDecoration(
                            color: Color(0xFF3498DB),
                            borderRadius: BorderRadius.circular(
                                8), // Reduced border radius
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF3498DB).withOpacity(0.3),
                                blurRadius: 6, // Reduced blur
                                offset: Offset(0, 3), // Reduced offset
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.description,
                            color: Colors.white,
                            size: 20, // Reduced icon size
                          ),
                        ),
                        SizedBox(width: 12), // Reduced spacing
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                letterDoc['letterTo'] ?? 'No recipient',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16, // Reduced font size
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2), // Reduced spacing
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: Colors.grey[300],
                                      size: 12), // Reduced icon size
                                  SizedBox(width: 3), // Reduced spacing
                                  Text(
                                    letterDoc['letterDate'] ?? 'No date',
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 12, // Reduced font size
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              color: Colors.white,
                              size: 20), // Reduced icon size
                          onSelected: (value) {
                            if (value == 'Edit') {
                              _showEditLetterForm(context, letterDoc.id);
                            } else if (value == 'Generate PDF') {
                              _generatePDFFromDoc(letterDoc);
                            } else if (value == 'Delete') {
                              _showDeleteConfirmation(context, letterDoc.id);
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              PopupMenuItem<String>(
                                value: 'Edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Color(0xFF3498DB)),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'Generate PDF',
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf,
                                        color: Color(0xFFE74C3C)),
                                    SizedBox(width: 8),
                                    Text('Generate PDF'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'Delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 12), // Reduced spacing
                    Container(
                      padding: EdgeInsets.all(8), // Reduced padding
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(6), // Reduced border radius
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12, // Reduced font size
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              letterDoc['letterSubject'] ?? 'No subject',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12, // Reduced font size
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1, // Reduced to 1 line
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8), // Reduced spacing
                    Container(
                      padding: EdgeInsets.all(8), // Reduced padding
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(6), // Reduced border radius
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '',
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 12, // Reduced font size
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              letterDoc['letterBody'] ?? 'No content',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12, // Reduced font size
                              ),
                              maxLines: 2, // Reduced to 2 lines
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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

  void _showDeleteConfirmation(BuildContext context, String letterId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Letter'),
        content: Text(
            'Are you sure you want to delete this letter? This action cannot be undone.'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('Letters')
                  .doc(letterId)
                  .delete();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLetterDetails(BuildContext context, DocumentSnapshot letterDoc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Letter Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                        'To', letterDoc['letterTo'] ?? 'No recipient'),
                    SizedBox(height: 16),
                    _buildDetailSection(
                        'Date', letterDoc['letterDate'] ?? 'No date'),
                    SizedBox(height: 16),
                    _buildDetailSection(
                        'Subject', letterDoc['letterSubject'] ?? 'No subject'),
                    SizedBox(height: 16),
                    _buildDetailSection(
                        'Content', letterDoc['letterBody'] ?? 'No content',
                        isContent: true),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.edit),
                            label: Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              primary: Color(0xFF3498DB),
                              onPrimary: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _showEditLetterForm(context, letterDoc.id);
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.picture_as_pdf),
                            label: Text('Generate PDF'),
                            style: ElevatedButton.styleFrom(
                              primary: Color(0xFFE74C3C),
                              onPrimary: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _generatePDFFromDoc(letterDoc);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content,
      {bool isContent = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: isContent ? 16 : 18,
              color: Colors.black87,
              height: isContent ? 1.5 : 1.2,
            ),
          ),
        ],
      ),
    );
  }

  void _generatePDFFromDoc(DocumentSnapshot letterDoc) {
    try {
      String address = letterDoc['letterTo'] ?? '';
      String subject = letterDoc['letterSubject'] ?? '';
      String letterBody = letterDoc['letterBody'] ?? '';

      // Parse date safely
      Timestamp dateTime;
      try {
        if (letterDoc['letterDate'] != null) {
          dateTime =
              Timestamp.fromDate(DateTime.parse(letterDoc['letterDate']));
        } else {
          dateTime = Timestamp.now();
        }
      } catch (e) {
        dateTime = Timestamp.now();
      }

      _showSignatureSelectionDialog(address, subject, dateTime, letterBody);
    } catch (e) {
      _showErrorDialog("Error: $e");
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _safePopNavigator() {
    try {
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print("Safe pop navigator error: $e");
    }
  }

  void _safeShowErrorDialog(String message) {
    try {
      if (mounted) {
        _showErrorDialog(message);
      }
    } catch (e) {
      print("Safe show error dialog error: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSignatureSelectionDialog(
      String address, String subject, Timestamp dateTime, String letterBody) {
    bool includeStamp = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF3498DB)),
              SizedBox(width: 8),
              Text('Choose Signature'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select a signature for your letter:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                // Stamp checkbox
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: includeStamp,
                        onChanged: (value) {
                          setState(() {
                            includeStamp = value ?? false;
                          });
                        },
                        activeColor: Color(0xFF3498DB),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.verified, color: Color(0xFFE74C3C), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Include Company Stamp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Signature Option 1
                InkWell(
                  onTap: () {
                    _safePopNavigator();
                    _showLoadingDialog("Generating PDF...");
                    pdfGenerator(address, subject, dateTime, letterBody,
                            signatureType: 'signature1',
                            includeStamp: includeStamp)
                        .then((_) {
                      _safePopNavigator();
                    }).catchError((error) {
                      _safePopNavigator();
                      _safeShowErrorDialog("Failed to generate PDF: $error");
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF3498DB), width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Color(0xFF3498DB).withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFF3498DB)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<ImageProvider>(
                              future: loadSanjaySignatureForUI(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image(
                                    image: snapshot.data,
                                    fit: BoxFit.contain,
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Sanjay',
                                      style: TextStyle(
                                        color: Color(0xFF3498DB),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                } else {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF3498DB)),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sanjay Kumar Agrawal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              Text(
                                'Proprietor',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: Color(0xFF3498DB), size: 16),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Signature Option 2
                InkWell(
                  onTap: () {
                    _safePopNavigator();
                    _showLoadingDialog("Generating PDF...");
                    pdfGenerator(address, subject, dateTime, letterBody,
                            signatureType: 'signature2',
                            includeStamp: includeStamp)
                        .then((_) {
                      _safePopNavigator();
                    }).catchError((error) {
                      _safePopNavigator();
                      _safeShowErrorDialog("Failed to generate PDF: $error");
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFE74C3C), width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Color(0xFFE74C3C).withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFE74C3C)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<ImageProvider>(
                              future: loadPankajSignatureForUI(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image(
                                    image: snapshot.data,
                                    fit: BoxFit.contain,
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Pankaj',
                                      style: TextStyle(
                                        color: Color(0xFFE74C3C),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                } else {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFE74C3C)),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pankaj Agrawal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              Text(
                                'Partner',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: Color(0xFFE74C3C), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLetterForm(BuildContext context, String letterId) {
    final _formKey = GlobalKey<FormState>();
    String letterDate = '';

    // Create TextEditingControllers
    TextEditingController letterToController = TextEditingController();
    TextEditingController letterSubjectController = TextEditingController();
    TextEditingController letterBodyController = TextEditingController();
    TextEditingController letterDateController = TextEditingController();

    // Fetch existing letter details
    FirebaseFirestore.instance
        .collection('Letters')
        .doc(letterId)
        .get()
        .then((doc) {
      if (doc.exists) {
        letterToController.text = doc['letterTo'] ?? '';
        letterDate = doc['letterDate'] ?? '';
        letterDateController.text = letterDate;
        letterSubjectController.text = doc['letterSubject'] ?? '';
        letterBodyController.text = doc['letterBody'] ?? '';

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF2C3E50),
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.white, size: 24),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Edit Letter',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
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
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recipient',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _buildTextField("To", letterToController,
                                      maxLines: 3),
                                  SizedBox(height: 16),
                                  Text(
                                    'Date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _buildDateField(context, (value) {
                                    setState(() {
                                      letterDate = value;
                                    });
                                  },
                                      initialDate: letterDate,
                                      controller: letterDateController),
                                  SizedBox(height: 16),
                                  Text(
                                    'Subject',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _buildTextField(
                                      "Subject", letterSubjectController,
                                      maxLines: 3),
                                  SizedBox(height: 16),
                                  Text(
                                    'Content',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _buildTextField("Body", letterBodyController,
                                      maxLines: 10, minLines: 1),
                                  SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            primary: Colors.grey[300],
                                            onPrimary: Colors.black87,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Cancel'),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            primary: Color(0xFFE74C3C),
                                            onPrimary: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          onPressed: () {
                                            try {
                                              Timestamp dateTime =
                                                  Timestamp.fromDate(
                                                      DateTime.parse(
                                                          letterDate));
                                              _showSignatureSelectionDialog(
                                                letterToController.text,
                                                letterSubjectController.text,
                                                dateTime,
                                                letterBodyController.text,
                                              );
                                            } catch (e) {
                                              _showErrorDialog(
                                                  "Invalid date format: $e");
                                            }
                                          },
                                          child: Text('Generate PDF'),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            primary: Color(0xFF3498DB),
                                            onPrimary: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          onPressed: () {
                                            if (_formKey.currentState
                                                .validate()) {
                                              // Update letter in Firestore
                                              FirebaseFirestore.instance
                                                  .collection('Letters')
                                                  .doc(letterId)
                                                  .update({
                                                'letterTo':
                                                    letterToController.text,
                                                'letterDate': letterDate,
                                                'letterSubject':
                                                    letterSubjectController
                                                        .text,
                                                'letterBody':
                                                    letterBodyController.text,
                                                'updatedAt': Timestamp.now(),
                                              });
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: Text('Update'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    });
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, int minLines = 1}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.all(12),
          suffixIcon: label == 'Body'
              ? IconButton(
                  icon: Icon(Icons.auto_awesome, color: Color(0xFF3498DB)),
                  onPressed: () async {
                    try {
                      String explanation =
                          await fetchAIExplanation(controller.text);
                      controller.text = "Dear Sir/Madam\n\n\n\n" + explanation;
                    } catch (e) {
                      _showErrorDialog("Failed to generate AI content: $e");
                    }
                  },
                )
              : null,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Please enter $label.";
          return null;
        },
        maxLines: maxLines,
        minLines: minLines,
      ),
    );
  }

  void _showAddLetterForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    // Set current date as default
    String letterDate =
        "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

    // Create TextEditingControllers
    TextEditingController letterToController = TextEditingController();
    TextEditingController letterSubjectController = TextEditingController();
    TextEditingController letterBodyController = TextEditingController();
    TextEditingController letterDateController =
        TextEditingController(text: letterDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
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
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF2C3E50),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_circle, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add New Letter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recipient',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildTextField("To", letterToController,
                                  maxLines: 3),
                              SizedBox(height: 16),
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildDateField(context, (value) {
                                setState(() {
                                  letterDate = value;
                                });
                              },
                                  initialDate: letterDate,
                                  controller: letterDateController),
                              SizedBox(height: 16),
                              Text(
                                'Subject',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildTextField(
                                  "Subject", letterSubjectController,
                                  maxLines: 3),
                              SizedBox(height: 16),
                              Text(
                                'Content',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildTextField("Body", letterBodyController,
                                  maxLines: 10, minLines: 1),
                              SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.grey[300],
                                        onPrimary: Colors.black87,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel'),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        primary: Color(0xFF3498DB),
                                        onPrimary: Colors.white,
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        if (_formKey.currentState.validate()) {
                                          // Add letter to Firestore
                                          FirebaseFirestore.instance
                                              .collection('Letters')
                                              .add({
                                            'letterTo': letterToController.text,
                                            'letterDate': letterDate,
                                            'letterSubject':
                                                letterSubjectController.text,
                                            'letterBody':
                                                letterBodyController.text,
                                            'createdAt': Timestamp.now(),
                                            'updatedAt': Timestamp.now(),
                                          });
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Text('Add Letter'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateField(BuildContext context, Function(String) onSaved,
      {String initialDate, TextEditingController controller}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: "Date",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.all(12),
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate?.isNotEmpty == true
                    ? DateTime.parse(initialDate)
                    : DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Color(0xFF3498DB),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                    ),
                    child: child,
                  );
                },
              );

              if (pickedDate != null) {
                String newDate =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                controller.text = newDate;
                onSaved(newDate);
              }
            },
          ),
        ),
        readOnly: true, // Make it read-only so user can't type directly
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please select a date";
          }
          return null;
        },
      ),
    );
  }

  pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(children: <pw.Widget>[
      // Container with border for the header
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.grey,
            width: 1.0,
          ),
          borderRadius: pw.BorderRadius.circular(8), // Rounded corners
        ),
        width: double.infinity,
        child: pw.Column(
          children: <pw.Widget>[
            pw.Row(children: <pw.Widget>[
              // Left side with company details
              pw.Container(
                padding: pw.EdgeInsets.all(12.0),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    right: pw.BorderSide(
                      width: 1.0,
                      style: pw.BorderStyle.solid,
                    ),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      "MAHESH PHARMA",
                      textAlign: pw.TextAlign.left,
                      style: pw.TextStyle(
                        font: pw.Font.times(),
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      "GONDA (U.P.)",
                      textAlign: pw.TextAlign.left,
                      style: pw.TextStyle(
                        font: pw.Font.times(),
                        fontWeight: pw.FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      "GST No:- 09ACTPA5656M1ZX",
                      textAlign: pw.TextAlign.left,
                      style: pw.TextStyle(
                        font: pw.Font.times(),
                        fontWeight: pw.FontWeight.normal,
                        fontSize: 8,
                      ),
                    ),
                    pw.Text(
                      "DL No:- UP4320B000762/UP4321B000761",
                      textAlign: pw.TextAlign.left,
                      style: pw.TextStyle(
                        font: pw.Font.times(),
                        fontWeight: pw.FontWeight.normal,
                        fontSize: 8,
                      ),
                    ),
                    pw.Container(height: 5),
                    pw.Text(
                      "DT - ${widget.datetime.toDate().day}/${widget.datetime.toDate().month}/${widget.datetime.toDate().year}",
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        font: pw.Font.times(),
                        fontWeight: pw.FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side for 'To' section
              pw.Expanded(
                child: pw.Container(
                  padding: pw.EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[
                      pw.Padding(
                        padding: pw.EdgeInsets.only(left: 10),
                        child: pw.Text(
                          "To,",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.only(left: 12),
                        child: pw.Text(
                          "M/S ${widget.address}",
                          textAlign: pw.TextAlign.left,
                          style: pw.TextStyle(
                            font: pw.Font.times(),
                            fontWeight: pw.FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
      // Subject outside the border
      pw.Padding(
        padding: pw.EdgeInsets.only(top: 8, bottom: 8),
        child: pw.Text(
          getSubject(widget.subject),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
            font: pw.Font.times(),
          ),
        ),
      ),
    ]);
  }

  getSubject(String subject) {
    if (subject == "") {
      return "TO WHOMSOEVER IT MAY CONCERN";
    } else {
      return "Subject: " + subject;
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
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  // Load the signature image from assets
  Future<pw.ImageProvider> loadImage() async {
    final bytes = await rootBundle.load('asset/image.jpg');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  // Load Sanjay's signature image
  Future<pw.ImageProvider> loadSanjaySignature() async {
    final bytes = await rootBundle.load('asset/image.jpg');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  // Load Pankaj's signature image
  Future<pw.ImageProvider> loadPankajSignature() async {
    final bytes = await rootBundle.load('asset/pankaj.jpg');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  // Load the stamp image from assets
  Future<pw.ImageProvider> loadStampImage() async {
    final bytes = await rootBundle.load('asset/stamp.png');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  // Load Sanjay's signature for UI display
  Future<ImageProvider> loadSanjaySignatureForUI() async {
    final bytes = await rootBundle.load('asset/image.jpg');
    return MemoryImage(bytes.buffer.asUint8List());
  }

  // Load Pankaj's signature for UI display
  Future<ImageProvider> loadPankajSignatureForUI() async {
    final bytes = await rootBundle.load('asset/pankaj.jpg');
    return MemoryImage(bytes.buffer.asUint8List());
  }

  pdfGenerator(
      String address, String subject, Timestamp dateTime, String Letterbody,
      {String signatureType = 'signature1', bool includeStamp = false}) async {
    // Assuming the original dimensions are known or can be calculated
    final originalWidth = 400.0; // Replace with actual width in points
    final originalHeight = 200.0; // Replace with actual height in points

    // Calculate new dimensions (1/2 of original)
    var newWidth = originalWidth / 2;
    var newHeight = originalHeight / 2;

    try {
      // Load the appropriate signature based on signatureType
      pw.ImageProvider signatureImage;
      if (signatureType == 'signature1') {
        signatureImage = await loadSanjaySignature();
      } else {
        signatureImage = await loadPankajSignature();
        newHeight = newHeight / 2;
        newWidth = newWidth / 2;
      }

      // Load stamp image if requested
      pw.ImageProvider stampImage;
      if (includeStamp) {
        try {
          stampImage = await loadStampImage();
        } catch (e) {
          // If stamp image doesn't exist, continue without it
          print('Stamp image not found: $e');
          stampImage = null;
        }
      } else {
        stampImage = null;
      }

      if (mounted) {
        setState(() {
          loaderText = "Generating Pdf...";
        });
      }

      widget.address = address;
      widget.subject = subject;
      widget.datetime = dateTime;

      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        header: _buildHeader,
        footer: _buildFooter,
        build: (pw.Context context) => [
          // Write letter body here,
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 50),
            child: pw.Text(Letterbody),
          ),
          pw.Padding(
            padding: pw.EdgeInsets.only(top: 50),
            child: pw.Text(
              "For Mahesh Pharma",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 5), // Add space between text and signature
          pw.Image(
            signatureImage,
            width: newWidth,
            height: newHeight,
          ), // Add the signature image here
          // Signature name directly below signature
          pw.Text(
            signatureType == 'signature1'
                ? "Sanjay Kumar Agrawal (Prop.)"
                : "Pankaj Kumar Agrawal",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          // Stamp positioned to the right of signature (if requested)
          if (includeStamp && stampImage != null)
            // pw.Align(
            //   alignment: pw.Alignment.center,
            //   child: pw.Container(
            //     margin:
            //
            pw.SizedBox(
                height:
                    5), //  pw.EdgeInsets.only(top: -40), // Overlap with signature area
          pw.Image(
            stampImage,
            width: 75, // Smaller stamp size
            height: 75,
          ),
          //   ),
          // ),
        ],
      ));

      final pdfBytes = List.from(await doc.save());
      if (pdfBytes.length > 0) {
        await openFile(pdfBytes.cast<int>());
      } else {
        throw Exception('Failed to generate PDF bytes');
      }
    } catch (e) {
      throw Exception('PDF generation failed: $e');
    }
  }

  static Future<void> openFile(List<int> bytes) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File(
          "${output.path}/letter_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(bytes);
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        throw Exception('Failed to open file: ${result.message}');
      }
    } catch (e) {
      throw Exception('Failed to save or open PDF: $e');
    }
  }

  Future<String> fetchAIExplanation(String letterText) async {
    // TODO: Move API key to environment variables or secure storage
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=AIzaSyChcU73LdC9_Mv6KXUOGOIlXl1ht2lYXL8';

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "You are my AI copilot. I will give you a prompt in which I will informally write a business letter, your job is to make the letter content formal. Also you can add few words to make it look more appealing. Do not add subject or Dear [Recipient] and Sincerely. The informal letter is $letterText"
            }
          ]
        }
      ]
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['candidates'] != null &&
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0]['content'] != null &&
            jsonResponse['candidates'][0]['content']['parts'] != null &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty) {
          return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        } else {
          throw Exception('Invalid response format from AI service');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }
}
