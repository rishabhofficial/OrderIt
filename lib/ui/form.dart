import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:startup_namer/model.dart';

class CompanyForm extends StatefulWidget {
  @override
  _CompanyFormState createState() => _CompanyFormState();
}

class _CompanyFormState extends State<CompanyForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _name = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _cc = TextEditingController();
  TextEditingController _mn = TextEditingController();
  TextEditingController _l = TextEditingController();
  TextEditingController _codesController = TextEditingController();
  List<String> _codes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _name.clear();
    _email.clear();
    _cc.clear();
    _mn.clear();
    _l.clear();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _cc.dispose();
    _mn.dispose();
    _l.dispose();
    _codesController.dispose();
    super.dispose();
  }

  _displaySnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Color(0xFFE74C3C) : Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void _addCode(String code) {
    if (code.trim().isNotEmpty && !_codes.contains(code.trim())) {
      setState(() {
        _codes.add(code.trim());
        _codesController.clear();
      });
    }
  }

  void _removeCode(String code) {
    setState(() {
      _codes.remove(code);
    });
  }

  Future<void> _addCompany() async {
    if (!_formKey.currentState.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      CompanyData newComp = CompanyData(
        name: _name.text.trim(),
        email: _email.text.trim(),
        cc: _cc.text.trim(),
        mailingName: _mn.text.trim(),
        mailingLocation: _l.text.trim(),
        codes: _codes,
      );

      await FirebaseFirestore.instance
          .collection('Company')
          .add(newComp.toJson());

      _displaySnackBar("Company added successfully!");

      // Clear form
      _name.clear();
      _email.clear();
      _cc.clear();
      _mn.clear();
      _l.clear();
      _codes.clear();
      _codesController.clear();

      Navigator.pop(context);
    } catch (e) {
      _displaySnackBar("Failed to add company: ${e.toString()}", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C3E50),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        elevation: 0,
        title: Text(
          "Add New Company",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 20.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Company Name Field
                _buildTextField(
                  controller: _name,
                  label: "Company Name",
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Company name is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Email Field
                _buildTextField(
                  controller: _email,
                  label: "Email Address",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // CC Field
                _buildTextField(
                  controller: _cc,
                  label: "CC Email",
                  icon: Icons.people,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),

                // Mailing Name Field
                _buildTextField(
                  controller: _mn,
                  label: "Mailing Name",
                  icon: Icons.location_on,
                ),
                SizedBox(height: 20),

                // Location Field
                _buildTextField(
                  controller: _l,
                  label: "Mailing Location",
                  icon: Icons.place,
                ),
                SizedBox(height: 20),

                // Codes Field
                _buildCodesField(),
                SizedBox(height: 30),

                // Add Button
                Container(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addCompany,
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFF3498DB),
                      onPrimary: Colors.white,
                      elevation: 6,
                      shadowColor: Color(0xFF3498DB).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Adding...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Add Company',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
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

  Widget _buildTextField({
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType,
    String Function(String) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (value) {
          FocusScope.of(context).nextFocus();
        },
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Roboto',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            fontFamily: 'Roboto',
          ),
          prefixIcon: Icon(
            icon,
            color: Color(0xFF3498DB),
            size: 20,
          ),
          filled: true,
          fillColor: Color(0xFF34495E).withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[600],
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0xFF3498DB),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0xFFE74C3C),
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0xFFE74C3C),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          errorStyle: TextStyle(
            color: Color(0xFFE74C3C),
            fontSize: 12,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }

  Widget _buildCodesField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              "Company Codes",
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
            ),
          ),

          // Input field for adding codes
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF34495E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[600],
                width: 1,
              ),
            ),
            child: TextField(
              controller: _codesController,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Roboto',
              ),
              decoration: InputDecoration(
                hintText: "Type a code and press Enter",
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontFamily: 'Roboto',
                ),
                prefixIcon: Icon(
                  Icons.tag,
                  color: Color(0xFF3498DB),
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Color(0xFF3498DB),
                    size: 20,
                  ),
                  onPressed: () => _addCode(_codesController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (value) => _addCode(value),
            ),
          ),

          // Display existing codes as chips
          if (_codes.isNotEmpty) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _codes.map((code) => _buildCodeChip(code)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeChip(String code) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF3498DB).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF3498DB),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12, top: 6, bottom: 6),
            child: Text(
              code,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _removeCode(code),
            child: Container(
              margin: EdgeInsets.only(left: 4, right: 8),
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Color(0xFFE74C3C).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close,
                color: Color(0xFFE74C3C),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompanyUpdateForm extends StatefulWidget {
  final CompanyData initialData;
  final String docId;
  CompanyUpdateForm(this.initialData, this.docId);
  @override
  _CompanyUpdateFormState createState() => _CompanyUpdateFormState();
}

class _CompanyUpdateFormState extends State<CompanyUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _name = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _cc = TextEditingController();
  TextEditingController _mn = TextEditingController();
  TextEditingController _l = TextEditingController();
  TextEditingController _codesController = TextEditingController();
  List<String> _codes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Populate all fields with existing data
    _name.text = widget.initialData.name ?? '';
    _email.text = widget.initialData.email ?? '';
    _cc.text = widget.initialData.cc ?? '';
    _mn.text = widget.initialData.mailingName ?? '';
    _l.text = widget.initialData.mailingLocation ?? '';
    _codes = List<String>.from(widget.initialData.codes ?? []);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _cc.dispose();
    _mn.dispose();
    _l.dispose();
    _codesController.dispose();
    super.dispose();
  }

  _displaySnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Color(0xFFE74C3C) : Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _updateCompany() async {
    if (!_formKey.currentState.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a map with only the fields that have been changed
      Map<String, dynamic> updateData = {};

      if (_name.text.trim() != (widget.initialData.name ?? '')) {
        updateData['compName'] = _name.text.trim();
      }
      if (_email.text.trim() != (widget.initialData.email ?? '')) {
        updateData['compEmail'] = _email.text.trim();
      }
      if (_cc.text.trim() != (widget.initialData.cc ?? '')) {
        updateData['compCC'] = _cc.text.trim();
      }
      if (_mn.text.trim() != (widget.initialData.mailingName ?? '')) {
        updateData['compMailingName'] = _mn.text.trim();
      }
      if (_l.text.trim() != (widget.initialData.mailingLocation ?? '')) {
        updateData['compMailingLocation'] = _l.text.trim();
      }

      // Check if codes have changed
      List<String> initialCodes =
          List<String>.from(widget.initialData.codes ?? []);
      if (_codes.length != initialCodes.length ||
          !_listEquals(_codes, initialCodes)) {
        updateData['codes'] = _codes;
      }

      // Only update if there are changes
      if (updateData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('Company')
            .doc(widget.docId)
            .update(updateData);

        _displaySnackBar("Company updated successfully!");
        Navigator.pop(context);
      } else {
        _displaySnackBar("No changes detected");
      }
    } catch (e) {
      _displaySnackBar("Failed to update company: ${e.toString()}",
          isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void _addCode(String code) {
    if (code.trim().isNotEmpty && !_codes.contains(code.trim())) {
      setState(() {
        _codes.add(code.trim());
        _codesController.clear();
      });
    }
  }

  void _removeCode(String code) {
    setState(() {
      _codes.remove(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C3E50),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        elevation: 0,
        title: Text(
          "Update Company",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 20.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Company Name Field
                _buildTextField(
                  controller: _name,
                  label: "Company Name",
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Company name is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Email Field
                _buildTextField(
                  controller: _email,
                  label: "Email Address",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // CC Field
                _buildTextField(
                  controller: _cc,
                  label: "CC Email",
                  icon: Icons.people,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),

                // Mailing Name Field
                _buildTextField(
                  controller: _mn,
                  label: "Mailing Name",
                  icon: Icons.location_on,
                ),
                SizedBox(height: 20),

                // Location Field
                _buildTextField(
                  controller: _l,
                  label: "Mailing Location",
                  icon: Icons.place,
                ),
                SizedBox(height: 20),

                // Codes Field
                _buildCodesField(),
                SizedBox(height: 30),

                // Update Button
                Container(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateCompany,
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xFF3498DB),
                      onPrimary: Colors.white,
                      elevation: 6,
                      shadowColor: Color(0xFF3498DB).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Updating...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Update Company',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
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

  Widget _buildTextField({
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType,
    String Function(String) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (value) {
          FocusScope.of(context).nextFocus();
        },
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'Roboto',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            fontFamily: 'Roboto',
          ),
          prefixIcon: Icon(
            icon,
            color: Color(0xFF3498DB),
            size: 20,
          ),
          filled: true,
          fillColor: Color(0xFF34495E).withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[600],
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0xFF3498DB),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0xFFE74C3C),
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Color(0xFFE74C3C),
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          errorStyle: TextStyle(
            color: Color(0xFFE74C3C),
            fontSize: 12,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }

  Widget _buildCodesField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              "Company Codes",
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
            ),
          ),

          // Input field for adding codes
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF34495E).withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[600],
                width: 1,
              ),
            ),
            child: TextField(
              controller: _codesController,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Roboto',
              ),
              decoration: InputDecoration(
                hintText: "Type a code and press Enter",
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontFamily: 'Roboto',
                ),
                prefixIcon: Icon(
                  Icons.tag,
                  color: Color(0xFF3498DB),
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Color(0xFF3498DB),
                    size: 20,
                  ),
                  onPressed: () => _addCode(_codesController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (value) => _addCode(value),
            ),
          ),

          // Display existing codes as chips
          if (_codes.isNotEmpty) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _codes.map((code) => _buildCodeChip(code)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeChip(String code) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF3498DB).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color(0xFF3498DB),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12, top: 6, bottom: 6),
            child: Text(
              code,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _removeCode(code),
            child: Container(
              margin: EdgeInsets.only(left: 4, right: 8),
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Color(0xFFE74C3C).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.close,
                color: Color(0xFFE74C3C),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductForm extends StatefulWidget {
  final String compName;
  final bool isExpiryProd;
  ProductForm(this.compName, this.isExpiryProd);
  @override
  _ProductFormState createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  TextEditingController _name = TextEditingController();
  TextEditingController _pack = TextEditingController();
  TextEditingController _div = TextEditingController();
  TextEditingController _comp = TextEditingController();
  ProductData newProd = ProductData();
  bool test = true;

  @override
  void initState() {
    super.initState();
    _name.clear();
    _pack.clear();
    _div.clear();
    _comp.clear();
    populateComp();
  }

  List<String> _companies = List();
  String company;
  void populateComp() {
    _companies.clear();
    FirebaseFirestore.instance
        .collection("Company")
        .orderBy('compName')
        .snapshots()
        .listen((event) {
      event.docs.forEach((element) {
        if (!_companies.contains(element.data()['compName']))
          _companies.add(element.data()['compName']);
      });
    });
    //print(_companies);
  }

  List comp = List();
  FutureOr<Iterable<dynamic>> getSuggestions(String pattern) {
    comp.clear();
    _companies.forEach((element) {
      element.startsWith(pattern) ? comp.add(element) : null;
    });
    return comp;
  }

  _displaySnackBar(String action) {
    final snackbar = SnackBar(content: Text(action));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  final _scaffoldKey3 = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey3,
        backgroundColor: Color(0xFF2C3E50),
        resizeToAvoidBottomInset: true,
        appBar: new AppBar(
          backgroundColor: Color(0xFF2C3E50),
          elevation: 0,
          title: Text(
            "Add New Product",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto',
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 20.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                  child: TextField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (value) {
                        FocusScope.of(context).nextFocus();
                      },
                      decoration: new InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        labelText: "Name",
                        fillColor: Colors.white,
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(15.0),
                          borderSide: new BorderSide(),
                        ),
                      )),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                  child: TextField(
                      controller: _pack,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (value) {
                        FocusScope.of(context).nextFocus();
                      },
                      decoration: new InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        labelText: "Pack",
                        fillColor: Colors.black,
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(15.0),
                          borderSide: new BorderSide(),
                        ),
                      )),
                ),
                (!widget.isExpiryProd)
                    ? Padding(
                        padding: (widget.isExpiryProd)
                            ? EdgeInsets.only(top: 30, left: 20, right: 20)
                            : EdgeInsets.only(
                                top: 30, left: 20, right: 20, bottom: 30),
                        child: TextField(
                            controller: _div,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (value) {
                              FocusScope.of(context).unfocus();
                            },
                            decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 20),
                              labelText: "Division",
                              fillColor: Colors.white,
                              enabled: (widget.compName == "ABT INDIA")
                                  ? true
                                  : false,
                              border: new OutlineInputBorder(
                                borderRadius: new BorderRadius.circular(15.0),
                                borderSide: new BorderSide(),
                              ),
                            )),
                      )
                    : Container(height: 0, width: 0),
                (widget.isExpiryProd)
                    ? Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: TypeAheadField(
                          textFieldConfiguration: TextFieldConfiguration(
                              autofocus: false,
                              controller: _comp,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (value) {
                                FocusScope.of(context).nextFocus();
                              },
                              //   style: DefaultTextStyle.of(context).style.copyWith(
                              //   fontStyle: FontStyle.italic
                              // ),
                              decoration: new InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 20),
                                labelText: "Company",
                                fillColor: Colors.black,
                                border: new OutlineInputBorder(
                                  borderRadius: new BorderRadius.circular(15.0),
                                  borderSide: new BorderSide(),
                                ),
                              )),
                          suggestionsCallback: (pattern) {
                            return getSuggestions(pattern);
                          },
                          itemBuilder: (context, suggestion) {
                            return ListTile(
                              title: Text(suggestion),
                            );
                          },
                          onSuggestionSelected: (suggestion) {
                            setState(() {
                              _comp.text = suggestion.toString();
                            });
                          },
                        ))
                    : Container(height: 0, width: 0),
                (widget.isExpiryProd && (_comp.text == "ABT INDIA"))
                    ? Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: TextField(
                            controller: _div,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (value) {
                              FocusScope.of(context).unfocus();
                            },
                            decoration: new InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 20),
                              labelText: "Division",
                              fillColor: Colors.white,
                              //enabled: (widget.compName == "ALKEM" || widget.compName == "ABT INDIA")?true:false,
                              border: new OutlineInputBorder(
                                borderRadius: new BorderRadius.circular(15.0),
                                borderSide: new BorderSide(),
                              ),
                            )),
                      )
                    : Container(height: 0, width: 0),
                ElevatedButton(
                    child: Text("SUBMIT",
                        style: TextStyle(
                            fontSize: 20, fontStyle: FontStyle.normal)),
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        newProd.name = _name.text;
                        newProd.pack = _pack.text;
                        newProd.division = _div.text;
                        (widget.isExpiryProd)
                            ? newProd.compCode = _comp.text
                            : newProd.compCode = widget.compName;
                      });
                      Map<String, dynamic> addProd = newProd.toJson();
                      print(widget.compName);
                      if (!widget.isExpiryProd) {
                        FirebaseFirestore.instance
                            .collection(widget.compName)
                            .add(addProd)
                            .whenComplete(() {
                          print("---------->>>>>>" + addProd.toString());
                          _displaySnackBar("Successfully added to database");
                          FirebaseFirestore.instance
                              .collection("AllProducts")
                              .add(addProd);
                          test = true;
                          _name.clear();
                          _pack.clear();
                          _div.clear();
                        }).catchError((e) {
                          test = false;
                        });
                        if (test == false) {
                          _displaySnackBar("Check your internet connection");
                        }
                        if (test == true) {
                          test = false;
                        }
                      } else {
                        FirebaseFirestore.instance
                            .collection("AllProducts")
                            .add(addProd)
                            .whenComplete(() {
                          _displaySnackBar("Successfully added to database");
                          test = true;
                          _name.clear();
                          _pack.clear();
                          _div.clear();
                          _comp.clear();
                        }).catchError((e) {
                          test = false;
                        });
                        if (test == false) {
                          _displaySnackBar("Check your internet connection");
                        }
                        if (test == true) {
                          test = false;
                        }
                      }
                    })
              ],
            ),
          ),
        ));
  }
}

