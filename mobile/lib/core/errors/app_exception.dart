sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = '연결에 실패했습니다. 다시 시도해주세요.']);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = '로그인이 필요합니다.']);
}

class AuthException extends AppException {
  const AuthException([super.message = '이메일 또는 비밀번호를 확인해주세요.']);
}

class ValidationException extends AppException {
  const ValidationException([super.message = '입력을 확인해주세요.']);
}

class ConflictException extends AppException {
  const ConflictException([super.message = '이미 사용 중인 이메일입니다.']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = '리소스를 찾을 수 없습니다.']);
}

class ServerException extends AppException {
  const ServerException([super.message = '서버 오류가 발생했습니다.']);
}
