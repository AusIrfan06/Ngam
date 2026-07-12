import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  final adminClient = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!
  );
  final users = await adminClient.from('users').select('id').limit(1);
  if (users.isEmpty) return;
  final userId = users[0]['id'];
  try {
    await adminClient.from('users').update({'address_lat': 3.14}).eq('id', userId);
    print('SUCCESS');
  } catch (e) {
    print('ERROR: $e');
  }
}