class ProductUpdateForm extends StatefulWidget {
  final ProductData initialData;
  final String docId;
  final String compName;
  ProductUpdateForm(this.initialData, this.docId, this.compName);
  @override
  _ProductUpdateFormState createState() => _ProductUpdateFormState();
}

class _ProductUpdateFormState extends State<ProductUpdateForm> {
  TextEditingController _name = TextEditingController();
  TextEditingController _pack = TextEditingController();
  TextEditingController _comp = TextEditingController();
  TextEditingController _div = TextEditingController();
  ProductData newProd = ProductData();
  bool test = true;

  @override
  void initState() {
    super.initState();
    _name.text = widget.initialData.name;
    _pack.text = widget.initialData.pack;
    _div.text = widget.initialData.division;
    _comp.text = widget.compName;
    populateComp();
  }

  List<String> _companies = [];
  String company;
  void populateComp() {
    _companies.clear();
    FirebaseFirestore.instance
        .collection("Company")
        .orderBy('compName')
        .snapshots()
        .listen((event) {
      event.docs.forEach((element) {
        if (!_companies.contains(element.data()['compName']))
          _companies.add(element.data()['compName']);
      });
    });
    //print(_companies);
  }

  List comp = [];
  FutureOr<Iterable<dynamic>> getSuggestions(String pattern) {
    comp.clear();
    _companies.forEach((element) {
      element.startsWith(pattern.toUpperCase()) ? comp.add(element) : null;
    });
    return comp;
  }

