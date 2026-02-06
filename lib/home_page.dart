import 'package:flutter/material.dart';
import 'Models/patients_table.dart';
import 'Models/patients.dart';
import 'Models/button.dart';
import 'addpatients.dart';
import 'view_patients.dart';


class HomePage extends StatelessWidget {
  int _selectedIndex = 0;

  final List<Widget> _screens = [Viewpatients(), Addpatients()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _screens[_selectedIndex],
    );
  }
}