import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'lib/utils/constants.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  
  try {
    // Get a valid user ID first
    final userResp = await client.from('users').select('id, balance').limit(1).single();
    final customerId = userResp['id'];
    
    final gigId = Uuid().v4();
    
    final response = await client.rpc('create_gig_with_payment', params: {
      'p_id': gigId,
      'p_customer_id': customerId,
      'p_gig_worker_id': null,
      'p_title': 'Test Gig',
      'p_description': 'Test Description',
      'p_category': 'Food',
      'p_bounty_amount': 5.0,
      'p_status': 'OPEN',
      'p_location': 'Test Location',
      'p_latitude': 3.14,
      'p_longitude': 101.68,
    });
    
    print('SUCCESS: $response');
  } catch (e) {
    print('ERROR: $e');
  }
}
