import 'package:flutter/material.dart';
import 'detect_screen.dart';
import 'results_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // Inicialmente en Detectar (índice 2)
  
  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      const ResultsScreen(), // Resultados
      const ReportsScreen(), // Reportes
      const DetectScreen(),  // Detectar (pantalla principal)
      const ProfileScreen(), // Perfil
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF0D1A2A),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Resultados',
            backgroundColor: const Color(0xFF0D1A2A),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reportes',
            backgroundColor: const Color(0xFF0D1A2A),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Detectar',
            backgroundColor: const Color(0xFF0D1A2A),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
            backgroundColor: const Color(0xFF0D1A2A),
          ),
        ],
      ),
    );
  }
}
