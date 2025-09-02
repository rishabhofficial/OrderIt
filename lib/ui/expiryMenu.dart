import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import './expirySentProduct.dart';
import './localPartyReport.dart';
import './multipleReportsSetup.dart';
import './salesReport.dart';

class ExpiryMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C3E50),
      appBar: AppBar(
        backgroundColor: Color(0xFF2C3E50),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Reports Menu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
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
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Menu Options
                Column(
                  children: [
                    // Sales Report Option
                    _buildMenuOption(
                      context,
                      icon: Icons.analytics,
                      iconColor: Color(0xFFE74C3C),
                      title: 'Stock Report',
                      subtitle: 'View detailed stock analytics and reports',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SalesReport()),
                        );
                      },
                    ),

                    SizedBox(height: 4),

                    // Multiple Reports Option
                    _buildMenuOption(
                      context,
                      icon: Icons.list_alt,
                      iconColor: Color(0xFF9B59B6),
                      title: 'Multiple Reports',
                      subtitle: 'Generate multiple reports at once',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MultipleReportsSetup()),
                        );
                      },
                    ),

                    SizedBox(height: 4),

                    // Purchase Report Option
                    _buildMenuOption(
                      context,
                      icon: Icons.shopping_cart,
                      iconColor: Color(0xFFF39C12),
                      title: 'Purchase Report',
                      subtitle: 'Analyze purchase history and trends',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LocalPartyReport()),
                        );
                      },
                    ),

                    SizedBox(height: 4),

                    // Expiry Report Option
                    _buildMenuOption(
                      context,
                      icon: Icons.warning,
                      iconColor: Color(0xFFE67E22),
                      title: 'Expiry Report',
                      subtitle: 'Monitor product expiry dates and alerts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ExpirySentProductList(
                                  "", "", 0.0, 0.0, Timestamp.now())),
                        );
                      },
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

  Widget _buildMenuOption(
    BuildContext context, {
    IconData icon,
    Color iconColor,
    String title,
    String subtitle,
    VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 4.0),
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
                        size: 28,
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
