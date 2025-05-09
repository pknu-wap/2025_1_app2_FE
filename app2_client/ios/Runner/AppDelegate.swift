import UIKit
import Flutter
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Flutter 플러그인 등록
    GeneratedPluginRegistrant.register(with: self)

    // Info.plist에서 CLIENT_ID를 읽어서 GoogleSignIn 초기화
    if let clientID = Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String {
      let config = GIDConfiguration(clientID: clientID)
      GIDSignIn.sharedInstance.configuration = config
    } else {
      NSLog("[AppDelegate] Error: CLIENT_ID not found in Info.plist")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // iOS 9.0+ OAuth 콜백 URL 처리
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // GoogleSignIn이 처리했으면 true
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    // 아니면 Flutter 기본 핸들러에게 넘김
    return super.application(app, open: url, options: options)
  }
}
