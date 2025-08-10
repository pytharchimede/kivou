import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickCallSheet extends StatelessWidget {
  final String phoneNumber;
  final String? message;

  const QuickCallSheet({super.key, required this.phoneNumber, this.message});

  static Future<void> show(BuildContext context,
      {required String phoneNumber, String? message}) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
          child: QuickCallSheet(phoneNumber: phoneNumber, message: message)),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 12),
          Text('Contacter', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.call),
            title: const Text('Appeler'),
            subtitle: Text(phoneNumber),
            onTap: () => _launch('tel:$phoneNumber'),
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('SMS'),
            onTap: () => _launch(
                'sms:$phoneNumber?body=${Uri.encodeComponent(message ?? "Bonjour !")}'),
          ),
        ],
      ),
    );
  }
}
