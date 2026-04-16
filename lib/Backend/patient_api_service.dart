// lib/services/patient_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/patients.dart';
import '../Models/patients_test.dart';

class PatientApiService {
  static const String _baseUrl = 'http://10.0.2.2:3000'; // For Android emulator
  
  // Add a new patient
  static Future<Patient> addPatient({
    required String name,
    required String age,
    required String department,
    bool critical = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/patients'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'age': age,
          'deparment': department, // Note: Typo matches your API
          'critical': critical,
        }),
      );

      print('Add Patient Response status: ${response.statusCode}');
      print('Add Patient Response body: ${response.body}');

      if (response.statusCode == 201) {
        return Patient.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to add patient: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error adding patient: $e');
      rethrow;
    }
  }

  // Get all patients
  static Future<List<Patient>> getPatients() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/patients'));

      print('Get Patients Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load patients: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching patients: $e');
      rethrow;
    }
  }

  // Get a single patient by ID
  static Future<Patient> getPatient(String patientId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/patients/$patientId'));

      print('Get Patient Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return Patient.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Patient not found');
      } else {
        throw Exception('Failed to load patient: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching patient: $e');
      rethrow;
    }
  }

  // NEW METHOD: Update patient critical status using PATCH
  static Future<Patient> updatePatientCriticalStatus({
    required String patientId,
    required bool critical,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/patients/$patientId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'critical': critical,
        }),
      );

      print('Update Critical Status Response status: ${response.statusCode}');
      print('Update Critical Status Response body: ${response.body}');

      if (response.statusCode == 200) {
        return Patient.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Patient not found');
      } else {
        throw Exception('Failed to update critical status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating critical status: $e');
      rethrow;
    }
  }

  // Add tests to a patient
  static Future<List<PatientsTest>> addPatientTests({
    required String patientId,
    required List<PatientsTest> tests,
    bool critial = false, // New parameter to indicate if the patient is critical
  }) async {
    try {
      // Convert tests to JSON format expected by backend
      final testsJson = tests.map((test) => ({
        'testType': test.testType,
        'testResult': test.testResult,
        // testDate will be added automatically by backend
      })).toList();

      final response = await http.post(
        Uri.parse('$_baseUrl/patients/$patientId/test'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tests': testsJson,
          'critical': critial,
        }),
      );

      print('Add Tests Response status: ${response.statusCode}');
      print('Add Tests Response body: ${response.body}');

      if (response.statusCode == 201) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PatientsTest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to add tests: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error adding tests: $e');
      rethrow;
    }
  }

  // Get all tests for a patient
  static Future<List<PatientsTest>> getPatientTests(String patientId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/patients/$patientId/tests'));

      print('Get Tests Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PatientsTest.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tests: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tests: $e');
      rethrow;
    }
  }

  // Delete a patient
  static Future<void> deletePatient(String patientId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/patients/$patientId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Delete Patient Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete patient: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting patient: $e');
      rethrow;
    }
  }

  // Delete all patients
  static Future<void> deleteAllPatients() async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/patients'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Delete All Patients Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete all patients: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting all patients: $e');
      rethrow;
    }
  }

  // Delete a specific test
  static Future<void> deletePatientTest(String patientId, String testId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/patients/$patientId/tests/$testId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Delete Test Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete test: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting test: $e');
      rethrow;
    }
  }
  // Update patient details (name and age)

// Update patient details (name and age)
static Future<Patient> updatePatientDetails({
  required String patientId,
  required String name,
  required String age,
}) async {
  try {
    // First, get the current patient to retrieve the existing department
    final currentPatient = await getPatient(patientId);
    
    final response = await http.put(
      Uri.parse('$_baseUrl/patients/$patientId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'age': age,
        'deparment': currentPatient.department, // Use existing department
        'critical': currentPatient.critial, // Keep existing critical status
      }),
    );

    print('Update Patient Details Response status: ${response.statusCode}');
    print('Update Patient Details Response body: ${response.body}');

    if (response.statusCode == 200) {
      return Patient.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Patient not found');
    } else {
      throw Exception('Failed to update patient details: ${response.statusCode}');
    }
  } catch (e) {
    print('Error updating patient details: $e');
    rethrow;
  }
}
}