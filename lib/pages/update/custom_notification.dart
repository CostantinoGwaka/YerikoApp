import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String body;
  final BuildContext context;

  const CustomDialog({super.key, required this.title, required this.body, required this.context});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black54, // Set background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0), // Rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                color: Colors.white, // White text for the title
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: const TextStyle(
                color: Colors.white70, // Lighter white text for the content
                fontSize: 12.0,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true), // Close dialog and return true
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.redAccent, fontSize: 16.0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
