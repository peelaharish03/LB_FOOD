
// global_exception_handler.dart

import 'package:dio/dio.dart';

/// Base class for all app-specific exceptions
abstract class AppException implements Exception {
  final String message;
  final int? code;
  AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException ($code): $message';
}

// === Specific Exceptions ===
class UserNotFoundException extends AppException {
  UserNotFoundException(super.message, int super.code);
}

class UnauthorizedException extends AppException {
  UnauthorizedException(super.message, int super.code);
}

class ForbiddenException extends AppException {
  ForbiddenException(super.message, int super.code);
}

class BadRequestException extends AppException {
  BadRequestException(super.message, int super.code);
}

class ConflictException extends AppException {
  ConflictException(super.message, int super.code);
}

class NotFoundException extends AppException {
  NotFoundException(super.message, int super.code);
}

class InternalServerErrorException extends AppException {
  InternalServerErrorException(super.message, int super.code);
}

class NetworkException extends AppException {
  NetworkException([
    String message = "No internet connection. Please check your network and try again.",
  ]) : super(message, null);
}

class RequestTimeoutException extends AppException {
  RequestTimeoutException([
    String message = "The request timed out. Please try again.",
  ]) : super(message, null);
}

class UnknownBackendException extends AppException {
  UnknownBackendException(super.message, [super.code]);
}

// === Error Mapper Function (backend-specific business error codes) ===
AppException mapErrorCodeToException(int code, String message) {
  switch (code) {
    case 1000:
      return UserNotFoundException("User not found", code);
    case 1001:
      return ConflictException("User already exists", code);
    case 1002:
      return ConflictException("Email is already in use", code);
    case 1003:
    case 1200:
      return UnauthorizedException("Your session has expired. Please log in again.", code);
    case 1004:
      return ForbiddenException("Not a valid restaurant admin", code);
    case 1100:
    case 3001:
      return NotFoundException("Requested city/category not found", code);
    case 1101:
    case 1802:
    case 2000:
    case 3009:
    case 4003:
      return BadRequestException(message, code);
    case 1104:
    case 4102:
    case 3003:
    case 5003:
      return ConflictException(message, code);
    case 1203:
      return UnauthorizedException("Your session has expired. Please log in again.", code);
    case 1204:
      return ForbiddenException("Access denied. Please try again later.", code);
    case 1800:
      return NotFoundException("We couldn't find an OTP for this number. Please request a new one.", code);
    case 1801:
      return BadRequestException("This OTP has expired. Please request a new one.", code);
    case 1803:
      return BadRequestException("Invalid token or vote type", code);
    case 1805:
      return ForbiddenException("Unauthorized voting", code);
    case 1901:
    case 3005:
    case 4001:
    case 4002:
    case 4010:
      return NotFoundException(message, code);
    case 2001:
    case 5005:
      return InternalServerErrorException("Something went wrong on our end. Please try again after some time.", code);
    case 2002:
    case 4008:
    case 4009:
      return ForbiddenException(message, code);
    case 2003:
      return BadRequestException("Method not allowed", code);
    case 2004:
      return BadRequestException("Something went wrong. Please try again.", code);
    case 2005:
      return BadRequestException("Restaurant not found", code);
    case 2017:
      return ForbiddenException("Not enough coins for transaction", code);
    default:
      return UnknownBackendException(
        message.isNotEmpty ? message : "Something went wrong. Please try again after some time.",
        code,
      );
  }
}

// === HTTP status based fallback mapper ===
// Used when the backend response doesn't carry one of the app-specific
// business `code`s above (e.g. a plain 401/500 from a proxy/gateway).
AppException mapHttpStatusToException(int? statusCode, String message) {
  switch (statusCode) {
    case 400:
      return BadRequestException(
        message.isNotEmpty ? message : "Invalid request. Please check the details and try again.",
        statusCode!,
      );
    case 401:
      return UnauthorizedException("Your session has expired. Please log in again.", statusCode!);
    case 403:
      return ForbiddenException("You don't have permission to perform this action.", statusCode!);
    case 404:
      return NotFoundException(
        message.isNotEmpty ? message : "The requested information was not found.",
        statusCode!,
      );
    case 408:
      return RequestTimeoutException();
    case 409:
      return ConflictException(
        message.isNotEmpty ? message : "This action conflicts with existing data.",
        statusCode!,
      );
    case 422:
      return BadRequestException(
        message.isNotEmpty ? message : "Some of the information provided is invalid.",
        statusCode!,
      );
    case 429:
      return BadRequestException("Too many attempts. Please wait a moment and try again.", statusCode!);
    case 500:
    case 502:
    case 503:
    case 504:
      return InternalServerErrorException(
        "Something went wrong on our end. Please try again after some time.",
        statusCode!,
      );
    default:
      return UnknownBackendException(
        message.isNotEmpty ? message : "Something went wrong. Please try again after some time.",
        statusCode,
      );
  }
}

// === Handle Dio Error and Map to AppException ===
AppException handleDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return RequestTimeoutException();
    case DioExceptionType.connectionError:
      return NetworkException();
    case DioExceptionType.badCertificate:
      return NetworkException("Secure connection failed. Please try again.");
    case DioExceptionType.cancel:
      return UnknownBackendException("Request was cancelled.");
    case DioExceptionType.badResponse:
    case DioExceptionType.unknown:
      break;
  }

  final response = e.response;
  if (response == null) {
    // No response at all (e.g. socket/connection failure not caught above).
    return NetworkException();
  }

  final data = response.data;
  if (data is Map) {
    final rawCode = data['code'];
    final message = (data['message'] ?? '').toString();
    if (rawCode is int) {
      return mapErrorCodeToException(rawCode, message.isNotEmpty ? message : "Unexpected error occurred");
    }
    return mapHttpStatusToException(response.statusCode, message);
  }

  return mapHttpStatusToException(response.statusCode, data is String ? data : '');
}

/// Converts any caught error into a clean, user-facing message.
/// Use this as the single point of truth in cubits' catch blocks so
/// raw exception text (DioException dumps, stack traces, etc.) never
/// reaches the UI.
String friendlyErrorMessage(
  Object error, {
  String fallback = "Something went wrong. Please try again after some time.",
}) {
  if (error is AppException) return error.message;
  if (error is DioException) return handleDioError(error).message;
  return fallback;
}
