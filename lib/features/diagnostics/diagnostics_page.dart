import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../navigation/navigation_cubit.dart';
import '../../navigation/app_section.dart';
import '../../ui/components/app_button.dart';
import '../../ui/components/app_card.dart';
import '../../ui/components/app_toast.dart';
import '../../ui/tokens.dart';
import '../ffmpeg/ffmpeg_cubit.dart';
import 'diagnostics_cubit.dart';

class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiagnosticsCubit, DiagnosticsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(state: state),
            SizedBox(height: AppTokens.space.s16),
            _SessionCard(state: state),
            SizedBox(height: AppTokens.space.s12),
            _CookieCard(state: state),
            SizedBox(height: AppTokens.space.s12),
            _ToolsCard(state: state),
            SizedBox(height: AppTokens.space.s12),
            _FfmpegCard(state: state),
            SizedBox(height: AppTokens.space.s12),
            _TemplateCard(state: state),
            if (state.hints.isNotEmpty) ...[
              SizedBox(height: AppTokens.space.s12),
              _HintsCard(state: state),
            ],
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final DiagnosticsState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final updated = state.lastUpdated == null
        ? 'Not checked yet'
        : 'Updated ${state.lastUpdated!.toLocal()}';
    return Row(
      children: [
        Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health & diagnostics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: AppTokens.space.s6),
                Text(
                  updated,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                if (state.errorMessage != null) ...[
                  SizedBox(height: AppTokens.space.s6),
                  Text(
                    state.errorMessage!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.destructive),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(width: AppTokens.space.s12),
        AppButton(
          label: state.isLoading ? 'Checking...' : 'Refresh checks',
          onPressed: state.isLoading
              ? null
              : () => context.read<DiagnosticsCubit>().refresh(),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.state});

  final DiagnosticsState state;

  @override
  Widget build(BuildContext context) {
    final session = state.session;
    final label = session.isValid ? 'Session active' : 'Session needs login';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Session',
            level: session.level,
            subtitle: session.message,
          ),
          SizedBox(height: AppTokens.space.s8),
          Text(
            session.username == null ? label : '$label • u/${session.username}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: AppTokens.space.s12),
          Row(
            children: [
              AppButton(
                label: 'Open Sync',
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    context.read<NavigationCubit>().select(AppSection.sync),
              ),
              SizedBox(width: AppTokens.space.s8),
              AppButton(
                label: 'Recheck',
                variant: AppButtonVariant.ghost,
                onPressed: () => context.read<DiagnosticsCubit>().refresh(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CookieCard extends StatelessWidget {
  const _CookieCard({required this.state});

  final DiagnosticsState state;

  @override
  Widget build(BuildContext context) {
    final cookies = state.cookies;
    final isPersisted = cookies.persistence == CookiePersistence.persisted;
    final subtitle = isPersisted ? 'Remember-me enabled' : 'Ephemeral session';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Cookie storage',
            level: isPersisted && !cookies.storeExists
                ? DiagnosticsLevel.warn
                : DiagnosticsLevel.ok,
            subtitle: subtitle,
          ),
          SizedBox(height: AppTokens.space.s8),
          Text(
            cookies.storagePath.isEmpty
                ? 'Storage path not available.'
                : cookies.storagePath,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(height: AppTokens.space.s12),
          AppButton(
            label: 'Open Settings',
            variant: AppButtonVariant.secondary,
            onPressed: () =>
                context.read<NavigationCubit>().select(AppSection.settings),
          ),
        ],
      ),
    );
  }
}

class _ToolsCard extends StatelessWidget {
  const _ToolsCard({required this.state});

  final DiagnosticsState state;

  @override
  Widget build(BuildContext context) {
    final tools = state.tools;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'External tools',
            level: DiagnosticsLevel.ok,
            subtitle: 'gallery-dl and yt-dlp',
          ),
          SizedBox(height: AppTokens.space.s8),
          if (tools.isEmpty)
            Text(
              'No tool checks yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Column(
              children: tools
                  .map(
                    (tool) => Padding(
                      padding: EdgeInsets.only(bottom: AppTokens.space.s8),
                      child: _ToolRow(tool: tool),
                    ),
                  )
                  .toList(),
            ),
          SizedBox(height: AppTokens.space.s8),
          Row(
            children: [
              AppButton(
                label: 'Open Settings',
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    context.read<NavigationCubit>().select(AppSection.settings),
              ),
              SizedBox(width: AppTokens.space.s8),
              AppButton(
                label: 'Recheck',
                variant: AppButtonVariant.ghost,
                onPressed: () => context.read<DiagnosticsCubit>().refresh(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FfmpegCard extends StatelessWidget {
  const _FfmpegCard({required this.state});

  final DiagnosticsState state;

  @override
  Widget build(BuildContext context) {
    final ffmpeg = state.ffmpeg;
    return BlocBuilder<FfmpegCubit, FfmpegState>(
      builder: (context, ffmpegState) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(
                title: 'ffmpeg runtime',
                level: ffmpeg.level,
                subtitle: ffmpeg.isInstalled
                    ? 'Installed'
                    : 'Not installed yet',
              ),
              SizedBox(height: AppTokens.space.s8),
              Text(
                ffmpeg.ffmpegPath ?? 'ffmpeg path not available.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (ffmpeg.version != null) ...[
                SizedBox(height: AppTokens.space.s6),
                Text(
                  ffmpeg.version!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              SizedBox(height: AppTokens.space.s12),
              Row(
                children: [
                  AppButton(
                    label: ffmpegState.isInstalling
                        ? 'Installing...'
                        : 'Install runtime',
                    variant: AppButtonVariant.secondary,
                    onPressed: ffmpegState.isInstalling
                        ? null
                        : () async {
                            await context.read<FfmpegCubit>().install();
                            if (!context.mounted) {
                              return;
                            }
                            AppToast.show(
                              context,
                              'ffmpeg runtime install requested.',
                            );
                            context.read<DiagnosticsCubit>().refresh();
                          },
                  ),
                  SizedBox(width: AppTokens.space.s8),
                  AppButton(
                    label: 'Recheck',
                    variant: AppButtonVariant.ghost,
                    onPressed: () => context.read<DiagnosticsCubit>().refresh(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.state});

  final DiagnosticsState state;

  @override
  Widget build(BuildContext context) {
    final templates = state.templates;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'Download path templates',
            level: templates.level,
            subtitle: templates.message,
          ),
          SizedBox(height: AppTokens.space.s8),
          Text(
            templates.rootPath.isEmpty
                ? 'Download root not set.'
                : templates.rootPath,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (templates.previewPath != null) ...[
            SizedBox(height: AppTokens.space.s6),
            Text(
              templates.previewPath!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (templates.warnings.isNotEmpty) ...[
            SizedBox(height: AppTokens.space.s8),
            ...templates.warnings.map(
              (warning) => Text(
                '• $warning',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          SizedBox(height: AppTokens.space.s12),
          AppButton(
            label: 'Open Settings',
            variant: AppButtonVariant.secondary,
            onPressed: () =>
                context.read<NavigationCubit>().select(AppSection.settings),
          ),
        ],
      ),
    );
  }
}

class _HintsCard extends StatelessWidget {
  const _HintsCard({required this.state});

  final DiagnosticsState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeader(
            title: 'Platform notes',
            level: DiagnosticsLevel.ok,
            subtitle: 'Helpful hints for your OS',
          ),
          SizedBox(height: AppTokens.space.s8),
          ...state.hints.map(
            (hint) => Padding(
              padding: EdgeInsets.only(bottom: AppTokens.space.s6),
              child: Text(
                '${hint.title}: ${hint.message}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.tool});

  final ToolDiagnostics tool;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusDot(level: tool.level),
        SizedBox(width: AppTokens.space.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tool.name, style: Theme.of(context).textTheme.bodyMedium),
              Text(tool.summary, style: Theme.of(context).textTheme.bodySmall),
              if (tool.path != null) ...[
                Text(tool.path!, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (tool.version != null) ...[
                Text(
                  tool.version!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    required this.level,
    required this.subtitle,
  });

  final String title;
  final DiagnosticsLevel level;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final levelColor = _levelColor(colors, level);
    return Row(
      children: [
        _StatusDot(level: level),
        SizedBox(width: AppTokens.space.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: levelColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _levelColor(AppColorScheme colors, DiagnosticsLevel level) {
    switch (level) {
      case DiagnosticsLevel.ok:
        return colors.primary;
      case DiagnosticsLevel.warn:
        return colors.accent;
      case DiagnosticsLevel.error:
        return colors.destructive;
    }
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.level});

  final DiagnosticsLevel level;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Color color;
    switch (level) {
      case DiagnosticsLevel.ok:
        color = colors.primary;
      case DiagnosticsLevel.warn:
        color = colors.accent;
      case DiagnosticsLevel.error:
        color = colors.destructive;
    }
    return Container(
      width: AppTokens.space.s8,
      height: AppTokens.space.s8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
