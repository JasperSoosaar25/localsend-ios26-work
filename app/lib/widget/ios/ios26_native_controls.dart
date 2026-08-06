import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool get supportsNativeIOS26Controls =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

class IOS26TabItem {
  final String label;
  final String symbol;
  final String selectedSymbol;

  const IOS26TabItem({
    required this.label,
    required this.symbol,
    required this.selectedSymbol,
  });

  Map<String, Object> toMap() => {
    'label': label,
    'symbol': symbol,
    'selectedSymbol': selectedSymbol,
  };
}

/// A native [UITabBar]. When built with the iOS 26 SDK this is Apple's real
/// Liquid Glass tab bar, including SF Symbols, material, motion, and accessibility.
class IOS26NativeTabBar extends StatefulWidget {
  final List<IOS26TabItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const IOS26NativeTabBar({
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  @override
  State<IOS26NativeTabBar> createState() => _IOS26NativeTabBarState();
}

class _IOS26NativeTabBarState extends State<IOS26NativeTabBar> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(IOS26NativeTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final channel = _channel;
      if (channel != null) {
        unawaited(channel.invokeMethod<void>('setIndex', widget.currentIndex));
      }
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsNativeIOS26Controls) {
      return NavigationBar(
        selectedIndex: widget.currentIndex,
        onDestinationSelected: widget.onSelected,
        destinations: widget.items
            .map(
              (item) => NavigationDestination(
                icon: const SizedBox.shrink(),
                label: item.label,
              ),
            )
            .toList(growable: false),
      );
    }

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return SizedBox(
      height: 58 + bottomInset,
      child: UiKitView(
        viewType: 'localsend/ios26-tab-bar',
        creationParams: {
          'selectedIndex': widget.currentIndex,
          'items': widget.items
              .map((item) => item.toMap())
              .toList(growable: false),
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          final channel = MethodChannel('localsend/ios26-tab-bar/$id');
          _channel = channel;
          channel.setMethodCallHandler((call) async {
            if (call.method == 'selected') {
              widget.onSelected(call.arguments as int);
            }
          });
        },
      ),
    );
  }
}

/// A native [UIButton]. iOS 26 supplies the glass material and interaction;
/// older releases receive the closest system button configuration.
class IOS26NativeButton extends StatefulWidget {
  final String? title;
  final String symbol;
  final String accessibilityLabel;
  final VoidCallback? onPressed;
  final bool prominent;
  final bool destructive;

  const IOS26NativeButton({
    required this.symbol,
    required this.accessibilityLabel,
    required this.onPressed,
    this.title,
    this.prominent = false,
    this.destructive = false,
    super.key,
  });

  @override
  State<IOS26NativeButton> createState() => _IOS26NativeButtonState();
}

class _IOS26NativeButtonState extends State<IOS26NativeButton> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(IOS26NativeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.onPressed == null) != (widget.onPressed == null)) {
      final channel = _channel;
      if (channel != null) {
        unawaited(
          channel.invokeMethod<void>('setEnabled', widget.onPressed != null),
        );
      }
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsNativeIOS26Controls) {
      return FilledButton.icon(
        onPressed: widget.onPressed,
        icon: const SizedBox.shrink(),
        label: Text(widget.title ?? widget.accessibilityLabel),
      );
    }

    return UiKitView(
      viewType: 'localsend/ios26-button',
      creationParams: {
        if (widget.title != null) 'title': widget.title!,
        'symbol': widget.symbol,
        'accessibilityLabel': widget.accessibilityLabel,
        'prominent': widget.prominent,
        'destructive': widget.destructive,
        'enabled': widget.onPressed != null,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (id) {
        final channel = MethodChannel('localsend/ios26-button/$id');
        _channel = channel;
        channel.setMethodCallHandler((call) async {
          if (call.method == 'pressed') {
            widget.onPressed?.call();
          }
        });
      },
    );
  }
}

/// A native [UISwitch], so Settings uses the exact platform control rather
/// than a painted approximation.
class IOS26NativeSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String accessibilityLabel;

  const IOS26NativeSwitch({
    required this.value,
    required this.onChanged,
    required this.accessibilityLabel,
    super.key,
  });

  @override
  State<IOS26NativeSwitch> createState() => _IOS26NativeSwitchState();
}

class _IOS26NativeSwitchState extends State<IOS26NativeSwitch> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(IOS26NativeSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final channel = _channel;
      if (channel != null) {
        unawaited(channel.invokeMethod<void>('setValue', widget.value));
      }
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsNativeIOS26Controls) {
      return Switch(value: widget.value, onChanged: widget.onChanged);
    }

    return SizedBox(
      width: 52,
      height: 34,
      child: UiKitView(
        viewType: 'localsend/ios26-switch',
        creationParams: {
          'value': widget.value,
          'accessibilityLabel': widget.accessibilityLabel,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (id) {
          final channel = MethodChannel('localsend/ios26-switch/$id');
          _channel = channel;
          channel.setMethodCallHandler((call) async {
            if (call.method == 'changed') {
              widget.onChanged(call.arguments as bool);
            }
          });
        },
      ),
    );
  }
}

class IOS26LargeTitle extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const IOS26LargeTitle({
    required this.title,
    this.actions = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 34,
                height: 1.15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          if (actions.isNotEmpty) ...[const SizedBox(width: 12), ...actions],
        ],
      ),
    );
  }
}