  _displaySnackBar(String action) {
    final snackbar = SnackBar(content: Text(action));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  final _scaffoldKey4 = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey4,
      appBar: new AppBar(
        backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
        title: Text("Update Product Details"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        width: 500,
        decoration: BoxDecoration(color: Colors.grey[100]),
        child: new Column(
          children: <Widget>[
            // Padding(
            //   padding: EdgeInsets.only(top: 10),
            //   child: Text("Enter Company Details", textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),)
            // ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                  controller: _name,
                  //textAlign: TextAlign.center,
                  decoration: new InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    labelText: "Name",
                    fillColor: Colors.white,
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                      borderSide: new BorderSide(),
                    ),
                  )),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                  controller: _pack,
                  decoration: new InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    labelText: "Pack",
                    fillColor: Colors.black,
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                      borderSide: new BorderSide(),
                    ),
                  )),
            ),
            Padding(
                padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                child: TypeAheadField(
                  textFieldConfiguration: TextFieldConfiguration(
                      autofocus: false,
                      controller: _comp,
                      //   style: DefaultTextStyle.of(context).style.copyWith(
                      //   fontStyle: FontStyle.italic
                      // ),
                      decoration: new InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        labelText: "Company",
                        fillColor: Colors.black,
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(15.0),
                          borderSide: new BorderSide(),
                        ),
                      )),
                  suggestionsCallback: (pattern) {
                    return getSuggestions(pattern);
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: Text(suggestion),
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    setState(() {
                      _comp.text = suggestion.toString();
                    });
                  },
                )),
            Padding(
              padding:
                  EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 30),
              child: TextField(
                  controller: _div,
                  decoration: new InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    labelText: "Division",
                    enabled: true,
                    fillColor: Colors.black,
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                      borderSide: new BorderSide(),
                    ),
                  )),
            ),
            ElevatedButton(
                // child: Center(
                child: Text("SUBMIT",
                    style:
                        TextStyle(fontSize: 20, fontStyle: FontStyle.normal)),

                // padding: EdgeInsets.all(30),
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    newProd.name = _name.text;
                    newProd.compCode = _comp.text;
                    newProd.pack = _pack.text;
                    newProd.division = _div.text;
                  });
                  Map<String, dynamic> addProd = newProd.toJson();
                  FirebaseFirestore.instance
                      .collection("AllProducts")
                      .doc(widget.docId)
                      .update(addProd)
                      .whenComplete(() {
                    _displaySnackBar("Successfully updated to database");
                    test = true;
                    _name.clear();
                    _pack.clear();
                    _div.clear();
                    _comp.clear();
                  }).catchError((e) {
                    test = false;
                  });
                  if (test == false) {
                    _displaySnackBar("Check your internet connection");
                  }
                  if (test == true) {
                    test = false;
                  }
                })
          ],
        ),
      ),
    );
  }
}

