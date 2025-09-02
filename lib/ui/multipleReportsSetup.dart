import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './multipleReportsGenerated.dart';
import './reportConfig.dart';

class MultipleReportsSetup extends StatefulWidget {
  @override
  _MultipleReportsSetupState createState() => _MultipleReportsSetupState();
}

class _MultipleReportsSetupState extends State<MultipleReportsSetup> {
  List<String> companies = [];
  List<String> selectedCompanies = [];
  Set<String> selectedCompanySet = {};
  bool isLoading = false;
  DateRangeType selectedDateRange = DateRangeType.lastMonth;
  DateTime customStartDate = DateTime.now().subtract(Duration(days: 30));
  DateTime customEndDate = DateTime.now();
  bool useCustomDate = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
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

  void _toggleCompany(String company) {
    setState(() {
      if (selectedCompanySet.contains(company)) {
        selectedCompanySet.remove(company);
        selectedCompanies.remove(company);
      } else {
        selectedCompanySet.add(company);
        selectedCompanies.add(company);
      }
    });
  }

  void _selectAllCompanies() {
    setState(() {
      selectedCompanies = List.from(companies);
      selectedCompanySet = selectedCompanies.toSet();
    });
  }

  void _clearAllCompanies() {
    setState(() {
      selectedCompanies.clear();
      selectedCompanySet.clear();
    });
  }

  Future<void> _selectCustomDate(BuildContext context, bool isStartDate) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? customStartDate : customEndDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          customStartDate = picked;
        } else {
          customEndDate = picked;
        }
      });
    }
  }

  void _generateReports() {
    if (selectedCompanies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one company'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Map<String, DateTime> dateRange = useCustomDate
        ? {'startDate': customStartDate, 'endDate': customEndDate}
        : DateRangeHelper.getDateRange(selectedDateRange);

    List<ReportConfig> reports = [];
    for (String company in selectedCompanies) {
      reports.add(ReportConfig(
        companies: [company],
        division: '',
        startDate: dateRange['startDate'],
        endDate: dateRange['endDate'],
      ));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultipleReportsGenerated(
          reports: reports,
          companies: companies,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C3E50),
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        elevation: 0,
        title: Text(
          'Multiple Reports Setup',
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
                  'Setup Multiple Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Select date range and companies to generate reports',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 24),

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
                          'Date Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        SizedBox(height: 12),

                        // Quick Date Range Options
                        if (!useCustomDate) ...[
                          DropdownButtonFormField<DateRangeType>(
                            value: selectedDateRange,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
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
                            },
                          ),
                          SizedBox(height: 8),
                        ],

                        // Custom Date Range
                        Row(
                          children: [
                            Checkbox(
                              value: useCustomDate,
                              onChanged: (bool value) {
                                setState(() {
                                  useCustomDate = value;
                                });
                              },
                            ),
                            Text(
                              'Use Custom Date Range',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),

                        if (useCustomDate) ...[
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    InkWell(
                                      onTap: () =>
                                          _selectCustomDate(context, true),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border: Border.all(
                                              color: Colors.grey[300]),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                size: 20,
                                                color: Colors.grey[600]),
                                            SizedBox(width: 8),
                                            Text(
                                              DateFormat('dd/MM/yyyy')
                                                  .format(customStartDate),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    InkWell(
                                      onTap: () =>
                                          _selectCustomDate(context, false),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          border: Border.all(
                                              color: Colors.grey[300]),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                size: 20,
                                                color: Colors.grey[600]),
                                            SizedBox(width: 8),
                                            Text(
                                              DateFormat('dd/MM/yyyy')
                                                  .format(customEndDate),
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
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Companies Selection
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
                          'Select Companies',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                          ),
                        ),
                        SizedBox(height: 8),

                        // Select All/Clear All buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _selectAllCompanies,
                                icon: Icon(Icons.select_all, size: 16),
                                label: Text('Select All'),
                                style: ElevatedButton.styleFrom(
                                  primary: Color(0xFF3498DB),
                                  onPrimary: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _clearAllCompanies,
                                icon: Icon(Icons.clear, size: 16),
                                label: Text('Clear All'),
                                style: ElevatedButton.styleFrom(
                                  primary: Color(0xFFE74C3C),
                                  onPrimary: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),

                        // Companies List
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF2C3E50)),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: companies.length,
                                  itemBuilder: (context, index) {
                                    String company = companies[index];
                                    bool isSelected =
                                        selectedCompanySet.contains(company);

                                    return CheckboxListTile(
                                      title: Text(
                                        company,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      value: isSelected,
                                      onChanged: (bool value) =>
                                          _toggleCompany(company),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      dense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 0),
                                    );
                                  },
                                ),
                        ),

                        // Selected Companies Summary
                        if (selectedCompanies.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 8),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(color: Colors.blue[200]),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info,
                                    size: 16, color: Colors.blue[700]),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${selectedCompanies.length} company(ies) selected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[700],
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateReports,
                    icon: Icon(Icons.analytics),
                    label: Text('Generate Reports'),
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFF27AE60),
                      onPrimary: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 4,
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
