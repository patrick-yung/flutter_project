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
    required this.tests,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    // Parse tests safely
    List<PatientsTest> testsList = [];
    if (json['test'] != null && json['test'] is List) {
      testsList = List<PatientsTest>.from(
        (json['test'] as List).map((x) => PatientsTest.fromJson(x))
      );
    }
    
    return Patient(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      age: int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      critial: json['critical'] ?? false,
      department: json['deparment'] ?? '', // Note: typo matches backend
      tests: testsList, // Use the parsed list
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
  
  // Add a copyWith method for easy updates
  Patient copyWith({
    String? id,
    String? name,
    int? age,
    bool? critial,
    String? department,
    List<PatientsTest>? tests,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      critial: critial ?? this.critial,
      department: department ?? this.department,
      tests: tests ?? this.tests,
    );
  }
}