// class ProfileUpdateForm extends StatefulWidget {

//   final ProductData initialData;
//   final String docId;
//   final String compName;
//   ProfileUpdateForm(this.initialData, this.docId, this.compName);
//   @override
//   _ProfileUpdateFormState createState() => _ProfileUpdateFormState();
// }

// class _ProfileUpdateFormState extends State<ProfileUpdateForm> {

// TextEditingController _name = TextEditingController();
// TextEditingController _email = TextEditingController();
// TextEditingController _pass = TextEditingController();
// ProductData newProd = ProductData();
// bool test = true;

// @override
// void initState(){
//   super.initState();
//   _name.text = widget.initialData.name;
//   _email.text = widget.initialData.pack;
// }

// _displaySnackBar(String action){
//            final snackbar = SnackBar(content: Text(action));
//  _scaffoldKey4.currentState.showSnackBar(snackbar);

// }
//   final _scaffoldKey4 = GlobalKey<ScaffoldMessengerState>();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: _scaffoldKey4,
//       appBar: new AppBar(
//         backgroundColor: Color.fromRGBO(58, 66, 86, 1.0),
//         title: Text("Update Product Details"),
//         leading: IconButton(icon: Icon(Icons.arrow_back),
//         onPressed: (){
//           Navigator.pop(context);     },),),
//       body: Container(
//           width: 500,
//         decoration: BoxDecoration(
//          color: Colors.grey[100]
//         ),
//         child: new Column(
//           children: <Widget>[
//             // Padding(
//             //   padding: EdgeInsets.only(top: 10),
//             //   child: Text("Enter Company Details", textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),)
//             // ),
//             Padding(
//               padding: EdgeInsets.only(top: 30, left: 20, right: 20),
//               child: TextField(
//                 controller: _name,
//                 //textAlign: TextAlign.center,
//                 decoration: new InputDecoration(
//                               contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                labelText: "Name",
//                               fillColor: Colors.white,
//                                border: new OutlineInputBorder(
//                                  borderRadius: new BorderRadius.circular(15.0),
//                                  borderSide: new BorderSide(),
//                                 ),)

