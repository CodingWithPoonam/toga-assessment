// Deliberately flawed static review excerpt. prefs is ordinary preferences.
import 'dart:convert';

Future<void> saveDraft(dynamic prefs, String lessonId, Map draft) async {
  await prefs.setString('draft_$lessonId', jsonEncode(draft));
}
Future<void> logout(dynamic prefs, dynamic router) async {
  await prefs.remove('access_token');
  router.go('/login');
}
