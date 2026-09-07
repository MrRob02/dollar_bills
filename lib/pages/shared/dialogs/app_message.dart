class ErrorMessage implements Exception {
  final String? message;
  final Object? exception;

  const ErrorMessage({this.message, this.exception});

  String get displayMessage => message ?? kErrorMessage;

  bool get hasException => exception != null;

  @override
  String toString() {
    if (exception != null) return exception.toString();
    return displayMessage;
  }
}

const String kErrorMessage = 'Algo salió mal. Inténtalo nuevamente.';
