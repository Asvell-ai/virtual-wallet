import 'package:hamyon/features/auth/domain/repositories/auth_repository.dart';

class CreatePin {
  const CreatePin(this._repository);
  final AuthRepository _repository;
  Future<void> call(String pin) => _repository.createPin(pin);
}

class UnlockWallet {
  const UnlockWallet(this._repository);
  final AuthRepository _repository;
  Future<void> call(String pin) => _repository.unlock(pin);
}

class VerifyPin {
  const VerifyPin(this._repository);
  final AuthRepository _repository;
  Future<void> call(String pin) => _repository.verifyPin(pin);
}
