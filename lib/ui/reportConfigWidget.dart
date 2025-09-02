import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './reportConfig.dart';

class ReportConfigWidget extends StatefulWidget {
  final ReportConfig report;
  final int index;
  final List<String> companies;
  final List<String> divisions;
  final DateRangeType selectedDateRange;
  final Function(int, ReportConfig) onUpdate;
  final Function(int) onRemove;
  final Function(int) onSelectContact;

  ReportConfigWidget({
    this.report,
    this.index,
    this.companies,
    this.divisions,
    this.selectedDateRange,
    this.onUpdate,
    this.onRemove,
    this.onSelectContact,
  });

  @override
  _ReportConfigWidgetState createState() => _ReportConfigWidgetState();
}

class _ReportConfigWidgetState extends State<ReportConfigWidget> {
  List<String> selectedCompanies = [];
  Set<String> selectedCompanySet = {};

  @override
  void initState() {
    super.initState();
    selectedCompanies = widget.report.companies ?? [];
    selectedCompanySet = selectedCompanies.toSet();
  }

  void _updateReport() {
    ReportConfig newConfig = widget.report.copyWith(
      companies: selectedCompanies,
    );
    widget.onUpdate(widget.index, newConfig);
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
    _updateReport();
  }

  void _selectAllCompanies() {
    setState(() {
      selectedCompanies = List.from(widget.companies);
      selectedCompanySet = selectedCompanies.toSet();
    });
    _updateReport();
  }

  void _clearAllCompanies() {
    setState(() {
      selectedCompanies.clear();
      selectedCompanySet.clear();
    });
    _updateReport();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, DateTime> dateRange =
        DateRangeHelper.getDateRange(widget.selectedDateRange);

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
                  'Report ${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => widget.onRemove(widget.index),
                  tooltip: 'Remove Report',
                ),
              ],
            ),
            SizedBox(height: 16),

            // Companies Selection
            Text(
              'Companies',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 4),

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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView.builder(
                itemCount: widget.companies.length,
                itemBuilder: (context, index) {
                  String company = widget.companies[index];
                  bool isSelected = selectedCompanySet.contains(company);

                  return CheckboxListTile(
                    title: Text(
                      company,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    value: isSelected,
                    onChanged: (bool value) => _toggleCompany(company),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  );
                },
              ),
            ),
            SizedBox(height: 12),

            // Selected Companies Summary
            if (selectedCompanies.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: Colors.blue[200]),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 16, color: Colors.blue[700]),
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
            SizedBox(height: 12),

            // Division Selection
            Text(
              'Division',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: widget.report.division.isNotEmpty
                  ? widget.report.division
                  : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              hint: Text('Select Division'),
              items: widget.divisions.map((String division) {
                return DropdownMenuItem<String>(
                  value: division,
                  child: Text(division),
                );
              }).toList(),
              onChanged: (String newValue) {
                ReportConfig newConfig =
                    widget.report.copyWith(division: newValue);
                widget.onUpdate(widget.index, newConfig);
              },
            ),
            SizedBox(height: 12),

            // Date Range Display
            Text(
              'Date Range',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${DateFormat('dd/MM/yyyy').format(dateRange['startDate'])} - ${DateFormat('dd/MM/yyyy').format(dateRange['endDate'])}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Contact Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.report.contactName.isNotEmpty
                              ? Colors.green[50]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: widget.report.contactName.isNotEmpty
                                ? Colors.green
                                : Colors.grey[300],
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.contact_phone,
                              size: 16,
                              color: widget.report.contactName.isNotEmpty
                                  ? Colors.green
                                  : Colors.grey[600],
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.report.contactName.isNotEmpty
                                    ? '${widget.report.contactName} (${widget.report.contactPhone})'
                                    : 'No contact selected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.report.contactName.isNotEmpty
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
                  onPressed: () => widget.onSelectContact(widget.index),
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
          ],
        ),
      ),
    );
  }
}
