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
      '_id': id, // Include id in toJson
      'testType': testType,
      'testResult': testResult,
      // testDate will be added automatically by backend
    };
  }
  
  // Add a copyWith method for easy updates
  PatientsTest copyWith({
    String? id,
    String? testType,
    String? testResult,
    DateTime? testDate,
  }) {
    return PatientsTest(
      id: id ?? this.id,
      testType: testType ?? this.testType,
      testResult: testResult ?? this.testResult,
      testDate: testDate ?? this.testDate,
    );
  }
}