//               ),
//             ),
//              Padding(
//               padding: EdgeInsets.only(top: 30, left: 20, right: 20,bottom: 30),
//               child: TextField(
//                 controller: _pack,
//                 decoration: new InputDecoration(
//                               contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                labelText: "Pack",
//                                  fillColor: Colors.black,
//                                border: new OutlineInputBorder(
//                                  borderRadius: new BorderRadius.circular(15.0),
//                                  borderSide: new BorderSide(),
//                                 ),)

//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.only(top: 30, left: 20, right: 20,bottom: 30),
//               child: TextField(
//                 controller: _pack,
//                 decoration: new InputDecoration(
//                               contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//                                labelText: "Password",
//                                  fillColor: Colors.black,
//                                border: new OutlineInputBorder(
//                                  borderRadius: new BorderRadius.circular(15.0),
//                                  borderSide: new BorderSide(),
//                                 ),)

//               ),),
//             ElevatedButton(
//              // child: Center(
//                 child: Text("SUBMIT", style: TextStyle(
//                   fontSize: 20, fontStyle: FontStyle.normal
//                 )),

//              // padding: EdgeInsets.all(30),
//               onPressed: () async {
//                 FocusScope.of(context).unfocus();
//                 setState(() {
//                  newProd.name = _name.text;
//                  newProd.pack = _pack.text;
//                 });
//       Map<String, dynamic> addProd = newProd.toJson();
//       FirebaseFirestore.instance.collection(widget.compName).doc(widget.docId).updateData(addProd).whenComplete((){
//           _displaySnackBar("Successfully updated to database");
//           test = true;
//           _name.clear();
//           _pack.clear();
//       }).catchError((e) {
//              test = false;
//       });
//       if(test == false){
//           _displaySnackBar("Check your internet connection");
//       }
//       if(test == true){
//         test =false;
//       }

