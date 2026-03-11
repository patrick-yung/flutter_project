// lib/Models/patient.dart
import 'package:flutter/material.dart';
import 'patients_test.dart';

class Patient {
  final String id;
  final String name;
  final int age;
  final bool critial;
  final String department;
  final List<PatientsTest> tests;
  
  Patient({
    required this.id,
    required this.name,
    required this.age,
    this.critial = false,
    required this.department,
    this.tests = const [],
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      critial: json['critical'] ?? false,
      department: json['deparment'] ?? '', // Note: typo matches backend
      tests: json['test'] != null
          ? List<PatientsTest>.from(
              json['test'].map((x) => PatientsTest.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'age': age.toString(),
      'critical': critial,
      'deparment': department,
      'test': tests.map((test) => test.toJson()).toList(),
    };
  }
}