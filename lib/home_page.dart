// lib/home_page.dart
import 'package:flutter/material.dart';
import 'addpatients.dart';
import 'view_patients.dart';
import 'splash_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;
    
    _animationController.reset();
    setState(() {
      _selectedIndex = index;
    });
    _animationController.forward();
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // REMOVED the AppBar from here
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens.asMap().entries.map((entry) {
          final index = entry.key;
          final screen = entry.value;
          
          if (index == _selectedIndex) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: screen,
              ),
            );
          }
          return screen;
        }).toList(),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: _navigationItems,
              backgroundColor: Colors.white,
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 300),
              indicatorColor: Colors.blue.shade100,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.white,
            ),
          );
        },
      ),
      // Add a floating logout button
      floatingActionButton: FloatingActionButton(
        onPressed: _logout,
        mini: true,
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.blue.shade800,
        child: const Icon(Icons.logout, size: 20),
        tooltip: 'Logout',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}