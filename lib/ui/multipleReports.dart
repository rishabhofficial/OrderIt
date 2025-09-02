import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import './contactSelectionDialog.dart';
import './reportConfig.dart';
import './reportConfigWidget.dart';
import './salesReportResults.dart';

class MultipleReports extends StatefulWidget {
  @override
  _MultipleReportsState createState() => _MultipleReportsState();
}

class _MultipleReportsState extends State<MultipleReports> {
  List<ReportConfig> reports = [];
  List<String> companies = [];
  List<String> divisions = [];
  bool isLoading = false;
  DateRangeType selectedDateRange = DateRangeType.lastMonth;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _addDefaultReport();
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
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading companies: $e');
    }
  }

  Future<void> _loadDivisions(String company) async {
    if (company.isEmpty) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Company')
          .where('compName', isEqualTo: company)
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
      });
    } catch (e) {
      print('Error loading divisions: $e');
    }
  }

  void _addDefaultReport() {
    Map<String, DateTime> dateRange =
        DateRangeHelper.getDateRange(selectedDateRange);
    reports.add(ReportConfig(
      companies: companies.isNotEmpty ? [companies[0]] : [],
      division: '',
      startDate: dateRange['startDate'],
      endDate: dateRange['endDate'],
    ));
  }

  void _addReport() {
    Map<String, DateTime> dateRange =
        DateRangeHelper.getDateRange(selectedDateRange);
    reports.add(ReportConfig(
      companies: companies.isNotEmpty ? [companies[0]] : [],
      division: '',
      startDate: dateRange['startDate'],
      endDate: dateRange['endDate'],
    ));
    setState(() {});
  }

  void _removeReport(int index) {
    if (reports.length > 1) {
      reports.removeAt(index);
      setState(() {});
    }
  }

  void _updateReport(int index, ReportConfig newConfig) {
    reports[index] = newConfig;
    setState(() {});
  }

  Future<void> _selectContact(int reportIndex) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return ContactSelectionDialog();
      },
    );

    if (result != null) {
      ReportConfig currentConfig = reports[reportIndex];
      ReportConfig newConfig = currentConfig.copyWith(
        contactName: result['name'],
        contactPhone: result['phone'],
      );
      _updateReport(reportIndex, newConfig);
    }
  }

  void _generateAllReports() {
    // Validate all reports
    for (int i = 0; i < reports.length; i++) {
      if (reports[i].companies.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Please select at least one company for report ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Generate all reports
    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      // Generate a report for each selected company
      for (String company in report.companies) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SalesReportResults(
              company: company,
              division: report.division,
              startDate: report.startDate,
              endDate: report.endDate,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C3E50),
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        elevation: 0,
        title: Text(
          'Multiple Reports',
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
                  'Generate Multiple Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create and configure multiple reports at once',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 16),

                // Date Range Selection
                Card(
                  elevation: 4.0,
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: Colors.white,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Default Date Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<DateRangeType>(
                          value: selectedDateRange,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
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
                              // Update all reports with new date range
                              Map<String, DateTime> dateRange =
                                  DateRangeHelper.getDateRange(newValue);
                              for (int i = 0; i < reports.length; i++) {
                                reports[i] = reports[i].copyWith(
                                  startDate: dateRange['startDate'],
                                  endDate: dateRange['endDate'],
                                );
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Reports List
                Expanded(
                  child: ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      return ReportConfigWidget(
                        report: reports[index],
                        index: index,
                        companies: companies,
                        divisions: divisions,
                        selectedDateRange: selectedDateRange,
                        onUpdate: _updateReport,
                        onRemove: _removeReport,
                        onSelectContact: _selectContact,
                      );
                    },
                  ),
                ),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _addReport,
                        icon: Icon(Icons.add),
                        label: Text('Add Report'),
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFF3498DB),
                          onPrimary: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _generateAllReports,
                        icon: Icon(Icons.analytics),
                        label: Text('Generate All'),
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFF27AE60),
                          onPrimary: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
