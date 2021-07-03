import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:startup_namer/model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:intl/intl.dart';

int claim;
 
  
  String address = "";
  String location = "";
  String code = "";
  List<dynamic> divi;
  List<ExpiryProductData> partyWiseList = List();

class PartyReport extends StatefulWidget {
  
  @override
  _PartyReportState createState() => _PartyReportState();
}


class _PartyReportState extends State<PartyReport> {

  double mrpValue = 0.0;
  @override
  void initState() {
    print("Inside Init");
    setState(() {
      mrpValue = 0.0;
      batch.clear();
      populateComp();
      //print(_companies);
    });
    super.initState();    
  }
  List<String> batch = List();
  static void openFile(List<int> bytes) async {
    //print("Inside openFile===========>>");
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/"+ code +".pdf");
    await file.writeAsBytes(bytes);
    OpenFile.open(file.path);
  }
  
  Map<String,List<ProductData>> fillData(DateTime date) {
    print("Inside FillData");
    mrpValue = 0.0;
    batch.clear();
    
    Map<String,List<ProductData>> m = Map();
   
  String comp = company;
  //print(comp);
  //print(divi);
  Timestamp timestamp2 = Timestamp.fromDate(timestamp1);
  (comp=="MANKIND" || comp == "ARISTO")?
   Firestore.instance.collection('Expiry').where('timestamp', isGreaterThan: timestamp2).snapshots().listen((event) => event.documents.forEach((element) {
    Firestore.instance.collection('Expiry').document(element.documentID).collection(element['partyName']).where('compCode', whereIn: divi).snapshots().listen(
  
      (cour)=> cour.documents.forEach((doc) {
                print("Inside Firestore");
          ProductData prod = ProductData();
          ExpiryProductData product = ExpiryProductData();
          prod.qty = int.parse(doc.data['prodQty']).toString();
          prod.name = doc.data['prodName'];
          prod.pack = doc.data['prodPack'];
          prod.mrp  = doc.data['prodMrp'];
          prod.expiryDate = doc.data['prodExpiryDate'];
          prod.batchNumber = doc.data['prodBatchNumber'];
          prod.compCode = doc.data['compCode'];
          product.qty = int.parse(doc.data['prodQty']).toString();
          product.name = doc.data['prodName'];
          product.pack = doc.data['prodPack'];
          product.mrp  = doc.data['prodMrp'];
          product.expiryDate = doc.data['prodExpiryDate'];
          product.batchNumber = doc.data['prodBatchNumber'];
          product.compCode = doc.data['compCode'];
          product.partyName = element['partyName'];
          product.colDocId = element.documentID;
          product.docId = doc.documentID;        
          partyWiseList.add(product);
        mrpValue += double.parse(prod.qty) * prod.mrp;
        bool test =false;
        if(m.containsKey(doc.data['prodName'])){
          for(int i=0;i<m[prod.name].length;i++){
            if(m[prod.name][i].batchNumber == prod.batchNumber){
              m[prod.name][i].qty = (int.parse(m[prod.name][i].qty) + int.parse(prod.qty)).toString();
              test = true;
              break;
            }
            
          }
          if(test == false){
              m[prod.name].add(prod);
            }
          //print("Inside==================>>>>");
        }
        else{       
          batch.add(prod.name);
          //print("Hiiiiiiiii");
          if(!m.containsKey(prod.name)){
            m[prod.name] = []; 
          }
          m[prod.name].add(prod);
          
          //print(batch);
        }  
        //print("qty====>>" + m[doc.data['prodName']].toString());       
      }
    )
  );
}) ):
Firestore.instance.collection('Expiry').where('timestamp', isGreaterThan: timestamp2).snapshots().listen((event) => event.documents.forEach((element) {
    Firestore.instance.collection('Expiry').document(element.documentID).collection(element['partyName']).where('compCode', isEqualTo: comp).snapshots().listen(
  
      (cour)=> cour.documents.forEach((doc) {
                print("Inside firestore2");
          ProductData prod = ProductData();
          ExpiryProductData product = ExpiryProductData();
          prod.qty = int.parse(doc.data['prodQty']).toString();
          prod.name = doc.data['prodName'];
          prod.pack = doc.data['prodPack'];
          prod.mrp  = doc.data['prodMrp'];
          prod.expiryDate = doc.data['prodExpiryDate'];
          prod.batchNumber = doc.data['prodBatchNumber'];
          product.qty = int.parse(doc.data['prodQty']).toString();
          product.name = doc.data['prodName'];
          product.pack = doc.data['prodPack'];
          product.mrp  = doc.data['prodMrp'];
          product.expiryDate = doc.data['prodExpiryDate'];
          product.batchNumber = doc.data['prodBatchNumber'];
          product.compCode = doc.data['compCode'];
          product.partyName = element['partyName'];
          product.colDocId = element.documentID;
          product.docId = doc.documentID;        
          partyWiseList.add(product);
        mrpValue += double.parse(prod.qty) * prod.mrp;
        //print(prod.name + "  " + doc.data['compCode'].toString());
        bool test =false;
        if(m.containsKey(doc.data['prodName'])){
          for(int i=0;i<m[prod.name].length;i++){
            if(m[prod.name][i].batchNumber == prod.batchNumber){
              m[prod.name][i].qty = (int.parse(m[prod.name][i].qty) + int.parse(prod.qty)).toString();
              test = true;
              break;
            }
            
          }
          if(test == false){
              m[prod.name].add(prod);
            }
          //print("Inside==================>>>>");
        }
        else{       
          batch.add(prod.name);
          //print("Hiiiiiiiii");
          if(!m.containsKey(prod.name)){
            m[prod.name] = []; 
          }
          m[prod.name].add(prod);
          
          //print(batch);
        }  
        //print("qty====>>" + m[doc.data['prodName']].toString());       
      }
    )
  );
}) );   
  return m;
} 



pdfGeneratorDivWise(dynamic m){
  print("Indide Generate Pdf");
  
  final doc = pw.Document();
  //print(batch);
  Map<String,List<List<String>>> trial = Map();
  
   var element = (["S.No.", "Product" , "Pack" , "QTY","MRP", "E/D", "Batch No."]);
    //print("Hii....................LALALALALALLAa" + m.toString());
    //print("Hii....................LALALALALALLAa" + m[batch[1]].toString());

  for(int i = 0 ;i< m.length;i++){
    for(int j=0; j<m[batch[i]].length;j++){
    if(trial.containsKey(m[batch[i]][j].compCode)){
      trial[m[batch[i]][j].compCode].add([(trial[m[batch[i]][j].compCode].length+1).toString(),m[batch[i]][j].name,m[batch[i]][j].pack,m[batch[i]][j].qty,m[batch[i]][j].mrp.toString(),m[batch[i]][j].expiryDate,m[batch[i]][j].batchNumber]);
    }
    else{
      trial[m[batch[i]][j].compCode] = [];
      trial[m[batch[i]][j].compCode].add([(1).toString(),m[batch[i]][j].name,m[batch[i]][j].pack,m[batch[i]][j].qty,m[batch[i]][j].mrp.toString(),m[batch[i]][j].expiryDate,m[batch[i]][j].batchNumber]);    
    }
    }}
  //print("Hii....................LALALALALALLAaqqqqqqqq");
    //trial.sort((a,b)=>a[1].compareTo(b[1]));
  for(int x=0; x<divi.length;x++){
    if(trial.containsKey(divi[x])){
      trial[divi[x]].insert(0, element);
    }
    
    //print(trial);
    }
    
  doc.addPage( 
  
    pw.MultiPage(
      //margin: pw.EdgeInsets.only(top:5,bottom:5),
      header: _buildHeader,
      footer: _buildFooter,
      build: (pw.Context context) => [
          pw.Wrap(children:
            List.generate(divi.length, (index){
              return (trial.containsKey(divi[index]))?
                pw.Column(children: <pw.Widget>[
                    pw.Padding(child: pw.Text(divi[index]),
                    padding: pw.EdgeInsets.only(top: 12 ,bottom: 12)),
                    pw.Table.fromTextArray(context: context, data: trial[divi[index]], cellAlignment: pw.Alignment.topLeft),
                ]):pw.Container(width: 0, height: 0);
              
            })
          ),
           pw.Padding(padding: pw.EdgeInsets.only(top: 10),
          child: pw.Text("Total MRP Value(Rupees): " + mrpValue.toStringAsFixed(2)))

          

      ]
    )
  );

  final pdfBytes = doc.save(); 
  if(pdfBytes.length > 0) {
    openFile(pdfBytes);
  }
}



pdfGenerator(dynamic m){
  
  final doc = pw.Document();
  //print(batch);
  List<List<String>> trial = List();
  
   var element = (["S.No.", "Product" , "Pack" , "QTY","MRP", "E/D", "Batch No."]);
  int a=0;
  
  for(int i = 0 ;i< m.length;i++){
    for(int j=0; j<m[batch[i]].length;j++){
      trial.add([m[batch[i]][j].name,m[batch[i]][j].pack,m[batch[i]][j].qty,m[batch[i]][j].mrp.toString(),m[batch[i]][j].expiryDate,m[batch[i]][j].batchNumber]);
    }}
    trial.sort((a,b)=>a[0].compareTo(b[0]));
    a=1;
    for(int i=0;i<trial.length;i++){
      trial[i].insert(0, a.toString());
      a++;
    }
    trial.insert(0, element);
    //print(trial);
    
  doc.addPage(
    pw.MultiPage(
      header: _buildHeader,
      footer: _buildFooter,
      build: (pw.Context context) => [
          pw.Table.fromTextArray(context: context, data: trial, cellAlignment: pw.Alignment.topLeft),
          pw.Padding(padding: pw.EdgeInsets.only(top: 10),
          child: pw.Text("Total MRP Value(Rupees): " + mrpValue.toStringAsFixed(2)))

      ]
    )
  );

  final pdfBytes = doc.save(); 
  if(pdfBytes.length > 0) {
    openFile(pdfBytes);
  }
}

 
  void _populate_comp_details(String comp){
    if(comp.contains("MANKIND")){
      company = "MANKIND";

      //divi.clear();
      divi = ["MANKIND-CURIS","MANKIND-DISCOVERY","MANKIND-LIFESTAR","MANKIND-FUTURE","MANKIND-MAIN","MANKIND-MAGNET","MANKIND-NOBLIS","MANKIND-SPECIAL"];
    }
    if(comp.contains("ARISTO")){
      company = "ARISTO";
      divi = ["ARISTO-MF1","ARISTO-MF2","ARISTO-MF3","ARISTO-TF","ARISTO-GENETICA"];
    }
    Firestore.instance.collection("Company").where('compName', isEqualTo : comp).snapshots().listen((event) {
      event.documents.forEach((value) {
        address = (value.data['compMailingName']== null)?"":value.data['compMailingName'];
        location = (value.data['compMailingLocation']== null)?"":value.data['compMailingLocation'];
        code = (value.data['compCode']== null)?"":value.data['compCode'];
      });
    });
       
  
  }

List<String> _companies = List();
String company;
  void populateComp(){
  _companies.clear();
    Firestore.instance.collection("Company").orderBy('compName').snapshots().listen((event) {
      event.documents.forEach((element) {
        if(!_companies.contains(element.data['compName']))
        _companies.add(element.data['compName']); 
      });
    });
    //print(_companies);
  }
  final _sKey = GlobalKey<ScaffoldState>(); 
  DateTime timestamp1; 
  final format = DateFormat("yyyy-MM-dd");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _sKey,
      appBar:  new AppBar(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
        leading: new IconButton(icon: Icon(Icons.arrow_back), onPressed: () {
          Navigator.pop(context);
        }),
        title: new Text("Expiry Report", style: TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w600),),
        actions: <Widget>[        
          Padding(
                padding: const EdgeInsets.only(right: 12.0),
                                  child: IconButton(icon: Icon(Icons.refresh), onPressed: () {
                                    populateComp();
                                    setState(() {
                                      
                                    });
                                  } )
              
              ),
        ],
        //backgroundColor: Colors.blueAccent,
      ),
      body: Container(
          width: 500,
        decoration: BoxDecoration(
         color: Colors.grey[100]
        ),
        child: new Column(
          children: <Widget>[
            // Padding(
            //   padding: EdgeInsets.only(top: 10),
            //   child: Text("Enter Company Details", textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),)
            // ),
            
             Padding(
              padding: EdgeInsets.only(top:60,left:60,right:60,bottom:5),
              child: DropdownButton(
                isExpanded: true,               
                style: TextStyle(fontSize: 16, color: Colors.black),
                icon: Icon(Icons.business),
                hint: Text("Select Company"),
                value: company,
                onChanged: (newValue){
                setState(() {
                  
                    company = newValue;
                  
                  
                });
              },
                items: _companies.map((comp){
                  return DropdownMenuItem(child: new Text(comp),
                  value: comp,);
                }).toList(),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left:60,right:50,),
              child: DateTimeField(
                format: format,
                decoration: InputDecoration(suffixIcon: Icon(Icons.calendar_today),
                  labelText: "Starting Date",
               ),
                onShowPicker: (context, currentValue) {
                  return showDatePicker(
                    context: context,
                    firstDate: DateTime(2015),
                    fieldLabelText: "Starting Date",
                    initialDate: currentValue ?? DateTime.now(),
                    lastDate: DateTime(2100));
                  },
                  onChanged: (newValue){
                      timestamp1 = newValue;
                  },
              )
            ),
            Padding(
              padding: EdgeInsets.only(left:60,right:50,bottom: 30),
              child: DateTimeField(
                format: format,
                decoration: InputDecoration(suffixIcon: Icon(Icons.calendar_today),
                  labelText: "Ending Date",
               ),
                onShowPicker: (context, currentValue) {
                  return showDatePicker(
                    context: context,
                    firstDate: DateTime(2017),
                    fieldLabelText: "Ending Date",
                    initialDate: currentValue ?? DateTime.now(),
                    lastDate: DateTime(2100));
                  },
              )
            ),
            Padding(
              padding: const EdgeInsets.only(left:290),
              child: ClipOval(
                child: Material(
                  color: Colors.grey, // button color
                  child: InkWell(
                    splashColor: Colors.black, // inkwell color
                    child: SizedBox(width: 56, height: 56, child: Icon(Icons.arrow_forward, color: Colors.white,)),
                      onTap: () async {
                      try {
                        final result = await InternetAddress.lookup('google.com');
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
                                    padding: EdgeInsets.only(left: 18),
                                    child: CircularProgressIndicator(),),
                                    new Padding(
                                      padding: EdgeInsets.all(14),
                                      child: Text("Loading", style: TextStyle(
                                      fontSize: 16
                                      ),),
                                    )
                                  ],
                                )),
                              );
                            },
                          );
                          print("Before populate Comp details");
                          //divi.clear();
                           _populate_comp_details(company);
                           print("After populate Comp details");
                           //print(company);
                          var x = fillData(DateTime.now());
                          //print("x=" + x.toString());
                            new Future.delayed(new Duration(seconds: 5), () {
                            Navigator.of(context).pop();
                            print("Inside Future" + x.length.toString()); 
                            if(x.length == 0){
                              final snackbar = SnackBar(content: Text("No Data Found"));
                              _sKey.currentState.showSnackBar(snackbar);
                            } 
                           else   
                              //Navigator.push(context, MaterialPageRoute(builder: (context) => CompExpiryReport()));  
                              print("x==================>>>>>>>>>>>>>" + x.toString());       
                             (company == "MANKIND" || company == "ARISTO")?pdfGeneratorDivWise(x):pdfGenerator(x);
                            });
                        }
                      } on SocketException catch (_) {
                        final snackbar = SnackBar(content: Text("Please check your internet connection"));
                          _sKey.currentState.showSnackBar(snackbar);
                      }
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
pw.Widget _buildHeader(pw.Context context) {
    return pw.Column(children: <pw.Widget>[
      pw.Container(
            decoration: new pw.BoxDecoration(
                          border: new pw.BoxBorder(
                                left: true,right: true, top: true,bottom: true)),width: double.infinity,  
          child: pw.Row(children: <pw.Widget>[
            pw.Container(padding: pw.EdgeInsets.all(12.0),
                      decoration: new pw.BoxDecoration(
                          border: new pw.BoxBorder(
                                right: true)),
                          child:pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: <pw.Widget>[
              pw.Text("MAHESH PHARMA", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.bold, fontSize: 14)),
              //pw.Text("STATION ROAD", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 8)),
              pw.Text("GONDA (U.P.)", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 10)),
              pw.Text("GST No:- 09ACTPA5656M1ZX", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 8)),
              pw.Text("DL No:- UP4320B000615/UP4321B000615", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 8)),
              pw.Container(height: 5),

              pw.Text("CLAIM NO. - MP/"+ DateTime.now().month.toString() + "/"+ DateTime.now().year.toString() + "/"+ code, textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text("DT - " + DateTime.now().day.toString() + "/" + DateTime.now().month.toString() + "/" + DateTime.now().year.toString(), textAlign: pw.TextAlign.right  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 10))
            ])),
              pw.Expanded(child: pw.Container(padding: pw.EdgeInsets.only(right:8,top:8,bottom: 8),
                  decoration: pw.BoxDecoration(border: pw.BoxBorder()),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: <pw.Widget>[

              pw.Padding(
                padding: pw.EdgeInsets.only(left: 10),
                child: pw.Text("To,", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times() ,fontWeight: pw.FontWeight.bold, fontSize: 14))
              ),
              pw.Padding(child: pw.Text("  M/S " + address, textAlign: pw.TextAlign.right  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 13)),
              padding: pw.EdgeInsets.only(left: 12)),
              pw.Padding(padding: pw.EdgeInsets.only(left:12),
                child: pw.Text("  "+location, textAlign: pw.TextAlign.right  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 13))
              ),
              //  pw.Padding(padding: pw.EdgeInsets.only(left:12),
              //   child: pw.Text("  DT - " + DateTime.now().day.toString() + "/" + DateTime.now().month.toString() + "/" + DateTime.now().year.toString(), textAlign: pw.TextAlign.right  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 10))
              // )
            ]),
              ))
            
          ])
        ),
        pw.Padding(padding: pw.EdgeInsets.only(top: 14, bottom: 8),
        child: pw.Text("Expired/Breakage Goods Report", 
          textAlign: pw.TextAlign.center,  
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
            font: pw.Font.times()
            )))
    ]);
  }

}

