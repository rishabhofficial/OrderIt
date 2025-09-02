import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactSelectionDialog extends StatefulWidget {
  @override
  _ContactSelectionDialogState createState() => _ContactSelectionDialogState();
}

class _ContactSelectionDialogState extends State<ContactSelectionDialog> {
  List<Contact> contacts = [];
  List<Contact> filteredContacts = [];
  bool isLoading = true;
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  TextEditingController manualPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Request contacts permission
      PermissionStatus status = await Permission.contacts.request();

      if (status.isGranted) {
        // Load contacts
        Iterable<Contact> allContacts = await ContactsService.getContacts();
        setState(() {
          contacts = allContacts.toList();
          filteredContacts = contacts;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // Don't show snackbar here, let the UI handle it gracefully
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading contacts: $e');
    }
  }

  Future<void> _retryPermission() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Request contacts permission again
      PermissionStatus status = await Permission.contacts.request();

      if (status.isGranted) {
        // Load contacts
        Iterable<Contact> allContacts = await ContactsService.getContacts();
        setState(() {
          contacts = allContacts.toList();
          filteredContacts = contacts;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading contacts: $e');
    }
  }

  void _filterContacts(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredContacts = contacts;
      } else {
        filteredContacts = contacts.where((contact) {
          final name = contact.displayName?.toLowerCase() ?? '';
          final phones = contact.phones
                  ?.map((p) => p.value?.toLowerCase() ?? '')
                  .toList() ??
              [];
          return name.contains(query.toLowerCase()) ||
              phones.any((phone) => phone.contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  void _selectManualEntry() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Phone Number'),
          content: TextField(
            controller: manualPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter phone number',
              prefixText: '+91 ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (manualPhoneController.text.isNotEmpty) {
                  Navigator.pop(context);
                  Navigator.pop(context, {
                    'name': 'Manual Entry',
                    'phone': '+91${manualPhoneController.text}',
                  });
                }
              },
              child: Text('Select'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.contact_phone, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Select Contact',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: _filterContacts,
              ),
            ),

            // Manual Entry Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectManualEntry,
                  icon: Icon(Icons.add),
                  label: Text('Enter Phone Number Manually'),
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
            ),

            SizedBox(height: 16),

            // Contacts List
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF2C3E50)),
                      ),
                    )
                  : contacts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.contact_phone,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Contacts Permission Required',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Please grant contacts permission\nto select from your phone contacts',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await openAppSettings();
                                },
                                icon: Icon(Icons.settings),
                                label: Text('Open Settings'),
                                style: ElevatedButton.styleFrom(
                                  primary: Color(0xFF3498DB),
                                  onPrimary: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _retryPermission,
                                icon: Icon(Icons.refresh),
                                label: Text('Retry Permission'),
                                style: ElevatedButton.styleFrom(
                                  primary: Color(0xFF27AE60),
                                  onPrimary: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Or use manual entry below',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        )
                      : filteredContacts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No contacts match your search',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = filteredContacts[index];
                                final phones = contact.phones
                                        ?.map((p) => p.value)
                                        .toList() ??
                                    [];

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Color(0xFF2C3E50),
                                    child: Text(
                                      contact.displayName
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          '?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    contact.displayName ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  subtitle: phones.isNotEmpty
                                      ? Text(phones.first)
                                      : Text('No phone number'),
                                  onTap: () {
                                    if (phones.isNotEmpty) {
                                      Navigator.pop(context, {
                                        'name':
                                            contact.displayName ?? 'Unknown',
                                        'phone': phones.first,
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'This contact has no phone number'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
