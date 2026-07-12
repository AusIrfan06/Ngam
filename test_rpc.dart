import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  final client = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // We need to login first to get the access token, or use service role key if we can't login.
  // Actually, wait, do we know the user email/password? No.
  // We can just use the service role key if it's in the .env file.
  
  print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
  
  // Let's check if we have a service role key.
  final serviceRoleKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];
  if (serviceRoleKey != null) {
    print('Service role key found!');
    final adminClient = SupabaseClient(
      dotenv.env['SUPABASE_URL']!,
      serviceRoleKey,
    );
    
    // We can get a random user from users table
    final users = await adminClient.from('users').select('id, balance').limit(1);
    if (users.isEmpty) {
      print('No users found.');
      return;
    }
    
    final userId = users[0]['id'];
    final balance = users[0]['balance'];
    print('Testing with User ID: $userId, Balance: $balance');
    
    try {
      final response = await adminClient.rpc('create_gig_with_payment', params: {
        'p_id': '00000000-0000-0000-0000-000000000001',
        'p_customer_id': userId,
        'p_gig_worker_id': null,
        'p_title': 'Test Task',
        'p_description': 'Test Description',
        'p_category': 'Test',
        'p_bounty_amount': 1.0,
        'p_status': 'OPEN',
        'p_location': 'Test Location',
        'p_latitude': 0.0,
        'p_longitude': 0.0,
      });
      print('RPC Success: $response');
      
      // Cleanup
      await adminClient.from('gigs').delete().eq('id', '00000000-0000-0000-0000-000000000001');
    } catch (e) {
      print('RPC Error: $e');
    }
  } else {
    print('No service role key. Cannot authenticate easily.');
  }
}
