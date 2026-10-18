import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置')
      ),
      body: const Center(
        child: Text(
            '敬请期待喵！',
            style: TextStyle(
              fontSize: 24
            ),
        ),
      ),
      bottomNavigationBar: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DayFlow  |  1.3.0',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  'By CYmuke',
                  style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                  ),
                )
              ],
            ),
          )
      ),
    );
  }
}