//               })

//           ],
//         ),
//       ),
//     );
//   }
// }

class PartyForm extends StatefulWidget {
  @override
  _PartyFormState createState() => _PartyFormState();
}

class _PartyFormState extends State<PartyForm> {
  TextEditingController _name = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _dd = TextEditingController();
  PartyData newParty = PartyData();
  bool test = true;

  @override
  void initState() {
    super.initState();
    _name.clear();
    _email.clear();
    _dd.clear();
  }

  _displaySnackBar(String action) {
    final snackbar = SnackBar(content: Text(action));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  final _scaffoldKey1 = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey1,
        backgroundColor: Color(0xFF2C3E50),
        resizeToAvoidBottomInset: true,
        appBar: new AppBar(
          backgroundColor: Color(0xFF2C3E50),
          elevation: 0,
          title: Text(
            "Add New Party",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto',
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
          child: SingleChildScrollView(
            physics: ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 20.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: Column(
              children: <Widget>[
                // Padding(
                //   padding: EdgeInsets.only(top: 10),
                //   child: Text("Enter Company Details", textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),)
                // ),
                Padding(
                  padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                  child: TextField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (value) {
                        FocusScope.of(context).nextFocus();
                      },
                      //textAlign: TextAlign.center,
                      decoration: new InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        labelText: "Name",
                        fillColor: Colors.white,
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(15.0),
                          borderSide: new BorderSide(),
                        ),
                      )),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                  child: TextField(
                      controller: _email,
                      decoration: new InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        labelText: "Email",
                        fillColor: Colors.black,
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(15.0),
                          borderSide: new BorderSide(),
                        ),
                      )),
                ),
                Padding(
                  padding:
                      EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 30),
                  child: TextField(
                      controller: _dd,
                      //textAlign: TextAlign.center,
                      decoration: new InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 20),
                        labelText: "Default Discount",
                        fillColor: Colors.white,
                        border: new OutlineInputBorder(
                          borderRadius: new BorderRadius.circular(15.0),
                          borderSide: new BorderSide(),
                        ),
                      )),
                ),
                ElevatedButton(
                    // child: Center(
                    child: Text("SUBMIT",
                        style: TextStyle(
                            fontSize: 20, fontStyle: FontStyle.normal)),

                    // padding: EdgeInsets.all(30),
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        newParty.name = _name.text;
                        newParty.email = _email.text;
                        newParty.defaultDiscount = double.parse(_dd.text);
                      });
                      //   CollectionReference dbReplies = FirebaseFirestore.instance.collection('Company');

                      // FirebaseFirestore.instance.runTransaction((Transaction tx) async {
                      //   print(await dbReplies.add(newComp.toJson()));
                      //               },

                      // );
                      Map<String, dynamic> addParty = newParty.toJson();
                      FirebaseFirestore.instance
                          .collection('Party')
                          .add(addParty)
                          .whenComplete(() {
                        _displaySnackBar("Successfully added to database");
                        test = true;
                        _name.clear();
                        _email.clear();
                        _dd.clear();
                      }).catchError((e) {
                        test = false;
                      });
                      if (test == false) {
                        _displaySnackBar("Check your internet connection");
                      }
                      if (test == true) {
                        test = false;
                      }
                    })
              ],
            ),
          ),
        ));
  }
}

