import 'dart:convert';
import 'package:flutter/foundation.dart';

abstract class RemoteSourceInterface {
  @protected
  String get baseUrl => 'https://api.dollarbills.app';

  Map<String, String> get baseHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @protected
  void checkResponse(int statusCode, dynamic body) {
    if (statusCode != 200 && statusCode != 201) {
      if (body is Map<String, dynamic> && body.containsKey('mensaje')) {
        throw body['mensaje'];
      }
      throw body ?? 'Error en la petición del servidor ($statusCode)';
    }
  }

  @protected
  dynamic parseJson(String responseBody) {
    try {
      return jsonDecode(responseBody);
    } catch (_) {
      return responseBody;
    }
  }
}
