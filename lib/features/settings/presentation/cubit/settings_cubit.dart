import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/features/settings/presentation/cubit/settings_state.dart';
import 'package:hamyon/features/settings/domain/usecases/settings_usecases.dart';
import 'package:hamyon/features/settings/domain/repositories/settings_repository.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required GetThemeMode getThemeMode,
    required SaveThemeMode saveThemeMode,
  }) : _getThemeMode = getThemeMode,
       _saveThemeMode = saveThemeMode,
       super(const SettingsState());

  final GetThemeMode _getThemeMode;
  final SaveThemeMode _saveThemeMode;

  Future<void> load() async {
    emit(state.copyWith(status: SettingsStatus.loading, clearMessage: true));
    try {
      emit(
        state.copyWith(
          themeMode: _toFlutterThemeMode(await _getThemeMode()),
          status: SettingsStatus.ready,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          message: 'Tema sozlamasini o‘qib bo‘lmadi',
        ),
      );
    }
  }

  Future<void> darkModeChanged(bool enabled) async {
    final previous = state.themeMode;
    final themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    emit(state.copyWith(themeMode: themeMode, clearMessage: true));
    try {
      await _saveThemeMode(_toWalletThemeMode(themeMode));
      emit(state.copyWith(status: SettingsStatus.ready));
    } catch (_) {
      emit(
        state.copyWith(
          themeMode: previous,
          status: SettingsStatus.failure,
          message: 'Tema sozlamasini saqlab bo‘lmadi',
        ),
      );
    }
  }

  ThemeMode _toFlutterThemeMode(WalletThemeMode mode) => switch (mode) {
    WalletThemeMode.system => ThemeMode.system,
    WalletThemeMode.light => ThemeMode.light,
    WalletThemeMode.dark => ThemeMode.dark,
  };

  WalletThemeMode _toWalletThemeMode(ThemeMode mode) => switch (mode) {
    ThemeMode.system => WalletThemeMode.system,
    ThemeMode.light => WalletThemeMode.light,
    ThemeMode.dark => WalletThemeMode.dark,
  };
}
