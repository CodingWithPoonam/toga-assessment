// Deliberately flawed static review excerpt. Not a runnable app.
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

const providerSecret = 'SYNTHETIC_NOT_A_REAL_SECRET';
Future<Dio> makeClient() async {
  final prefs = await SharedPreferences.getInstance();
  final dio = Dio(BaseOptions(baseUrl: 'http://api.invalid'));
  dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () {
    return HttpClient()..badCertificateCallback = (cert, host, port) => true;
  });
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      options.headers['Authorization'] = prefs.getString('access_token');
      print('request: ${options.headers} ${options.data}');
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final refreshed = await dio.post('/auth/refresh', data: {
          'refresh_token': prefs.getString('refresh_token'),
        });
        await prefs.setString('access_token', refreshed.data['access_token']);
        handler.resolve(await dio.fetch(error.requestOptions));
      } else {
        handler.next(error);
      }
    },
  ));
  return dio;
}
