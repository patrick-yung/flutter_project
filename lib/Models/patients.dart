import 'package:flutter/material.dart';
import 'patients_test.dart';

class Patient {
  final String id;
  final String name;
  final int age;
  final bool critial;
  final List<PatientsTest> tests; 
  
  Patient({
    required this.id,
    required this.name,
    required this.age,
    this.critial = false,
    this.tests = const [],
  });
}