import 'package:flutter/material.dart';

class PatientsTest {
  final String type;
  final String result;
  final String timestamp;
  PatientsTest({
    required this.type,
    required this.result,
    this.timestamp = "",
  });
}