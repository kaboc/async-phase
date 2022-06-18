import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.0,
      color: Colors.grey.shade200,
      child: const Center(
        child: Text(
          'Thanks to:\n'
          'Random Useless Facts\n'
          'https://uselessfacts.jsph.pl/',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 11.0),
        ),
      ),
    );
  }
}
