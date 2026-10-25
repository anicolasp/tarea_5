import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/post.dart';
import '../models/user.dart';

/// No hay conexión a Internet (o el servidor no es alcanzable).
class NoInternetException implements Exception {
  const NoInternetException();

  @override
  String toString() => 'NoInternetException';
}

/// La API respondió, pero no como se esperaba (código, tiempo o formato).
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException: $message';
}

/// Cliente HTTP de JSONPlaceholder.
///
/// Solo lanza [NoInternetException] o [ApiException]; cualquier otro fallo
/// se convierte en una de las dos para que la UI nunca reciba una excepción
/// inesperada.
class ApiClient {
  ApiClient({
    http.Client? client,
    this.baseUrl = 'https://jsonplaceholder.typicode.com',
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final String baseUrl;
  final Duration timeout;

  Future<List<User>> fetchUsers() =>
      _getList(Uri.parse('$baseUrl/users'), User.fromJson);

  Future<List<Post>> fetchPosts(int userId) => _getList(
    Uri.parse('$baseUrl/posts').replace(queryParameters: {'userId': '$userId'}),
    Post.fromJson,
  );

  Future<List<T>> _getList<T>(
    Uri uri,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on IOException {
      // SocketException, HandshakeException (p. ej. portal cautivo), etc.
      throw const NoInternetException();
    } on http.ClientException {
      throw const NoInternetException();
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } catch (_) {
      throw const ApiException('No se pudo completar la solicitud.');
    }

    if (response.statusCode != 200) {
      throw ApiException('El servidor respondió ${response.statusCode}.');
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      return [
        for (final item in decoded) fromJson(item as Map<String, dynamic>),
      ];
    } on FormatException {
      throw const ApiException('La respuesta no es un JSON válido.');
    } on TypeError {
      throw const ApiException('La respuesta tiene un formato inesperado.');
    }
  }

  /// Cierra el cliente HTTP solo si lo creó este [ApiClient].
  void close() {
    if (_ownsClient) _client.close();
  }
}
