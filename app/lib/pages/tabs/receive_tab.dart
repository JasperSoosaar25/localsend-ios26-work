import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/state/server/server_state.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/home_page_controller.dart';
import 'package:localsend_app/pages/receive_history_page.dart';
import 'package:localsend_app/pages/web_share_page.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/widget/animations/initial_fade_transition.dart';
import 'package:localsend_app/widget/column_list_view.dart';
import 'package:localsend_app/widget/custom_icon_button.dart';
import 'package:localsend_app/widget/ios/ios26_native_controls.dart';
import 'package:localsend_app/widget/local_send_logo.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:localsend_app/widget/rotating_widget.dart';
import 'package:localsend_isolates/util/sleep.dart';
import 'package:refena_flutter/addons.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class ReceiveTab extends StatefulWidget {
  const ReceiveTab();

  @override
  State<ReceiveTab> createState() => _ReceiveTabState();
}

class _ReceiveTabState extends State<ReceiveTab> {
  /// Whether the advanced network info is shown
  bool _showAdvanced = false;

  /// Whether the history button is shown
  /// This extra boolean is needed to delay the animation
  bool _showHistoryButton = true;

  Future<void> _toggleAdvanced() async {
    if (_showAdvanced) {
      setState(() => _showAdvanced = false);
      await sleepAsync(200);
      if (mounted) {
        setState(() => _showHistoryButton = true);
      }
    } else {
      setState(() {
        _showAdvanced = true;
        _showHistoryButton = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final alias = context.watch(settingsProvider.select((s) => s.alias));
    final serverState = context.watch(serverProvider);
    final localIps = context.watch(localIpProvider.select((s) => s.localIps));

    if (supportsNativeIOS26Controls) {
      return _buildIOS26(
        context,
        alias: alias,
        serverState: serverState,
        localIps: localIps,
      );
    }

    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ResponsiveListView.defaultMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: ColumnListView(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InitialFadeTransition(
                          duration: const Duration(milliseconds: 300),
                          delay: const Duration(milliseconds: 200),
                          child: Consumer(
                            builder: (context, ref) {
                              final animations = ref.watch(animationProvider);
                              final activeTab = ref.watch(
                                homePageControllerProvider.select(
                                  (state) => state.currentTab,
                                ),
                              );
                              return RotatingWidget(
                                duration: const Duration(seconds: 15),
                                spinning: serverState != null && animations && activeTab == HomeTab.receive,
                                child: const LocalSendLogo(withText: false),
                              );
                            },
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            serverState?.alias ?? alias,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                        InitialFadeTransition(
                          duration: const Duration(milliseconds: 300),
                          delay: const Duration(milliseconds: 500),
                          child: Text(
                            serverState == null ? t.general.offline : t.general.online,
                            style: const TextStyle(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await context.global.dispatchAsync(
                            NavigateAction.push(const WebSharePage()),
                          );
                        },
                        icon: Icon(Icons.language),
                        label: Text(t.receiveTab.link),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
        _InfoBox(
          serverState: serverState,
          localIps: localIps,
          showAdvanced: _showAdvanced,
        ),
        _CornerButtons(
          showAdvanced: _showAdvanced,
          showHistoryButton: _showHistoryButton,
          toggleAdvanced: _toggleAdvanced,
        ),
      ],
    );
  }

  Widget _buildIOS26(
    BuildContext context, {
    required String alias,
    required ServerState? serverState,
    required List<String> localIps,
  }) {
    final online = serverState != null;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          IOS26LargeTitle(
            title: t.receiveTab.title,
            actions: [
              SizedBox(
                width: 48,
                height: 48,
                child: IOS26NativeButton(
                  symbol: 'clock.arrow.circlepath',
                  accessibilityLabel: t.receiveHistoryPage.title,
                  onPressed: () async {
                    await context.push(() => const ReceiveHistoryPage());
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: IOS26NativeButton(
                  symbol: _showAdvanced ? 'info.circle.fill' : 'info.circle',
                  accessibilityLabel: t.receiveHistoryPage.entryActions.info,
                  onPressed: _toggleAdvanced,
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _showAdvanced
                ? Card(
                    key: const ValueKey('ios-network-info'),
                    margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          _IOSInfoRow(
                            label: t.receiveTab.infoBox.alias,
                            value: serverState?.alias ?? '-',
                          ),
                          const Divider(),
                          _IOSInfoRow(
                            label: t.receiveTab.infoBox.ip,
                            value: localIps.isEmpty ? t.general.unknown : localIps.join('\n'),
                          ),
                          const Divider(),
                          _IOSInfoRow(
                            label: t.receiveTab.infoBox.port,
                            value: serverState?.port.toString() ?? '-',
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('ios-network-info-hidden')),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InitialFadeTransition(
                      duration: const Duration(milliseconds: 350),
                      delay: const Duration(milliseconds: 100),
                      child: Consumer(
                        builder: (context, ref) {
                          final animations = ref.watch(animationProvider);
                          final activeTab = ref.watch(
                            homePageControllerProvider.select(
                              (state) => state.currentTab,
                            ),
                          );
                          return RotatingWidget(
                            duration: const Duration(seconds: 15),
                            spinning: online && animations && activeTab == HomeTab.receive,
                            child: const SizedBox(
                              width: 132,
                              height: 132,
                              child: LocalSendLogo(withText: false),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      serverState?.alias ?? alias,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: online ? t.general.online : t.general.offline,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: online ? const Color(0xFF34C759) : Theme.of(context).colorScheme.outline,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                online ? t.general.online : t.general.offline,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 94),
            child: SizedBox(
              width: 230,
              height: 54,
              child: IOS26NativeButton(
                title: t.receiveTab.link,
                symbol: 'network',
                accessibilityLabel: t.receiveTab.link,
                prominent: true,
                onPressed: () async {
                  await context.global.dispatchAsync(
                    NavigateAction.push(const WebSharePage()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IOSInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _IOSInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          const SizedBox(width: 16),
          Flexible(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerButtons extends StatelessWidget {
  final bool showAdvanced;
  final bool showHistoryButton;
  final Future<void> Function() toggleAdvanced;

  const _CornerButtons({
    required this.showAdvanced,
    required this.showHistoryButton,
    required this.toggleAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!showAdvanced)
              AnimatedOpacity(
                opacity: showHistoryButton ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: CustomIconButton(
                  onPressed: () async {
                    await context.push(() => const ReceiveHistoryPage());
                  },
                  child: const Icon(Icons.history),
                ),
              ),
            CustomIconButton(
              key: const ValueKey('info-btn'),
              onPressed: toggleAdvanced,
              child: const Icon(Icons.info),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final ServerState? serverState;
  final List<String> localIps;
  final bool showAdvanced;

  const _InfoBox({
    required this.serverState,
    required this.localIps,
    required this.showAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      crossFadeState: showAdvanced ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
      firstChild: Container(),
      secondChild: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Table(
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: IntrinsicColumnWidth(),
                  2: IntrinsicColumnWidth(),
                },
                children: [
                  TableRow(
                    children: [
                      Text(t.receiveTab.infoBox.alias),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 30),
                        child: SelectableText(serverState?.alias ?? '-'),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Text(t.receiveTab.infoBox.ip),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (localIps.isEmpty) Text(t.general.unknown),
                          ...localIps.map((ip) => SelectableText(ip)),
                        ],
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      Text(t.receiveTab.infoBox.port),
                      const SizedBox(width: 10),
                      SelectableText(serverState?.port.toString() ?? '-'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
