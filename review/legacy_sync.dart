// Deliberately flawed static review excerpt; api/store are injected abstractions.
import 'dart:convert';

Future<void> drain(dynamic api, dynamic store, dynamic uuid) async {
  final pending = jsonDecode(await store.read('pending') ?? '[]') as List;
  await store.remove('pending');
  for (final payload in pending) {
    try {
      await api.post('/v1/submissions', payload,
          headers: {'Idempotency-Key': uuid.v4()});
    } catch (_) {
      await api.post('/v1/submissions', payload,
          headers: {'Idempotency-Key': uuid.v4()});
    }
  }
}
