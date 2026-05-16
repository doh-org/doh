sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = '네트워크 오류가 발생했습니다.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = '로그인이 필요합니다.']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = '리소스를 찾을 수 없습니다.']);
}

class ServerException extends AppException {
  const ServerException([super.message = '서버 오류가 발생했습니다.']);
}
