import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './reportConfig.dart';

class SalesReport extends StatefulWidget {
  @override
  _SalesReportState createState() => _SalesReportState();
}

class _SalesReportState extends State<SalesReport> {
  String selectedCompany = '';
  String selectedDivision = '';
  DateTime startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime endDate = DateTime.now();
  List<String> companies = [];
  List<String> divisions = [];
  bool isLoading = false;
  DateRangeType selectedDateRange = DateRangeType.lastMonth;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _updateDateRange();
  }

  void _updateDateRange() {
    Map<String, DateTime> dateRange =
        DateRangeHelper.getDateRange(selectedDateRange);
    setState(() {
      startDate = dateRange['startDate'];
      endDate = dateRange['endDate'];
    });
  }

  Future<void> _loadCompanies() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Company')
          .orderBy('compName')
          .get();

      List<String> compList = [];
      snapshot.docs.forEach((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String compName = data['compName'] as String;
        if (!compList.contains(compName)) {
          compList.add(compName);
        }
      });

      setState(() {
        companies = compList;
        if (compList.isNotEmpty) {
          selectedCompany = compList[0];
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading companies: $e');
    }
  }

  Future<void> _loadDivisions() async {
    if (selectedCompany.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Company')
          .where('compName', isEqualTo: selectedCompany)
          .get();

      List<String> divList = [];
      snapshot.docs.forEach((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('division')) {
          String division = data['division'] as String;
          if (!divList.contains(division)) {
            divList.add(division);
          }
        }
      });

      setState(() {
        divisions = divList;
        if (divList.isNotEmpty) {
          selectedDivision = divList[0];
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading divisions: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  void _generateReport() {
    if (selectedCompany.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a company'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C3E50),
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        elevation: 0,
        title: Text(
          '',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
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
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate Stock Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select filters to generate your stock report',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 24),
                Expanded(
                  child: Card(
                    elevation: 8.0,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF34495E),
                            Color(0xFF2C3E50),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Company Selection
                            Text(
                              'Company',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedCompany.isNotEmpty
                                    ? selectedCompany
                                    : null,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                hint: Text('Select Company'),
                                items: companies.map((String company) {
                                  return DropdownMenuItem<String>(
                                    value: company,
                                    child: Text(company),
                                  );
                                }).toList(),
                                onChanged: (String newValue) {
                                  setState(() {
                                    selectedCompany = newValue ?? '';
                                    selectedDivision = '';
                                  });
                                  if (newValue != null) {
                                    _loadDivisions();
                                  }
                                },
                              ),
                            ),
                            SizedBox(height: 20),

                            // Division Selection
                            Text(
                              'Division',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedDivision.isNotEmpty
                                    ? selectedDivision
                                    : null,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                hint: Text('Select Division'),
                                items: divisions.map((String division) {
                                  return DropdownMenuItem<String>(
                                    value: division,
                                    child: Text(division),
                                  );
                                }).toList(),
                                onChanged: (String newValue) {
                                  setState(() {
                                    selectedDivision = newValue ?? '';
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 20),

                            // Quick Date Range Selection
                            Text(
                              'Quick Date Range',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: DropdownButtonFormField<DateRangeType>(
                                value: selectedDateRange,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                hint: Text('Select Date Range'),
                                items: DateRangeHelper.getDisplayNames()
                                    .entries
                                    .map((entry) {
                                  return DropdownMenuItem<DateRangeType>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  );
                                }).toList(),
                                onChanged: (DateRangeType newValue) {
                                  setState(() {
                                    selectedDateRange = newValue;
                                  });
                                  _updateDateRange();
                                },
                              ),
                            ),
                            SizedBox(height: 20),

                            // Date Range Selection
                            Text(
                              'Date Range',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Roboto',
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Date',
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      InkWell(
                                        onTap: () => _selectDate(context, true),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.calendar_today,
                                                  size: 20,
                                                  color: Colors.grey[600]),
                                              SizedBox(width: 8),
                                              Text(
                                                DateFormat('dd/MM/yyyy')
                                                    .format(startDate),
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 14,
                                                  fontFamily: 'Roboto',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End Date',
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 12,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      InkWell(
                                        onTap: () =>
                                            _selectDate(context, false),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.calendar_today,
                                                  size: 20,
                                                  color: Colors.grey[600]),
                                              SizedBox(width: 8),
                                              Text(
                                                DateFormat('dd/MM/yyyy')
                                                    .format(endDate),
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 14,
                                                  fontFamily: 'Roboto',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 32),

                            // Generate Report Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _generateReport,
                                style: ElevatedButton.styleFrom(
                                  primary: Color(0xFF27AE60),
                                  onPrimary: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  elevation: 4,
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.analytics, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Generate Report',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Roboto',
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
