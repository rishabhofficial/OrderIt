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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
        title: new Text(
          "Letter Templates",
          style: TextStyle(
              color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('Letters').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot prodList = snapshot.data.docs[index];
                  return Column(children: <Widget>[
                    Card(
                      elevation: 20.0,
                      margin: new EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 6.0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Color.fromRGBO(64, 75, 96, .9)),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 15.0, vertical: 10.0),
                          leading: Container(
                            padding: EdgeInsets.only(right: 8.0),
                            decoration: new BoxDecoration(
                                border: new Border(
                                    right: new BorderSide(
                                        width: 1.0, color: Colors.white24))),
                            child: IconButton(
                              icon: Icon(Icons.edit_note_outlined,
                                  color: Colors.white, size: 35),
                              onPressed: () {
                                _showEditLetterForm(context, prodList.id);
                              },
                            ),
                          ),
                          title: Text(
                            '${prodList['letterTo']}',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                            maxLines: 1,
                          ),

                          subtitle: Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Text("Date: ",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                  Text('${prodList['letterDate']}',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16))
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  Text("Subject: ",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                  Expanded(
                                      flex: 1,
                                      child: Text(
                                          '${prodList['letterSubject']}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)))
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.all(8.0),
                                color: Color.fromRGBO(64, 75, 96, 1.0),
                                child: Text(
                                  '${prodList['letterBody']}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16), // White text
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          // trailing: IconButton(
                          //   icon: Icon(Icons.arrow_drop_down,
                          //       color: Colors.white, size: 30.0),
                          //   onPressed: () {},
                          // ),
                        ),
                      ),
                    )
                  ]);
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
        onPressed: () {
          _showAddLetterForm(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showEditLetterForm(BuildContext context, String letterId) {
    final _formKey = GlobalKey<FormState>();
    String letterDate;

    // Create TextEditingControllers
    TextEditingController letterToController = TextEditingController();
    TextEditingController letterSubjectController = TextEditingController();
    TextEditingController letterBodyController = TextEditingController();

    // Fetch existing letter details
    FirebaseFirestore.instance
        .collection('Letters')
        .doc(letterId)
        .get()
        .then((doc) {
      if (doc.exists) {
        letterToController.text = doc['letterTo'];
        letterDate = doc['letterDate'];
        letterSubjectController.text = doc['letterSubject'];
        letterBodyController.text = doc['letterBody'];

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Edit Letter"),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildTextField("To", letterToController, maxLines: 3),
                      _buildDateField(context, (value) => letterDate = value),
                      _buildTextField("Subject", letterSubjectController,
                          maxLines: 3),
                      _buildTextField("Body", letterBodyController,
                          maxLines: 5, minLines: 1),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text("Generate PDF"),
                  onPressed: () {
                    Navigator.pop(context);
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
                                      padding: EdgeInsets.only(left: 18),
                                      child: CircularProgressIndicator(),
                                    ),
                                    new Padding(
                                      padding: EdgeInsets.all(14),
                                      child: Text(
                                        loaderText,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    )
                                  ],
                                )),
                          );
                        });
                    pdfGenerator(
                            letterToController.text,
                            letterSubjectController.text,
                            Timestamp.fromDate(DateTime.parse(letterDate)),
                            letterBodyController.text)
                        .then((value) {
                      Navigator.pop(context);
                    });
                  },
                ),
                TextButton(
                  child: Text("Update"),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      // Save text from controllers
                      String letterTo = letterToController.text;
                      String letterSubject = letterSubjectController.text;
                      String letterBody = letterBodyController.text;

                      // Update letter in Firestore
                      FirebaseFirestore.instance
                          .collection('Letters')
                          .doc(letterId)
                          .update({
                        'letterTo': letterTo,
                        'letterDate': letterDate,
                        'letterSubject': letterSubject,
                        'letterBody': letterBody,
                        'updatedAt': Timestamp.now(),
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
                TextButton(
                  child: Text("Cancel", style: TextStyle(color: Colors.red)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
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
      child: Card(
        elevation: 2,
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(10),
            // Conditionally add suffixIcon if the label is "Body"
            suffixIcon: label == 'Body'
                ? IconButton(
                    icon: Icon(Icons.generating_tokens),
                    onPressed: () async {
                      String explanation =
                          await fetchAIExplanation(controller.text);
                      setState(() {
                        controller.text =
                            "Dear Sir/Madam\n\n\n\n" + explanation;
                      });
                    },
                  )
                : null, // Replace with your desired icon
          ),
          validator: (value) {
            if (value.isEmpty) return "Please enter $label.";
            return null;
          },
          maxLines: maxLines,
          minLines: minLines,
        ),
      ),
    );
  }

  void _showAddLetterForm(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String letterTo, letterDate, letterSubject, letterBody;

    // Create TextEditingControllers
    TextEditingController letterToController = TextEditingController();
    TextEditingController letterSubjectController = TextEditingController();
    TextEditingController letterBodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Letter"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildTextField("To", letterToController, maxLines: 10),
                  _buildDateField(context, (value) => letterDate = value),
                  _buildTextField("Subject", letterSubjectController,
                      maxLines: 3),
                  _buildTextField("Body", letterBodyController,
                      maxLines: 50, minLines: 1),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Add"),
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                  // Add letter to Firestore
                  FirebaseFirestore.instance.collection('Letters').add({
                    'letterTo': letterTo,
                    'letterDate': letterDate,
                    'letterSubject': letterSubject,
                    'letterBody': letterBody,
                    'createdAt': Timestamp.now(),
                    'updatedAt': Timestamp.now(),
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateField(BuildContext context, Function(String) onSaved) {
    String selectedDate;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 2,
        child: GestureDetector(
          onTap: () async {
            DateTime pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              selectedDate =
                  "${pickedDate.toLocal()}".split(' ')[0]; // Format as needed
              onSaved(selectedDate);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: "Date",
              border: OutlineInputBorder(),
            ),
            child: Text(
              selectedDate ?? 'Select a date',
              style: TextStyle(
                  color: selectedDate == null ? Colors.grey : Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Card(
      elevation: 2,
      child: SwitchListTile(
        title: Text(title),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildLetterCard(BuildContext context, DocumentSnapshot prodList) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        color: Colors.grey[800], // Light grey card color
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildFixedSizeRow("To:", '${prodList['letterTo']}', 1.5),
              _buildFixedSizeRow("Date:",
                  prodList['letterDate'].toString().split(' ')[0], 1.0),
              _buildFixedSizeRow(
                  "Subject:", '${prodList['letterSubject']}', 1.5),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  prodList['letterBody'],
                  style: TextStyle(
                      fontSize: 16, color: Colors.white), // White text
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'Edit') {
                      _showEditLetterForm(context, prodList.id);
                    } else if (value == 'Generate PDF') {
                      //   _generatePDF(prodList.id);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return {'Edit', 'Generate PDF'}.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice,
                            style: TextStyle(
                                color: Colors.white)), // White text in menu
                      );
                    }).toList();
                  },
                  icon:
                      Icon(Icons.more_vert, color: Colors.white), // White icon
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedSizeRow(String label, String value, double spaceFactor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white), // White label
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: spaceFactor.toInt(),
          child: Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.white), // White text
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
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

  pdfGenerator(String address, String subject, Timestamp dateTime,
      String Letterbody) async {
    final signatureImage = await loadImage();
    // Assuming the original dimensions are known or can be calculated
    final originalWidth = 400.0; // Replace with actual width in points
    final originalHeight = 200.0; // Replace with actual height in points

    // Calculate new dimensions (1/2 of original)
    final newWidth = originalWidth / 2;
    final newHeight = originalHeight / 2;

    setState(() {
      loaderText = "Generating Pdf...";
    });

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
        pw.SizedBox(height: 5), // Add space after the image
        pw.Text(
          "Sanjay Kumar Agrawal (Prop.)",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    ));

    final pdfBytes = List.from(await doc.save());
    if (pdfBytes.length > 0) {
      openFile(pdfBytes.cast<int>());
    }
  }

  static void openFile(List<int> bytes) async {
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/" + "letter" + ".pdf");
    await file.writeAsBytes(bytes);
    OpenFile.open(file.path);
  }

  Future<String> fetchAIExplanation(String letterText) async {
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=AIzaSyDkHQCehKnqRr_I8TeWeLcG-JrPgg1A9W8';

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text":
                  "You are my AI copilot. I will give you a prompt in which I will informally write a business letter, your job is to make the letter content formal. Also you can add few words to make it look more appealing. Do not add subject or Dear [Recipeint] and Sincerely. The informal letter is $letterText"
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
        print(jsonResponse['candidates'][0]['content']['parts'][0]['text']);
        return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error occurred: $e');
    }
  }
}
