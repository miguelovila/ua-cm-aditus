import '../../data/repositories/account_repository.dart';

class LogoutUseCase {
  final AccountRepository _repository;

  LogoutUseCase(this._repository);

  Future<void> call() async {
    await _repository.logout();
  }
}
