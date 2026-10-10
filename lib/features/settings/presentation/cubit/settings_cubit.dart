import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hamyon/features/settings/presentation/cubit/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void darkModeChanged(bool enabled) => emit(state.copyWith(
        themeMode: enabled ? ThemeMode.dark : ThemeMode.light,
      ));
}
