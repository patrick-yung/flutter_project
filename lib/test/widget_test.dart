import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patients_management/addpatients.dart'; // Adjust the path as needed


void main() {
  // Helper function to scroll to and tap a widget
  Future<void> tapAndScroll(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  group('Basic Rendering', () {
    testWidgets('Widget loads', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      expect(find.byType(AddPatients), findsOneWidget);
    });

    testWidgets('Has title and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      
      expect(find.text('Add New Patient'), findsOneWidget);
      expect(find.text('Save Patient'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Has 3 form fields', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      expect(find.byType(TextFormField), findsNWidgets(3));
    });
  });

  group('Validation', () {
    testWidgets('Empty name shows error', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      
      await tapAndScroll(tester, find.text('Save Patient'));
      
      expect(find.text('Please enter patient name'), findsOneWidget);
    });

    testWidgets('Empty age shows error', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      
      await tester.enterText(find.byType(TextFormField).first, 'John Doe');
      await tapAndScroll(tester, find.text('Save Patient'));
      
      expect(find.text('Please enter age'), findsOneWidget);
    });

    testWidgets('Empty department shows error', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      
      await tester.enterText(find.byType(TextFormField).first, 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), '45');
      await tapAndScroll(tester, find.text('Save Patient'));
      
      expect(find.text('Please enter department'), findsOneWidget);
    });

    testWidgets('Age over 150 shows error', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      
      await tester.enterText(find.byType(TextFormField).first, 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), '200');
      await tester.enterText(find.byType(TextFormField).at(2), 'Cardiology');
      await tapAndScroll(tester, find.text('Save Patient'));
      
      expect(find.text('Please enter a valid age (1-150)'), findsOneWidget);
    });

    testWidgets('Negative age shows error', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      
      await tester.enterText(find.byType(TextFormField).first, 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), '-5');
      await tester.enterText(find.byType(TextFormField).at(2), 'Cardiology');
      await tapAndScroll(tester, find.text('Save Patient'));
      
      expect(find.text('Please enter a valid age (1-150)'), findsOneWidget);
    });
  });

  group('Valid Input', () {
    testWidgets('Accepts valid age 45', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      
      await tester.enterText(find.byType(TextFormField).first, 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), '45');
      await tester.enterText(find.byType(TextFormField).at(2), 'Cardiology');
      await tapAndScroll(tester, find.text('Save Patient'));
      
      expect(find.text('Please enter a valid age (1-150)'), findsNothing);
    });

    testWidgets('Accepts age 1 (minimum)', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      
      await tester.enterText(find.byType(TextFormField).first, 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), '1');
      await tester.enterText(find.byType(TextFormField).at(2), 'Cardiology');
      await tapAndScroll(tester, find.text('Save Patient'));
      
      expect(find.text('Please enter a valid age (1-150)'), findsNothing);
    });

    testWidgets('Accepts age 150 (maximum)', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      
      await tester.enterText(find.byType(TextFormField).first, 'John Doe');
      await tester.enterText(find.byType(TextFormField).at(1), '150');
      await tester.enterText(find.byType(TextFormField).at(2), 'Cardiology');
      await tapAndScroll(tester, find.text('Save Patient'));
      
      expect(find.text('Please enter a valid age (1-150)'), findsNothing);
    });
  });

  group('Critical Checkbox', () {
    testWidgets('Checkbox exists and shows warning', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AddPatients()));
      await tester.pump();
      
      expect(find.text('Critical Condition'), findsOneWidget);
      
      await tapAndScroll(tester, find.text('Critical Condition'));
      
      expect(find.textContaining('CRITICAL'), findsAtLeastNWidgets(1));
    });
  });
}