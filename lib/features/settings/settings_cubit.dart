import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/settings_repository.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository)
      : super(SettingsState(settings: AppSettings.defaults(), isLoading: true)) {
    _load();
  }

  final SettingsRepository _repository;

  Future<void> _load() async {
    final settings = await _repository.load();
    emit(SettingsState(settings: settings, isLoading: false));
  }

  Future<void> updateSettings(AppSettings settings) async {
    emit(state.copyWith(settings: settings));
    await _repository.save(settings);
  }

  void updateDownloadRoot(String value) {
    updateSettings(state.settings.copyWith(downloadRoot: value));
  }

  void updateOverwritePolicy(OverwritePolicy policy) {
    updateSettings(state.settings.copyWith(overwritePolicy: policy));
  }

  void updateDownloadNsfw(bool value) {
    updateSettings(state.settings.copyWith(downloadNsfw: value));
  }

  void updateRememberSession(bool value) {
    updateSettings(state.settings.copyWith(rememberSession: value));
  }

  void updateThemeMode(AppThemeMode mode) {
    updateSettings(state.settings.copyWith(themeMode: mode));
  }
}

class SettingsState extends Equatable {
  const SettingsState({
    required this.settings,
    required this.isLoading,
  });

  final AppSettings settings;
  final bool isLoading;

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [settings, isLoading];
}
