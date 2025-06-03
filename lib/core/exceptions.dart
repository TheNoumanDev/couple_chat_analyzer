// core/exceptions.dart
// Consolidated: app_exceptions.dart

// Base Exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic data;

  AppException(this.message, {this.code, this.data});

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

// File related exceptions
class FileException extends AppException {
  FileException(String message, {String? code, dynamic data})
      : super(message, code: code, data: data);
}

class UnsupportedFileFormatException extends FileException {
  UnsupportedFileFormatException({String? filePath})
      : super('Unsupported file format', 
            code: 'unsupported_format', 
            data: {'filePath': filePath});
}

class FileReadException extends FileException {
  FileReadException({String? filePath, dynamic error})
      : super('Could not read file', 
            code: 'file_read_error', 
            data: {'filePath': filePath, 'error': error});
}

// Parsing related exceptions
class ParsingException extends AppException {
  ParsingException(String message, {String? code, dynamic data})
      : super(message, code: code, data: data);
}

class InvalidChatFormatException extends ParsingException {
  InvalidChatFormatException()
      : super('The file does not contain a valid WhatsApp chat', 
            code: 'invalid_chat_format');
}

// Analysis related exceptions
class AnalysisException extends AppException {
  AnalysisException(String message, {String? code, dynamic data})
      : super(message, code: code, data: data);
}

// Report related exceptions
class ReportException extends AppException {
  ReportException(String message, {String? code, dynamic data})
      : super(message, code: code, data: data);
}

// Storage related exceptions
class StorageException extends AppException {
  StorageException(String message, {String? code, dynamic data})
      : super(message, code: code, data: data);
}

// Network related exceptions
class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic data})
      : super(message, code: code, data: data);
}