class PartyUpdateForm extends StatefulWidget {
  final PartyData initialData;
  final String docId;
  PartyUpdateForm(this.initialData, this.docId);
  @override
  _PartyUpdateFormState createState() => _PartyUpdateFormState();
}

class _PartyUpdateFormState extends State<PartyUpdateForm> {
  TextEditingController _name = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _dd = TextEditingController();
  PartyData newComp = PartyData();
  bool test = true;

  @override
  void initState() {
    super.initState();
    _name.text = widget.initialData.name;
    _email.text = widget.initialData.email;
    _dd.text = widget.initialData.defaultDiscount.toString();
  }

  _displaySnackBar(String action) {
    final snackbar = SnackBar(content: Text(action));
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }

  final _scaffoldKey2 = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey2,
      appBar: new AppBar(
        title: Text("Update Party Details"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        width: 500,
        decoration: BoxDecoration(color: Colors.grey[100]),
        child: new Column(
          children: <Widget>[
            // Padding(
            //   padding: EdgeInsets.only(top: 10),
            //   child: Text("Enter Company Details", textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),)
            // ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                  controller: _name,
                  //textAlign: TextAlign.center,
                  decoration: new InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    labelText: "Name",
                    fillColor: Colors.white,
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                      borderSide: new BorderSide(),
                    ),
                  )),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: TextField(
                  controller: _email,
                  decoration: new InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    labelText: "Email",
                    fillColor: Colors.black,
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                      borderSide: new BorderSide(),
                    ),
                  )),
            ),
            Padding(
              padding:
                  EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 30),
              child: TextField(
                  controller: _dd,
                  //textAlign: TextAlign.center,
                  decoration: new InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    labelText: "Default Discount",
                    fillColor: Colors.white,
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(15.0),
                      borderSide: new BorderSide(),
                    ),
                  )),
            ),
            ElevatedButton(
                // child: Center(
                child: Text("SUBMIT",
                    style:
                        TextStyle(fontSize: 20, fontStyle: FontStyle.normal)),

                // padding: EdgeInsets.all(30),
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    newComp.name = _name.text;
                    newComp.email = _email.text;
                    newComp.defaultDiscount = double.parse(_dd.text);
                  });
                  Map<String, dynamic> addComp = newComp.toJson();
                  FirebaseFirestore.instance
                      .collection('Party')
                      .doc(widget.docId)
                      .update(addComp)
                      .whenComplete(() {
                    _displaySnackBar("Successfully updated to database");
                    test = true;
                    _name.clear();
                    _email.clear();
                    _dd.clear();
                  }).catchError((e) {
                    test = false;
                  });
                  if (test == false) {
                    _displaySnackBar("Check your internet connection");
                  }
                  if (test == true) {
                    test = false;
                  }
                })
          ],
        ),
      ),
    );
  }
}
