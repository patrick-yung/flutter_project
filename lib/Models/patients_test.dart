// lib/Models/patients_test.dart
class PatientsTest {
  final String id;
  final String testType;
  final String testResult;
  final DateTime testDate;

  PatientsTest({
    required this.id,
    required this.testType,
    required this.testResult,
    required this.testDate,
  });

  factory PatientsTest.fromJson(Map<String, dynamic> json) {
    return PatientsTest(
      id: json['_id'] ?? '',
      testType: json['testType'] ?? '',
      testResult: json['testResult'] ?? '',
      testDate: json['testDate'] != null 
          ? DateTime.parse(json['testDate']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testType': testType,
      'testResult': testResult,
      // testDate will be added automatically by backend
    };
  }
}