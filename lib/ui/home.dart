import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:startup_namer/globals.dart';
import 'package:startup_namer/utils/firebase_storage_service.dart';

import './expiryMenu.dart';
import './inventoryMenu.dart';
import './letterheadList.dart';
import './party.dart';

class Home extends StatelessWidget {
  Future<List<String>> populateComp() async {
    List<String> _companies = [];
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection("Company")
        .orderBy('compName')
        .get();

    snapshot.docs.forEach((element) {
      if (!_companies.contains(element.data()['compName'])) {
        _companies.add(element.data()['compName']);
      }
    });

    return _companies;
  }

  void _showDataManagementDialog(BuildContext context) {
    bool isDownloading = false;
    double progress = 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Data Management"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Download the latest CSV data files from Firebase Storage to update your local data.",
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  if (isDownloading) ...[
                    Text(
                      "Downloading files...",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: isDownloading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.cloud_download),
                      label: Text(
                        isDownloading ? "Downloading..." : "Upgrade Data",
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                        onPrimary: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isDownloading
                          ? null
                          : () async {
                              setState(() {
                                isDownloading = true;
                                progress = 0.0;
                              });

                              try {
                                // Use real progress updates from Firebase Storage
                                bool success = await FirebaseStorageService
                                    .downloadAllCSVFilesWithProgress(
                                        (double progressValue) {
                                  setState(() {
                                    progress = progressValue;
                                  });
                                });

                                // Load all CSV data in parallel after downloading
                                bool dataLoaded = await loadAllCSVData();

                                if (success && dataLoaded) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Data files downloaded successfully!")),
                                  );
                                  Navigator.of(context).pop();
                                } else if (!success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Some files failed to download. Please try again.")),
                                  );
                                } else if (!dataLoaded) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Files downloaded but failed to load data. Please try again.")),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text("Error downloading files: $e")),
                                );
                              } finally {
                                setState(() {
                                  isDownloading = false;
                                  progress = 0.0;
                                });
                              }
                            },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C3E50),
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
        child: Column(
          children: [
            // Custom Header
            Container(
              padding: EdgeInsets.only(top: 50, bottom: 20),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      "asset/mp.webp",
                      width: 100,
                      height: 100,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Mahesh Pharma",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      fontFamily: 'Roboto',
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Pharmaceutical Management System",
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
            // Content List
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  // Order Console Card
                  _buildFeatureCard(
                    context,
                    icon: Icons.shopping_cart,
                    iconColor: Color(0xFF9B59B6),
                    title: 'Inventory Management',
                    subtitle: 'Create and manage inventory',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => InventoryMenu()),
                      );
                    },
                  ),

                  // Expiry Console Card
                  _buildFeatureCard(
                    context,
                    icon: Icons.warning,
                    iconColor: Color(0xFFF39C12),
                    title: 'Expiry Management',
                    subtitle: 'Manage Expired Goods',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PartyPage()),
                      );
                    },
                  ),

                  // Generate Report Card
                  _buildFeatureCard(
                    context,
                    icon: Icons.assessment,
                    iconColor: Color(0xFF27AE60),
                    title: 'Reports Portal',
                    subtitle: 'View and analyze reports',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExpiryMenu()),
                      );
                    },
                  ),

                  // Generate Letter Card
                  _buildFeatureCard(
                    context,
                    icon: Icons.description,
                    iconColor: Color(0xFF3498DB),
                    title: 'Letter Templates',
                    subtitle: 'Create and manage letterheads',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LetterHeadPage()),
                      );
                    },
                  ),

                  // Data Management Card
                  _buildFeatureCard(
                    context,
                    icon: Icons.cloud_download,
                    iconColor: Color(0xFF1ABC9C),
                    title: 'Sync & Manage',
                    subtitle: 'Download and update data',
                    onTap: () {
                      _showDataManagementDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    IconData icon,
    Color iconColor,
    String title,
    String subtitle,
    VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 6.0,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34495E),
                Color(0xFF2C3E50),
              ],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: iconColor,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 13,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[300],
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
