import 'package:flutter/material.dart';
import 'cloud.dart';  // Import the cloud.dart file
import 'offline.dart';
import 'Verification.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  // List of widgets for bottom navigation
  List<Widget> _widgetOptions = <Widget>[
    CloudWidget(), // Cloud widget as one option
    OfflineWidget(), // Placeholder for Offline widget
    VerificationScreen(), // Placeholder for Share widget
    Center(child: Text('Settings Widget')), // Placeholder for Settings widget
  ];

  // Function to handle bottom navigation bar change
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with a custom style
      appBar: AppBar(
        title: Text('LightViewer', style: TextStyle(fontWeight: FontWeight.bold,
	color: Colors.white
)),
        backgroundColor: Colors.deepPurple, // Use a deep purple background
        elevation: 5, // Add some elevation for a modern shadow effect
        centerTitle: true, // Center the title in the AppBar
      ),
      body: _widgetOptions[_selectedIndex], // Display widget based on selected index
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensure fixed type for proper background color
        backgroundColor: Colors.deepPurple, // Use deep purple for the bottom navigation bar
        selectedItemColor: Colors.white, // Change selected icon color to white
        unselectedItemColor: Colors.white70, // Change unselected icon color to a lighter shade
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Cloud',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.offline_bolt),
            label: 'Offline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified),
            label: 'Verified',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