pw.Widget _buildHeader1(pw.Context context) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Container(
                    height: 50,
                    padding: const pw.EdgeInsets.only(left: 20),
                    alignment: pw.Alignment.topLeft,
                    child: pw.Column(children: <pw.Widget>[
              pw.Text("MAHESH PHARMA", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text("STATION ROAD", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 8)),
              pw.Text("GONDA (U.P.)-271002 ", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize:8)),
              pw.Text("GST No:- 09ACTPA5656M1ZX", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 8)),
              pw.Text("DL No:- UP4320B000615/UP4321B000615", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 8)),
            ])
              ),
                  pw.Container(
                    color: PdfColors.black,
                    alignment: pw.Alignment.centerLeft,
                    height: 50,
                    child: pw.DefaultTextStyle(
                      style: pw.TextStyle(
                        fontSize: 12,
                      ),
                      child: pw.GridView(
                        crossAxisCount: 2,
                        children: [
                          pw.Text('Claim No. '),
                          pw.Text(claim.toString()),
                          pw.Text('Date: '),
                          pw.Text(DateTime.now().day.toString() + "/" + DateTime.now().month.toString() + "/" + DateTime.now().year.toString()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.max,
                children: [
                  pw.Container(
                    alignment: pw.Alignment.topLeft,
                    padding: const pw.EdgeInsets.only(bottom: 8, left: 10),
                    height: 72,
                    child: pw.Column(children: <pw.Widget>[
              pw.Padding(
                padding: pw.EdgeInsets.only(right: 50),
                child: pw.Text("To,", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times() ,fontWeight: pw.FontWeight.bold, fontSize: 14))
              ),
              pw.Padding(child: pw.Text("M/S " + address, textAlign: pw.TextAlign.right  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 12)),
              padding: pw.EdgeInsets.only(right: 12)),
              pw.Padding(padding: pw.EdgeInsets.only(right:12),
                child: pw.Text(location, textAlign: pw.TextAlign.right  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 12))
              ),
              
            ]),
                  ),
                  // pw.Container(
                  //   color: baseColor,
                  //   padding: pw.EdgeInsets.only(top: 3),
                  // ),
                ],
              ),
            ),
          ],
        ),
        if (context.pageNumber > 1) pw.SizedBox(height: 20)
      ],
    );
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


