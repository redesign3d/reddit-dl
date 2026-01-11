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

  void updateMediaPathTemplate(String value) {
    updateSettings(state.settings.copyWith(mediaPathTemplate: value));
  }

  void updateMediaLayoutMode(MediaLayoutMode mode) {
    updateSettings(state.settings.copyWith(mediaLayoutMode: mode));
  }

  void updateTextRoot(String value) {
    updateSettings(state.settings.copyWith(textRoot: value));
  }

  void updateCommentsRoot(String value) {
    updateSettings(state.settings.copyWith(commentsRoot: value));
  }

  void updateOverwritePolicy(OverwritePolicy policy) {
    updateSettings(state.settings.copyWith(overwritePolicy: policy));
  }

  void updateConcurrency(int value) {
    updateSettings(state.settings.copyWith(concurrency: value));
  }

  void updateRateLimit(int value) {
    updateSettings(state.settings.copyWith(rateLimitPerMinute: value));
  }

  void updateMaxDownloadAttempts(int value) {
    updateSettings(state.settings.copyWith(maxDownloadAttempts: value));
  }

  void updateDownloadNsfw(bool value) {
    updateSettings(state.settings.copyWith(downloadNsfw: value));
  }

  void updateGalleryDlPathOverride(String value) {
    updateSettings(state.settings.copyWith(galleryDlPathOverride: value));
  }

  void updateYtDlpPathOverride(String value) {
    updateSettings(state.settings.copyWith(ytDlpPathOverride: value));
  }

  void updateRememberSession(bool value) {
    updateSettings(state.settings.copyWith(rememberSession: value));
  }

  void updateExportTextPosts(bool value) {
    updateSettings(state.settings.copyWith(exportTextPosts: value));
  }

  void updateExportSavedComments(bool value) {
    updateSettings(state.settings.copyWith(exportSavedComments: value));
  }

  void updateExportPostComments(bool value) {
    updateSettings(state.settings.copyWith(exportPostComments: value));
  }

  void updatePostCommentsMaxCount(int? value) {
    updateSettings(state.settings.copyWith(postCommentsMaxCount: value));
  }

  void updatePostCommentsSort(CommentSort value) {
    updateSettings(state.settings.copyWith(postCommentsSort: value));
  }

  void updatePostCommentsTimeframeDays(int? value) {
    updateSettings(state.settings.copyWith(postCommentsTimeframeDays: value));
  }

  void updateThemeMode(AppThemeMode mode) {
    updateSettings(state.settings.copyWith(themeMode: mode));
  }
}

class SettingsState extends Equatable {
  const SettingsState({required this.settings, required this.isLoading});

  final AppSettings settings;
  final bool isLoading;

  SettingsState copyWith({AppSettings? settings, bool? isLoading}) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [settings, isLoading];
}
