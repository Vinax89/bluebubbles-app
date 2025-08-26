import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bluebubbles/services/services.dart';

class SessionManagementPage extends StatefulWidget {
  const SessionManagementPage({super.key});

  @override
  State<SessionManagementPage> createState() => _SessionManagementPageState();
}

class _SessionManagementPageState extends State<SessionManagementPage> {
  @override
  void initState() {
    super.initState();
    sessionRegistry.loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Sessions')),
      body: Obx(() {
        final sessions = sessionRegistry.sessions;
        if (sessions.isEmpty) {
          return const Center(child: Text('No active sessions'));
        }
        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final s = sessions[index];
            return ListTile(
              title: Text(s.deviceId),
              subtitle: Text('Expires: ${s.expiresAt}'),
              trailing: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => sessionRegistry.revoke(s.deviceId),
              ),
            );
          },
        );
      }),
    );
  }
}