//   class CompExpiryReport extends StatefulWidget {
//   @override
//   _CompExpiryReport createState() => _CompExpiryReport();
// }

// class _CompExpiryReport extends State<CompExpiryReport> {


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: new AppBar(
//         backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
//         title: new Text("Report", style: TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.w600),),
//        actions: [
//          Padding(padding: EdgeInsets.only(right: 4),
//           child: IconButton(icon: Icon(Icons.add, size: 30,), onPressed: (){
//   //           Navigator.push(
//   //                   context,
//   //                 MaterialPageRoute(builder: (context) => AllProductPage(data: widget.data, docID: "", check: false)),
//   // );
//           },)
//          ),
//          Padding(
//                 padding: const EdgeInsets.only(right: 16.0),
//                 child: PopupMenuButton(
//                  // initialValue: 1,
//                   onSelected: (int) {
//                     //Navigator.push(context, MaterialPageRoute(builder: (context) => ProductForm(widget.data.name)));
//                    },
//                   itemBuilder: (context) => [
//                     PopupMenuItem(
//                       value: 1,
//                       child: Center(child: Text("Reports")),
                      
//                     )
//                   ]
//                 ),
//               ),
//        ],
//         //backgroundColor: Colors.blueAccent,
//       ),
//       body: ListView.builder(
//             scrollDirection: Axis.vertical,
//             shrinkWrap: true,
//             itemCount: partyWiseList.length,
//             itemBuilder: (context, index) {
//               return Column(
//                children: <Widget>[
    
//                       Card(
//       elevation: 10.0,
//       margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
//       child: Container(
//         decoration: BoxDecoration(color: Color.fromRGBO(200, 200, 200, .4)),
//         child: ListTile(
//         contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
//         leading: Container(
//           padding: EdgeInsets.only(right: 2.0, top: 5),
//           decoration: new BoxDecoration(
//               border: new Border(
//                   right: new BorderSide(width: 0.5, color: Colors.white24))),
//           child: IconButton(icon: Icon(Icons.edit), iconSize: 25 ,onPressed: (){
//                                       TextEditingController _name   = TextEditingController(text: partyWiseList[index].name);
//                                       TextEditingController _pack   = TextEditingController(text: partyWiseList[index].pack);
//                                       TextEditingController _mrp    = TextEditingController(text: partyWiseList[index].mrp.toString());
//                                       TextEditingController _expiry = TextEditingController(text: partyWiseList[index].expiryDate);
//                                       TextEditingController _batch  = TextEditingController(text: partyWiseList[index].batchNumber);
//                                       TextEditingController _qty    = TextEditingController(text: partyWiseList[index].qty);
//                                       TextEditingController _deal1  = TextEditingController(text: partyWiseList[index].deal1.toString());
//                                       TextEditingController _deal2  = TextEditingController(text: partyWiseList[index].deal2.toString());
//                                       FocusNode qtyFocusNode = new FocusNode();
//                                       FocusNode pack         = new FocusNode();
//                                       FocusNode mrp          = new FocusNode();
//                                       FocusNode expiry       = new FocusNode();
//                                       FocusNode batch1       = new FocusNode();
//                                       FocusNode deal1        = new FocusNode();
//                                       FocusNode deal2        = new FocusNode();
//                                       bool _validate  = false;
//                                       showDialog(                                             
//                                         context: context,
//                                         builder: (context) {
//                                          // FocusNode inputOne = FocusNode();
//                                           return AlertDialog(
//                                            // contentPadding: EdgeInsets.all(0.0),
//                                             title: new Text('${partyWiseList[index].name}'),
//                                             content: Column(mainAxisSize: MainAxisSize.min ,children: <Widget>[
//                                             TextField(
//                                               autofocus: true,
//                                               keyboardType: TextInputType.text,
//                                               controller: _name,
//                                               decoration: new InputDecoration(
//                                               contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                               labelText: "Name",
//                                               //errorText: _validate ? "*Required" : null,
//                                               fillColor: Colors.black,
//                                               border: new OutlineInputBorder(
//                                                 borderRadius: new BorderRadius.circular(15.0), 
//                                                 borderSide: new BorderSide(),
//                                                 ),
//                                               ),
//                                               onChanged: (text) {
//                                                 partyWiseList[index].name = _name.text;
//                                               },
//                                               onSubmitted: (text) {
//                                                 FocusScope.of(context).requestFocus(pack);
//                                               },                                           
//                                             ),
//                                             Padding(
//                                               padding: EdgeInsets.only(top: 8),
//                                               child: TextField(
//                                                 focusNode: pack,
//                                                 keyboardType: TextInputType.text,
//                                                 controller: _pack,
//                                                 decoration: new InputDecoration(
//                                                 contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                                 labelText: "Pack",
//                                                 //errorText: _validate ? "*Required" : null,
//                                                 fillColor: Colors.black,
//                                                 border: new OutlineInputBorder(
//                                                   borderRadius: new BorderRadius.circular(15.0), 
//                                                   borderSide: new BorderSide(),
//                                                   ),),
//                                               onChanged: (text) {
//                                                 partyWiseList[index].pack = _pack.text;
//                                                 },
//                                                 onSubmitted: (text) {
//                                                   FocusScope.of(context).requestFocus(mrp);
//                                                 },
                                            
//                                               //prod.qty = _textFieldController.text
//                                             ),),
//                                             Padding(
                                    
//                                               padding: EdgeInsets.only(top: 8),
//                                             child: TextField(
//                                               focusNode: mrp,
//                                              // autofocus: true,
//                                               keyboardType: TextInputType.number,
//                                               controller: _mrp,
//                                               decoration: new InputDecoration(
//                               contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                labelText: "MRP",
//                                //errorText: _validate ? "*Required" : null,
//                                  fillColor: Colors.black,
//                                border: new OutlineInputBorder(
//                                  borderRadius: new BorderRadius.circular(15.0), 
//                                  borderSide: new BorderSide(),
//                                 ),),
//                                               onChanged: (text) {
//                                                 partyWiseList[index].mrp = double.parse(_mrp.text);
//                                                 },
//                                                 onSubmitted: (text) {
//                                                   FocusScope.of(context).requestFocus(expiry);
//                                                 },
//                                              ),),
//                                           Padding(
//                                             padding: EdgeInsets.only(top: 8),
//                                             child: TextField(
//                                               focusNode: expiry,
//                                               keyboardType: TextInputType.number,
//                                               controller: _expiry,
//                                               decoration: new InputDecoration(
//                                               contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                               labelText: "Expiry Date",
//                                               //errorText: _validate ? "*Required" : null,
//                                               fillColor: Colors.black,
//                                               border: new OutlineInputBorder(
//                                               borderRadius: new BorderRadius.circular(15.0), 
//                                               borderSide: new BorderSide(),
//                                               ),),
//                                               onChanged: (text) {
//                                                 partyWiseList[index].expiryDate = _expiry.text;
//                                                 },
//                                                 onSubmitted: (text) {
//                                                   FocusScope.of(context).requestFocus(batch1);
//                                                 },
                                            
//                                               //prod.qty = _textFieldController.text
//                                             ),),
//                                             Padding(
//                                               padding: EdgeInsets.only(top: 8),
//                                             child: TextField(
//                                               focusNode: batch1,
//                                              // autofocus: true,
//                                               keyboardType: TextInputType.text,
//                                               controller: _batch,
//                                               decoration: new InputDecoration(
//                                               contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                               labelText: "Batch Number",
//                                               //errorText: _validate ? "*Batch Number already used for this product" : null,
//                                               fillColor: Colors.black,
//                                               border: new OutlineInputBorder(
//                                                 borderRadius: new BorderRadius.circular(15.0), 
//                                                 borderSide: new BorderSide(),
//                                               ),),
//                                               onChanged: (text) {
//                                                 partyWiseList[index].batchNumber = _batch.text.toUpperCase();
//                                               },
//                                               onSubmitted: (text) {
//                                                   FocusScope.of(context).requestFocus(deal1);
//                                                 },
//                                               // onSubmitted: (text) {
//                                               //   if (batch.containsKey(partyWiseList[index].batchNumber) && partyWiseList[index].name == batch[partyWiseList[index].batchNumber]){
//                                               //     setState(() {
//                                               //       _validate = true;
//                                               //     });
//                                               //   }
//                                               //   else{
//                                               //   setState(() {
//                                               //     _validate = false;
//                                               //   });}}
                                             
                                            
//                                               //prod.qty = _textFieldController.text
//                                             ),),
//                                             Padding(
//                                               padding: EdgeInsets.only(top: 8),
//                                             child: Row(
//                                               children: <Widget>[
//                                                 Flexible(
//                                             child: Padding(
//                                               padding: EdgeInsets.only(right:4),
//                                                 child: TextField(
//                                                // autofocus: true,
//                                                   focusNode: deal1,
//                                                   keyboardType: TextInputType.number,
//                                                   controller: _deal1,
//                                                   decoration: new InputDecoration(
//                                                   contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                                   labelText: "Deal",
//                                                   fillColor: Colors.black,
//                                                   border: new OutlineInputBorder(
//                                                     borderRadius: new BorderRadius.circular(15.0), 
//                                                     borderSide: new BorderSide(),
//                                                    ),
//                                                   ),
//                                                   onChanged: (text) {
//                                                     if(_deal1.text == ""){
//                                                     partyWiseList[index].deal1 = 0;
//                                                   }
//                                                   else
//                                                     partyWiseList[index].deal1 = int.parse(_deal1.text);
//                                                   },
//                                                   onSubmitted: (text) {
//                                                     FocusScope.of(context).requestFocus(deal2);
//                                                   },
                                              
//                                                 //prod.qty = _textFieldController.text
//                                               ),
//                                             ),
//                                                 ),
//                                                 Icon(Icons.add),
//                                             Flexible(
//                                                   child: Padding(
//                                                        padding: EdgeInsets.only(left: 4),                                               
//                                                        child: TextField(
//                                                          focusNode: deal2,
//                                                // autofocus: true,
//                                                 keyboardType: TextInputType.number,
//                                                 controller: _deal2,
//                                                 decoration: new InputDecoration(
//                                                 contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                                 labelText: "Deal",
//                                                 fillColor: Colors.black,
//                                                 border: new OutlineInputBorder(
//                                                   borderRadius: new BorderRadius.circular(15.0), 
//                                                   borderSide: new BorderSide(),
//                                                 ),),
//                                                 onChanged: (text) {
//                                                   if(_deal2.text == ""){
//                                                     partyWiseList[index].deal2 = 0;
//                                                   }
//                                                   else
//                                                     partyWiseList[index].deal2 = int.parse(_deal2.text);
//                                                 },
//                                                     onSubmitted: (text) {
//                                                       FocusScope.of(context).requestFocus(qtyFocusNode);
//                                                     },
                                              
//                                                 //prod.qty = _textFieldController.text
//                                               ),
//                                                   ),
//                                             ),
//                                             ],), 
//                                             ),
//                                             Padding(
//                                               padding: EdgeInsets.only(top: 8),
//                                               child: TextField(
//                                               focusNode: qtyFocusNode,
//                                               keyboardType: TextInputType.number,
//                                               controller: _qty,
//                                               decoration: new InputDecoration(
//                                               contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                               labelText: "Quantity",
//                                                errorText: _validate ? "*Required" : null,
//                                                 fillColor: Colors.black,
//                                               border: new OutlineInputBorder(
//                                                 borderRadius: new BorderRadius.circular(15.0), 
//                                                 borderSide: new BorderSide(),
//                                               ),
//                                               ),                            
//                                               onSubmitted: (text) {
//                                                 if (_qty.text == ""){
//                                                   setState(() {
//                                                     _validate = true;
//                                                   });
//                                                 }
//                                                 else{
//                                                 setState(() {
//                                                   _validate = false;
//                                                 });
//                                                 partyWiseList[index].qty = _qty.text;
//                                                 Navigator.of(context).pop();
//                                                 if(partyWiseList[index].deal1 != 0 && partyWiseList[index].deal2 != 0){
//                                                 partyWiseList[index].amount = double.parse(partyWiseList[index].qty) * partyWiseList[index].mrp * (1 - (min(partyWiseList[index].deal1,partyWiseList[index].deal2)/(partyWiseList[index].deal1 + partyWiseList[index].deal2)));
//                                                 //print(widget.data.defaultDiscount);
//                                                 }
//                                                 else{
//                                                   partyWiseList[index].amount = double.parse(partyWiseList[index].qty) * partyWiseList[index].mrp;
//                                                 }
//                                                 partyWiseList[index].amount = double.parse((partyWiseList[index].amount - (widget.data.defaultDiscount/100)*partyWiseList[index].amount).toStringAsFixed(3));
                                              
                    
//                                                 // if(batch.containsKey(partyWiseList[index].batchNumber)){
//                                                 //   print("inside show");
//                                                 //   return showDialog(
//                                                 //     context: context,  
//                                                 //   builder: (BuildContext context) {  
//                                                 //     return AlertDialog(
//                                                 //       title: Text( prod.name +" with batch number " + prod.batchNumber + " already exists."),
//                                                 //       actions: [
//                                                 //         FlatButton(  
//                                                 //           child: Text("OK"),  
//                                                 //           onPressed: () {  
//                                                 //             Navigator.of(context).pop();  
//                                                 //           },  
//                                                 //         )]);
//                                                 //   });
//                                                 // }
//                                                  _qty.clear();
//                                                  _batch.clear();
//                                                  _mrp.clear(); _deal1.clear(); _deal2.clear(); _expiry.clear();
//                                                 }},
                                            
//                                             )),
//                                             ],),
                                            
//                                             actions: <Widget>[
//                                               new FlatButton(
//                                                 child: new Text("Close"),
//                                                 onPressed: () {
//                                                   Navigator.of(context).pop();
//                                                   _textFieldController.clear();
//                                                 },
//                                               ),
//                                             ],
//                                           );
//                                         },
//                                       );  
//           })
//         ),
//          title: Text('${partyWiseList[index].name}',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize:20,),
//         ),

//         subtitle: Column(
//           children: <Widget>[
//             Row(
//           children: <Widget>[
//             Text("Pack: ", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
//             Text('${partyWiseList[index].pack}', style: TextStyle(color: Colors.black)),
//             SizedBox(width: 5),
//             Text("Expiry Date: ", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
//             Text('${partyWiseList[index].expiryDate}', style: TextStyle(color: Colors.black)),
            
//             ],
//         ),
//         Row(
//           children: <Widget>[
//             Text("Batch No.: ", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
//             Text('${partyWiseList[index].batchNumber}', style: TextStyle(color: Colors.black)),
//             SizedBox(width: 5),
//             Text("MRP: ", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
//             Text('\u20B9 ${partyWiseList[index].mrp}', style: TextStyle(color: Colors.black)),

//           ],
//         ),
//         Row(
//           children: <Widget>[
//             Text("Qty: ", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
//             Text('${partyWiseList[index].qty}', style: TextStyle(color: Colors.black)),
//             SizedBox(width: 5),
//             Text("Deal: ", style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
//             Text('${partyWiseList[index].deal1}+${partyWiseList[index].deal2}', style: TextStyle(color: Colors.black))         
//             ],
//         ),
//           ]
//         ),
//          trailing: Container(
//            child:
//              Padding(padding: EdgeInsets.all(8),
//              child: Column(children: <Widget>[
//                Text("Amount", style: TextStyle(color: Colors.black)),
//             Text('\u20B9 ${partyWiseList[index].amount}', style: TextStyle(color: Colors.black, fontSize: 25)),
//              ])
//              )
           
//          )
        
//              ) ,
//       ),
//     )
//                        // Divider(height: 1.0,)
//                       ],);
                
//           },
//         )
    
  
//     );
//   }
// }
