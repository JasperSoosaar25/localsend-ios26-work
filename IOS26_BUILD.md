# LocalSend iOS 26 build

This fork keeps LocalSend's Flutter/Rust transfer engine and replaces the iPhone-facing chrome with iOS-native controls.

On iOS 26, the tab bar and primary controls are UIKit views using Apple's own `UITabBar`, `UISwitch`, SF Symbols, and `UIButton.Configuration.glass()` / `prominentGlass()` APIs. Those effects are rendered by iOS itself. Older iOS releases fall back to the corresponding native pre-Liquid-Glass controls.

## Build an IPA without a Mac

1. Put this project in a private GitHub repository.
2. Open **Actions** and run **Build iOS 26 IPA**.
3. Download the `LocalSend-iOS26-unsigned` artifact and unzip it once.
4. Move `LocalSend-iOS26.ipa` to the Files app on the iPhone.
5. Import the IPA into KravaSigner, sign it with the certificate already configured there, and install it.

The workflow deliberately produces an unsigned IPA because KravaSigner performs the final device-specific signing. Keep the Share Extension enabled when the signer offers extension options; LocalSend uses it for sending files from the iOS share sheet.

Developer Mode must be enabled on the iPhone for a development- or ad-hoc-signed app to launch. The first launch also requests Local Network and Photos permissions used by LocalSend.

## Build on a Mac

Use Xcode 26 or newer and Flutter 3.41.9:

```sh
cd app
flutter pub get
flutter build ios --release --no-codesign
mkdir -p dist/Payload
cp -R build/ios/iphoneos/Runner.app dist/Payload/
(cd dist && zip -qry LocalSend-iOS26.ipa Payload)
```

Then sign `app/dist/LocalSend-iOS26.ipa` in KravaSigner.
