import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import './contactSelectionDialog.dart';
import './reportConfig.dart';
import './salesReportResults.dart';

class MultipleReportsGenerated extends StatefulWidget {
  final List<ReportConfig> reports;
  final List<String> companies;

  MultipleReportsGenerated({
    this.reports,
    this.companies,
  });

  @override
  _MultipleReportsGeneratedState createState() =>
      _MultipleReportsGeneratedState();
}

class _MultipleReportsGeneratedState extends State<MultipleReportsGenerated> {
  List<ReportConfig> reports = [];

  @override
  void initState() {
    super.initState();
    reports = List.from(widget.reports);
  }

  void _updateReport(int index, ReportConfig newConfig) {
    setState(() {
      reports[index] = newConfig;
    });
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

  Future<void> _selectCustomDate(
      BuildContext context, int reportIndex, bool isStartDate) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? reports[reportIndex].startDate
          : reports[reportIndex].endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ReportConfig currentConfig = reports[reportIndex];
      ReportConfig newConfig = currentConfig.copyWith(
        startDate: isStartDate ? picked : currentConfig.startDate,
        endDate: isStartDate ? currentConfig.endDate : picked,
      );
      _updateReport(reportIndex, newConfig);
    }
  }

  void _generateAndSend() {
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

    // Generate and send all reports
    for (int i = 0; i < reports.length; i++) {
      final report = reports[i];
      // Generate a report for each selected company
      for (String company in report.companies) {
        // Generate the report
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

        // Send via WhatsApp if phone number is provided
        if (report.contactPhone.isNotEmpty) {
          _sendViaWhatsApp(report.contactPhone, report.contactName, company);
        }

        // Send via Email if email is provided
        if (report.email.isNotEmpty) {
          _sendViaEmail(report.email, report.contactName, company);
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reports generated and sent successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _sendViaWhatsApp(
      String phone, String name, String company) async {
    String phoneNumber = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneNumber.startsWith('91')) {
      phoneNumber = phoneNumber.substring(2);
    }

    String whatsappUrl =
        'https://wa.me/91$phoneNumber?text=Hi ${name}, here is your sales report for $company.';

    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    }
  }

  Future<void> _sendViaEmail(String email, String name, String company) async {
    String subject = 'Sales Report - $company';
    String body =
        'Hi $name,\n\nPlease find attached the sales report for $company.\n\nBest regards,\nYour Team';

    String mailtoUrl =
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';

    if (await canLaunch(mailtoUrl)) {
      await launch(mailtoUrl);
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
          'Generated Reports',
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
                  'Customize Reports',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Override settings and add contact details for each report',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 16),

                // Reports List
                Expanded(
                  child: ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      return _buildReportCard(index);
                    },
                  ),
                ),

                // Generate and Send Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateAndSend,
                    icon: Icon(Icons.send),
                    label: Text('Generate & Send All'),
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

  Widget _buildReportCard(int index) {
    final report = reports[index];
    final company = report.companies.isNotEmpty ? report.companies[0] : '';

    return Card(
      margin: EdgeInsets.only(bottom: 12.0),
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
            // Header
            Row(
              children: [
                Text(
                  'Report ${index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
                Spacer(),
                Text(
                  company,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Custom Date Range
            Text(
              'Custom Date Range (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 8),
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
                        onTap: () => _selectCustomDate(context, index, true),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey[300]),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 20, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(report.startDate),
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
                        onTap: () => _selectCustomDate(context, index, false),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: Colors.grey[300]),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 20, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                DateFormat('dd/MM/yyyy').format(report.endDate),
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
            SizedBox(height: 16),

            // Contact Information
            Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 8),

            // WhatsApp Contact
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WhatsApp Contact',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: report.contactName.isNotEmpty
                              ? Colors.green[50]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: report.contactName.isNotEmpty
                                ? Colors.green
                                : Colors.grey[300],
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.whatsapp,
                              size: 16,
                              color: report.contactName.isNotEmpty
                                  ? Colors.green
                                  : Colors.grey[600],
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                report.contactName.isNotEmpty
                                    ? '${report.contactName} (${report.contactPhone})'
                                    : 'No contact selected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: report.contactName.isNotEmpty
                                      ? Colors.green[700]
                                      : Colors.grey[600],
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
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _selectContact(index),
                  icon: Icon(Icons.add, size: 16),
                  label: Text('Select'),
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF27AE60),
                    onPrimary: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Email Contact
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 4),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (String value) {
                    ReportConfig newConfig = report.copyWith(email: value);
                    _updateReport(index, newConfig);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
