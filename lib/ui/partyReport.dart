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
  List<dynamic> divi;

class PartyReport extends StatefulWidget {
  
  @override
  _PartyReportState createState() => _PartyReportState();
}


class _PartyReportState extends State<PartyReport> {

  double mrpValue = 0.0;
  @override
  void initState() {
    setState(() {
      batch.clear();
      populateComp();
      print(_companies);
    });
    super.initState();    
  }
  List<String> batch = List();
  static void openFile(List<int> bytes) async {
    print("Inside openFile===========>>");
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/deals.pdf");
    await file.writeAsBytes(bytes);
    OpenFile.open(file.path);
  }
  
  Map<String,List<ProductData>> fillData(DateTime date) {
    batch.clear();
    
    Map<String,List<ProductData>> m = Map();
   
  String comp = company;
  print(comp);
  print(divi);
  (comp=="MANKIND" || comp == "ARISTO")?
   Firestore.instance.collection('Expiry').snapshots().listen((event) => event.documents.forEach((element) {
    Firestore.instance.collection('Expiry').document(element.documentID).collection(element['partyName']).where('compCode', whereIn: divi).snapshots().listen(
  
      (cour)=> cour.documents.forEach((doc) {
                
          ProductData prod = ProductData();
          prod.qty = int.parse(doc.data['prodQty']).toString();
          prod.name = doc.data['prodName'];
          prod.pack = doc.data['prodPack'];
          prod.mrp  = doc.data['prodMrp'];
          prod.expiryDate = doc.data['prodExpiryDate'];
          prod.batchNumber = doc.data['prodBatchNumber'];
          prod.compCode = doc.data['compCode'];
        //  mrpValue += doc.data['prodQty'] * doc.data['prodMrp'];
        print(prod.name + "  " + doc.data['compCode'].toString());
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
          print("Inside==================>>>>");
        }
        else{       
          batch.add(prod.name);
          print("Hiiiiiiiii");
          if(!m.containsKey(prod.name)){
            m[prod.name] = []; 
          }
          m[prod.name].add(prod);
          
          print(batch);
        }  
        print("qty====>>" + m[doc.data['prodName']].toString());       
      }
    )
  );
}) ):
Firestore.instance.collection('Expiry').snapshots().listen((event) => event.documents.forEach((element) {
    Firestore.instance.collection('Expiry').document(element.documentID).collection(element['partyName']).where('compCode', isEqualTo: comp).snapshots().listen(
  
      (cour)=> cour.documents.forEach((doc) {
                
          ProductData prod = ProductData();
          prod.qty = int.parse(doc.data['prodQty']).toString();
          prod.name = doc.data['prodName'];
          prod.pack = doc.data['prodPack'];
          prod.mrp  = doc.data['prodMrp'];
          prod.expiryDate = doc.data['prodExpiryDate'];
          prod.batchNumber = doc.data['prodBatchNumber'];
        //  mrpValue += doc.data['prodQty'] * doc.data['prodMrp'];
        print(prod.name + "  " + doc.data['compCode'].toString());
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
          print("Inside==================>>>>");
        }
        else{       
          batch.add(prod.name);
          print("Hiiiiiiiii");
          if(!m.containsKey(prod.name)){
            m[prod.name] = []; 
          }
          m[prod.name].add(prod);
          
          print(batch);
        }  
        print("qty====>>" + m[doc.data['prodName']].toString());       
      }
    )
  );
}) );

Firestore.instance.collection("My Profile").document("WkLniIfWVSQSPZ6bjXoq").get().then((value) => claim = value.data['Claim']);
Firestore.instance.collection("My Profile").document("WkLniIfWVSQSPZ6bjXoq").updateData({
  "Claim" : claim + 1
});


    
  return m;
} 



