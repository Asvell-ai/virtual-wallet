import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCubit extends Cubit<int> {
  HomeCubit() : super(0);

  bool _hasPlayedBalanceAnimation = false;

  void pageChanged(int index) => emit(index);

  bool consumeBalanceAnimation() {
    if (_hasPlayedBalanceAnimation) return false;
    _hasPlayedBalanceAnimation = true;
    return true;
  }
}
