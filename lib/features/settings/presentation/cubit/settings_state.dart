import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum SettingsStatus { initial, loading, ready, failure }

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.status = SettingsStatus.initial,
    this.message,
  });

  final ThemeMode themeMode;
  final SettingsStatus status;
  final String? message;

  SettingsState copyWith({
    ThemeMode? themeMode,
    SettingsStatus? status,
    String? message,
    bool clearMessage = false,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    status: status ?? this.status,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [themeMode, status, message];
}