pdfGeneratorDivWise(dynamic m){
  
  final doc = pw.Document();
  print(batch);
  Map<String,List<List<String>>> trial = Map();
  
   var element = (["S.No.", "Product" , "Pack" , "QTY","MRP", "E/D", "Batch No."]);
    print("Hii....................LALALALALALLAa" + m.toString());
    print("Hii....................LALALALALALLAa" + m[batch[1]].toString());

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
  print("Hii....................LALALALALALLAaqqqqqqqq");
    //trial.sort((a,b)=>a[1].compareTo(b[1]));
  for(int x=0; x<divi.length;x++){
    if(trial.containsKey(divi[x])){
      trial[divi[x]].insert(0, element);
    }
    
    print(trial);}
    
  doc.addPage( 
    pw.MultiPage(
      header: _buildHeader1,
      footer: _buildFooter,
      build: (pw.Context context) => [
          pw.Wrap(children:
            List.generate(divi.length, (index){
              print("Inside TTTTTTTTTTTTTTTTTTTTT");
              print(divi[index]);
              return (trial.containsKey(divi[index]))?
                pw.Column(children: <pw.Widget>[
                    pw.Padding(child: pw.Text(divi[index]),
                    padding: pw.EdgeInsets.only(top: 12 ,bottom: 12)),
                    pw.Table.fromTextArray(context: context, data: trial[divi[index]], cellAlignment: pw.Alignment.topLeft),
                ]):pw.Container(width: 0, height: 0);
              
            })
            
              
            
            
           )
          

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
  print(batch);
  List<List<String>> trial = List();
  
   var element = (["S.No.", "Product" , "Pack" , "QTY","MRP", "E/D", "Batch No."]);
  int a=0;
  
  for(int i = 0 ;i< m.length;i++){
    for(int j=0; j<m[batch[i]].length;j++){
      trial.add([(a+1).toString(),m[batch[i]][j].name,m[batch[i]][j].pack,m[batch[i]][j].qty,m[batch[i]][j].mrp.toString(),m[batch[i]][j].expiryDate,m[batch[i]][j].batchNumber]);
      a++;
    }}
    //trial.sort((a,b)=>a[1].compareTo(b[1]));
    trial.insert(0, element);
    print(trial);
    
  doc.addPage(
    pw.MultiPage(
      header: _buildHeader1,
      footer: _buildFooter,
      build: (pw.Context context) => [
          pw.Table.fromTextArray(context: context, data: trial, cellAlignment: pw.Alignment.topLeft),

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
      divi = ["MANKIND-CURIS","MANKIND-DISCOVERY","MANKIND-LIFESTAR","MANKIND-FUTURE","MANKIND-M","MANKIND-MAGNET","MANKIND-NOBLIS","MANKIND-SPECIAL"];
    }
    if(comp.contains("ARISTO")){
      company = "ARISTO";
      divi = ["ARISTO-MF1","ARISTO-MF2","ARISTO-MF3","ARISTO-TF","ARISTO-GENETICA"];
    }
    Firestore.instance.collection("Company").where('compName', isEqualTo : comp).snapshots().listen((event) {
      event.documents.forEach((value) {
         address = (value.data['compMailingName']== null)?"":value.data['compMailingName'];
        location = (value.data['compMailingLocation']== null)?"":value.data['compMailingLocation'];
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
    print(_companies);
  }
  final _sKey = GlobalKey<ScaffoldState>(); 
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
                          print(company);
                          //divi.clear();
                           _populate_comp_details(company);
                           print(company);
                          var x = fillData(DateTime.now());
                          print("x=" + x.toString());
                          new Future.delayed(new Duration(seconds: 10), () {
                          Navigator.of(context).pop(); 
                          if(x.length == 0){
                            final snackbar = SnackBar(content: Text("No Data Found"));
                            _sKey.currentState.showSnackBar(snackbar);
                          } 
                          else      
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
    return pw.Container(
            decoration: new pw.BoxDecoration(
                          border: new pw.BoxBorder(
                                left: true,right: true, top: true,bottom: true)),width: double.infinity,  
          child: pw.Row(children: <pw.Widget>[
            pw.Container(padding: pw.EdgeInsets.all(12.0),
                      decoration: new pw.BoxDecoration(
                          border: new pw.BoxBorder(
                                right: true)),
                          child:pw.Column(
                            children: <pw.Widget>[
              pw.Text("MAHESH PHARMA", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.Text("STATION ROAD", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 13)),
              pw.Text("GONDA (U.P.)-271002 ", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 13)),
              pw.Container(height: 5),
              pw.Text("CLAIM NO. - " + claim.toString(), textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.bold, fontSize: 13))
            ])),
              pw.Expanded(child: pw.Container(padding: pw.EdgeInsets.only(right:8,top:8,bottom: 8),
                  decoration: pw.BoxDecoration(border: pw.BoxBorder()),
                  child: pw.Column(children: <pw.Widget>[
              pw.Padding(
                padding: pw.EdgeInsets.only(left: 10),
                child: pw.Text("To,", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times() ,fontWeight: pw.FontWeight.bold, fontSize: 18))
              ),
              pw.Padding(child: pw.Text("M/S " + address, textAlign: pw.TextAlign.right  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 13)),
              padding: pw.EdgeInsets.only(left: 12)),
              pw.Padding(padding: pw.EdgeInsets.only(left:12),
                child: pw.Text(location, textAlign: pw.TextAlign.right  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 13))
              ),
               pw.Padding(padding: pw.EdgeInsets.only(left:12),
                child: pw.Text("DT - " + DateTime.now().day.toString() + "/" + DateTime.now().month.toString() + "/" + DateTime.now().year.toString(), textAlign: pw.TextAlign.right  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 13))
              )
            ]),
              ))
            
          ])
        );
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
              pw.Text("MAHESH PHARMA", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.Text("STATION ROAD", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 13)),
              pw.Text("GONDA (U.P.)-271002 ", textAlign: pw.TextAlign.left  ,style: pw.TextStyle(font: pw.Font.times(),fontWeight: pw.FontWeight.normal, fontSize: 13)),
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
            color: PdfColors.grey,
          ),
        ),
      ],
    );
  }
