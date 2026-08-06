import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(name: "ios-delegate-channel", binaryMessenger: messenger)
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "isReduceMotionEnabled" {
          result(UIAccessibility.isReduceMotionEnabled)
        } else {
          result(FlutterMethodNotImplemented)
        }
    }
    engineBridge.applicationRegistrar.register(
      IOS26TabBarFactory(messenger: messenger),
      withId: "localsend/ios26-tab-bar"
    )
    engineBridge.applicationRegistrar.register(
      IOS26ButtonFactory(messenger: messenger),
      withId: "localsend/ios26-button"
    )
    engineBridge.applicationRegistrar.register(
      IOS26SwitchFactory(messenger: messenger),
      withId: "localsend/ios26-switch"
    )
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

private final class IOS26TabBarFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    IOS26TabBarPlatformView(frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

private final class IOS26TabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
  private let container: UIView
  private let tabBar: UITabBar
  private let channel: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, arguments args: Any?, messenger: FlutterBinaryMessenger) {
    container = UIView(frame: frame)
    tabBar = UITabBar(frame: frame)
    channel = FlutterMethodChannel(name: "localsend/ios26-tab-bar/\(viewId)", binaryMessenger: messenger)
    super.init()

    container.backgroundColor = .clear
    container.isOpaque = false
    tabBar.backgroundColor = .clear
    tabBar.isTranslucent = true
    tabBar.delegate = self
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(tabBar)
    NSLayoutConstraint.activate([
      tabBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      tabBar.topAnchor.constraint(equalTo: container.topAnchor),
      tabBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    let params = args as? [String: Any]
    let rawItems = params?["items"] as? [[String: Any]] ?? []
    tabBar.items = rawItems.enumerated().map { index, item in
      let title = item["label"] as? String
      let symbol = item["symbol"] as? String ?? "circle"
      let selectedSymbol = item["selectedSymbol"] as? String ?? symbol
      let tabItem = UITabBarItem(
        title: title,
        image: UIImage(systemName: symbol),
        selectedImage: UIImage(systemName: selectedSymbol)
      )
      tabItem.tag = index
      tabItem.accessibilityLabel = title
      return tabItem
    }
    let selectedIndex = params?["selectedIndex"] as? Int ?? 0
    select(index: selectedIndex)

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setIndex", let index = call.arguments as? Int else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.select(index: index)
      result(nil)
    }
  }

  func view() -> UIView {
    container
  }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    channel.invokeMethod("selected", arguments: item.tag)
  }

  private func select(index: Int) {
    guard let items = tabBar.items, items.indices.contains(index) else { return }
    tabBar.selectedItem = items[index]
  }
}

private final class IOS26ButtonFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    IOS26ButtonPlatformView(frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

private final class IOS26ButtonPlatformView: NSObject, FlutterPlatformView {
  private let container: UIView
  private let button: UIButton
  private let channel: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, arguments args: Any?, messenger: FlutterBinaryMessenger) {
    container = UIView(frame: frame)
    button = UIButton(type: .system)
    channel = FlutterMethodChannel(name: "localsend/ios26-button/\(viewId)", binaryMessenger: messenger)
    super.init()

    let params = args as? [String: Any]
    let title = params?["title"] as? String
    let symbol = params?["symbol"] as? String ?? "circle"
    let label = params?["accessibilityLabel"] as? String ?? title
    let prominent = params?["prominent"] as? Bool ?? false
    let destructive = params?["destructive"] as? Bool ?? false
    let enabled = params?["enabled"] as? Bool ?? true
    let tint: UIColor = destructive ? .systemRed : .systemBlue

    if #available(iOS 15.0, *) {
      var configuration: UIButton.Configuration
      if #available(iOS 26.0, *) {
        configuration = prominent ? .prominentGlass() : .glass()
        configuration.buttonSize = .large
      } else {
        configuration = prominent ? .filled() : .tinted()
      }
      configuration.title = title
      configuration.image = UIImage(systemName: symbol)
      configuration.imagePadding = title == nil ? 0 : 7
      configuration.cornerStyle = .capsule
      configuration.baseBackgroundColor = prominent ? tint : nil
      configuration.baseForegroundColor = prominent ? .white : tint
      button.configuration = configuration
    } else {
      button.setTitle(title, for: .normal)
      button.setImage(UIImage(systemName: symbol), for: .normal)
      button.tintColor = prominent ? .white : tint
      button.backgroundColor = prominent ? tint : tint.withAlphaComponent(0.14)
      button.layer.cornerRadius = 22
      button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
    }
    button.accessibilityLabel = label
    button.isEnabled = enabled
    button.addTarget(self, action: #selector(pressed), for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false

    container.backgroundColor = .clear
    container.isOpaque = false
    container.addSubview(button)
    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      button.topAnchor.constraint(equalTo: container.topAnchor),
      button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setEnabled", let enabled = call.arguments as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.button.isEnabled = enabled
      result(nil)
    }
  }

  func view() -> UIView {
    container
  }

  @objc private func pressed() {
    channel.invokeMethod("pressed", arguments: nil)
  }
}

private final class IOS26SwitchFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    IOS26SwitchPlatformView(frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

private final class IOS26SwitchPlatformView: NSObject, FlutterPlatformView {
  private let container: UIView
  private let toggle: UISwitch
  private let channel: FlutterMethodChannel

  init(frame: CGRect, viewId: Int64, arguments args: Any?, messenger: FlutterBinaryMessenger) {
    container = UIView(frame: frame)
    toggle = UISwitch(frame: .zero)
    channel = FlutterMethodChannel(name: "localsend/ios26-switch/\(viewId)", binaryMessenger: messenger)
    super.init()

    let params = args as? [String: Any]
    toggle.isOn = params?["value"] as? Bool ?? false
    toggle.accessibilityLabel = params?["accessibilityLabel"] as? String
    toggle.onTintColor = .systemGreen
    toggle.addTarget(self, action: #selector(changed), for: .valueChanged)
    toggle.translatesAutoresizingMaskIntoConstraints = false

    container.backgroundColor = .clear
    container.isOpaque = false
    container.addSubview(toggle)
    NSLayoutConstraint.activate([
      toggle.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      toggle.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    ])

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setValue", let value = call.arguments as? Bool else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.toggle.setOn(value, animated: true)
      result(nil)
    }
  }

  func view() -> UIView {
    container
  }

  @objc private func changed() {
    channel.invokeMethod("changed", arguments: toggle.isOn)
  }
}
