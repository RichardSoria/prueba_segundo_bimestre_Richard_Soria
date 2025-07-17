import 'package:flutter/material.dart';
import 'package:mi_supabase_flutter/publisher_page.dart';
import 'package:mi_supabase_flutter/publisher_publications_page.dart';


class PublicadorTabs extends StatefulWidget {
  const PublicadorTabs({super.key});

  @override
  State<StatefulWidget> createState() => _PublicadorTabsState();
}

class _PublicadorTabsState extends State<PublicadorTabs> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    TurismosPage(),
    PublisherPublicationsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,

        selectedItemColor: Color.fromARGB(255, 22, 36, 62),

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Tareas'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Mis Tareas'),
        ],
      ),
    );
  }
}