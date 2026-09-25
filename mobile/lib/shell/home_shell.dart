import 'package:flutter/material.dart';

/// The three bespoke hero screens. Everything else comes from Mobile
/// Control's generic forms.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    (label: 'Dashboard', icon: Icons.insights_outlined),
    (label: 'Assistant', icon: Icons.chat_bubble_outline),
    (label: 'Quick send', icon: Icons.send_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_index];
    return Scaffold(
      appBar: AppBar(title: Text(tab.label)),
      body: Center(child: Text('${tab.label} — coming soon')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}
