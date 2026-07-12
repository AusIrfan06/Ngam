import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'lib/utils/constants.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);
  
  try {
    final response = await client
        .from(DbTable.gigs)
        .select('*, customer:users!customer_id(name), runner:users!gig_worker_id(name)')
        .limit(1);
    print('SUCCESS: $response');
  } catch (e) {
    print('ERROR: $e');
  }
}
