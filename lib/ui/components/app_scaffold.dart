import 'package:flutter/material.dart';

import '../../app_version.dart';
import '../../navigation/app_section.dart';
import '../tokens.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.section,
    required this.onSectionSelected,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final AppSection section;
  final ValueChanged<AppSection> onSectionSelected;
  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: AppTokens.layout.navWidth,
            decoration: BoxDecoration(
              color: colors.sidebar,
              border: Border(right: BorderSide(color: colors.sidebarBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(AppTokens.space.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'reddit-dl',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: AppTokens.fontWeights.medium,
                        ),
                      ),
                      SizedBox(height: AppTokens.space.s4),
                      Text(
                        'Archive your saved posts.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppTokens.space.s8),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTokens.space.s8,
                    ),
                    children: AppSection.values
                        .map(
                          (item) => _NavItem(
                            section: item,
                            selected: item == section,
                            onTap: () => onSectionSelected(item),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(AppTokens.space.s12),
                  child: Text(
                    appVersionLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: AppTokens.layout.titleBarHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTokens.space.s16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: colors.border)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      if (actions.isNotEmpty)
                        Row(
                          children: actions
                              .map(
                                (action) => Padding(
                                  padding: EdgeInsets.only(
                                    left: AppTokens.space.s8,
                                  ),
                                  child: action,
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(AppTokens.space.s20),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: AppTokens.layout.contentMaxWidth,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final AppSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final background = selected ? colors.sidebarAccent : Colors.transparent;
    final foreground = selected
        ? colors.sidebarAccentForeground
        : colors.sidebarForeground;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTokens.space.s4),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTokens.space.s12,
              vertical: AppTokens.space.s8,
            ),
            child: Row(
              children: [
                Icon(section.icon, color: foreground),
                SizedBox(width: AppTokens.space.s8),
                Expanded(
                  child: Text(
                    section.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
