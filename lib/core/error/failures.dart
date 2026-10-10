sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'PIN-kod noto‘g‘ri']);
}

final class BlockedFailure extends Failure {
  const BlockedFailure(this.until)
      : super('Juda ko‘p xato urinish. Biroz kuting.');

  final DateTime until;
}

final class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure(
      [super.message = 'Kartada mablag‘ yetarli emas']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

final class IntegrityFailure extends Failure {
  const IntegrityFailure(
      [super.message = 'Ma’lumot yaxlitligi buzilgan. Fayl o‘zgartirilgan.']);
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message);
}
