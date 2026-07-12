import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PaymentService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all payment methods for the current user
  static Future<List<Map<String, dynamic>>> fetchPaymentMethods() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('payment_methods')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    // Gubah baris data Supabase jadi bentuk yang WalletScreen faham
    return response.map((row) {
      final type = row['type'] as String;
      final map = <String, dynamic>{
        'id': row['id'],
        'type': type,
        'isPrimary': row['is_primary'] ?? false,
        'color': row['color_index'] ?? 0,
        'holder': row['holder_name'], // Baru ditambah
      };

      if (type == 'card') {
        map['name'] = row['name'];
        map['last4'] = row['details'];
        map['expiry'] = row['expiry'];
      } else if (type == 'bank') {
        map['bankName'] = row['name'];
        map['accountNumber'] = row['details'];
      } else if (type == 'duitnow_qr') {
        map['qrPath'] = row['details'];
      }
      return map;
    }).toList();
  }

  /// Add a new payment method
  static Future<void> addPaymentMethod(Map<String, dynamic> methodData) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("Not logged in");

    // Convert UI punya data balik jadi baris DB
    final row = <String, dynamic>{
      'id': const Uuid().v4(),
      'user_id': userId,
      'type': methodData['type'],
      'is_primary': methodData['isPrimary'] ?? false,
      'color_index': methodData['color'] ?? 0,
      'holder_name': methodData['holder'], // Baru ditambah
    };

    if (methodData['type'] == 'card') {
      row['name'] = methodData['name'];
      row['details'] = methodData['last4'];
      row['expiry'] = methodData['expiry'];
    } else if (methodData['type'] == 'bank') {
      row['name'] = methodData['name'] ?? methodData['bankName'];
      row['details'] = methodData['accountNumber'];
    } else if (methodData['type'] == 'duitnow_qr') {
      row['details'] = methodData['qrPath'];
    }

    await _supabase.from('payment_methods').insert(row);
  }

  /// Delete a payment method
  static Future<void> deletePaymentMethod(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    await _supabase.from('payment_methods').delete().eq('id', id).eq('user_id', userId);
  }

  /// Set a payment method as primary (and unset others)
  static Future<void> setPrimaryPaymentMethod(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // First set all methods for this user to is_primary = false
    await _supabase
        .from('payment_methods')
        .update({'is_primary': false})
        .eq('user_id', userId);

    // Lepas tu set option yang dia pilih tu jadi true
    await _supabase
        .from('payment_methods')
        .update({'is_primary': true})
        .eq('id', id)
        .eq('user_id', userId);
  }
}
