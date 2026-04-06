import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Perfil'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
