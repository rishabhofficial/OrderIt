import 'dart:async';

import 'package:flutter/material.dart';
import 'package:startup_namer/globals.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;
  String _loadingMessage = "Initializing...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataWithProgress();
  }

  Future<void> _loadDataWithProgress() async {
    try {
      setState(() {
        _loadingMessage = "Loading product data...";
        _progress = 0.0;
      });

      // Load CSV data and track real progress
      bool success = await loadAllCSVData();

      setState(() {
        _loadingMessage = success ? "Ready!" : "Loading completed";
        _progress = 1.0;
        _isLoading = false;
      });

      // Wait a moment to show completion, then navigate
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/HomeScreen');
      }
    } catch (e) {
      setState(() {
        _loadingMessage = "Error loading data. Please try again.";
        _isLoading = false;
      });

      // Wait a moment then navigate anyway
      await Future.delayed(Duration(milliseconds: 2000));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/HomeScreen');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Container(
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 25,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'asset/mp.webp',
                  width: 160,
                  height: 160,
                ),
              ),

              SizedBox(height: 40),

              // App Title
              Text(
                'Mahesh Pharma',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  fontFamily: 'Roboto',
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Pharmaceutical Management System',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  fontFamily: 'Roboto',
                ),
              ),

              SizedBox(height: 60),

              // Loading Message
              Text(
                _loadingMessage,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  fontFamily: 'Roboto',
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 20),

              // Progress Bar
              Container(
                width: 200,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF3498DB),
                          Color(0xFF2980B9),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 10),

              // Progress Percentage
              Text(
                "${(_progress * 100).toInt()}%",
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  fontFamily: 'Roboto',
                ),
              ),

              SizedBox(height: 40),

              // Loading indicator
              if (_isLoading)
                Container(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
