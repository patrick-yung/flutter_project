import 'package:flutter/material.dart';
import 'addpatients.dart';
import 'view_patients.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    ViewPatients(),
    AddPatients(),
  ];

  static const List<NavigationDestination> _navigationItems = [
    NavigationDestination(
      icon: Icon(Icons.list_alt),
      label: 'Patients',
      selectedIcon: Icon(Icons.list_alt, color: Colors.white),
    ),
    NavigationDestination(
      icon: Icon(Icons.person_add),
      label: 'Add Patient',
      selectedIcon: Icon(Icons.person_add, color: Colors.white),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _navigationItems,
        backgroundColor: Colors.white,
        elevation: 8,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}