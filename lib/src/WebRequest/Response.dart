/// Error type of HTTP request
enum ErrorType {
  /// Failed to communicate with the server. For example, the request couldn't connect
  /// or it could not establish a secure channel.
  connectionError,
  
  /// The server returned an error response. The request succeeded in communicating
  /// with the server, but received an error as defined by the connection protocol.
  protocolError,
  
  /// Error processing data. The request succeeded in communicating with the server,
  /// but encountered an error when processing the received data. For example, the
  /// data was corrupted or not in the correct format.
  dataProcessingError,
  
  /// No Error
  noError,
}

/// Class to encapsulate response data from a web request
class Response {
  /// The HTTP status code of the response
  final int statusCode;

  /// The body of the response as a string
  final String data;

  /// Any error message associated with the request, or null if successful
  final List<String>? errors;

  /// The type of error that occurred
  final ErrorType errorType;

  /// Error message for display
  String? get errorMessage {
    if (errors != null && errors!.isNotEmpty) {
      return errors!.join(', ');
    }
    return null;
  }

  Response({
    required this.statusCode,
    required this.data,
    this.errors,
    this.errorType = ErrorType.noError,
  });

  /// Indicates whether the request was successful based on the status code and error
  bool get isSuccess => 
      (errors == null || errors!.isEmpty) &&
      statusCode >= 200 && 
      statusCode < 300 &&
      errorType == ErrorType.noError;

  /// Create a successful response
  factory Response.success(String data, {int statusCode = 200}) {
    return Response(
      statusCode: statusCode,
      data: data,
      errorType: ErrorType.noError,
    );
  }

  /// Create an error response
  factory Response.error(
    String errorMessage, {
    int statusCode = 500,
    ErrorType errorType = ErrorType.connectionError,
  }) {
    return Response(
      statusCode: statusCode,
      data: '',
      errors: [errorMessage],
      errorType: errorType,
    );
  }

  @override
  String toString() {
    return 'Response(statusCode: $statusCode, isSuccess: $isSuccess, errorType: $errorType, errors: $errors)';
  }
}